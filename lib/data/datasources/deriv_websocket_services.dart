import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:get/get.dart';
import '../models/trading_models.dart';
import '../../core/constants/app_constants.dart';

class DerivWebSocketService extends GetxService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final _connectionStatus = ConnectionStatus.disconnected.obs;
  ConnectionStatus get connectionStatus => _connectionStatus.value;
  RxString get connectionStatusObs => _connectionStatus.value.name.obs;

  final _ticks = <TickData>[].obs;
  List<TickData> get ticks => _ticks;

  final _accountInfo = Rxn<AccountInfo>();
  AccountInfo? get accountInfo => _accountInfo.value;

  final _balance = 0.0.obs;
  double get balance => _balance.value;
  RxDouble get balanceObs => _balance;

  // Exposed reactive status for UI
  Rx<ConnectionStatus> get statusRx => _connectionStatus;

  final _tickController = StreamController<TickData>.broadcast();
  Stream<TickData> get tickStream => _tickController.stream;

  final _tradeResultController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get tradeResultStream =>
      _tradeResultController.stream;

  String? _currentSymbol;
  String? _apiToken;
  int _reqId = 1;
  final Map<int, Completer<Map<String, dynamic>>> _pendingRequests = {};

  // Reconnect state
  Timer? _reconnectTimer;
  bool _intentionalDisconnect = false;

  Future<bool> connect(String apiToken) async {
    _apiToken = apiToken;
    _intentionalDisconnect = false;
    _connectionStatus.value = ConnectionStatus.connecting;
    try {
      _channel?.sink.close();
      _subscription?.cancel();

      _channel = WebSocketChannel.connect(Uri.parse(AppConstants.derivWsUrl));
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
      _connectionStatus.value = ConnectionStatus.connected;

      final authResult = await _sendRequest({'authorize': apiToken});
      if (authResult.containsKey('authorize')) {
        final auth = authResult['authorize'];
        _accountInfo.value = AccountInfo.fromJson(auth);
        _balance.value = (auth['balance'] as num?)?.toDouble() ?? 0.0;
        _connectionStatus.value = ConnectionStatus.authorized;
        // Subscribe to balance updates
        _sendRequest({'balance': 1, 'subscribe': 1});
        return true;
      }
      _connectionStatus.value = ConnectionStatus.error;
      return false;
    } catch (e) {
      _connectionStatus.value = ConnectionStatus.error;
      return false;
    }
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;

      // Resolve pending requests first
      final reqId = data['req_id'] as int?;
      if (reqId != null && _pendingRequests.containsKey(reqId)) {
        _pendingRequests[reqId]!.complete(data);
        _pendingRequests.remove(reqId);
        // Don't return — balance/tick updates may share req_id=0
      }

      // Tick stream
      if (data.containsKey('tick')) {
        final tick = TickData.fromJson(data['tick'] as Map<String, dynamic>);
        _ticks.add(tick);
        if (_ticks.length > AppConstants.tickBufferSize) _ticks.removeAt(0);
        _tickController.add(tick);
      }

      // Trade result — contract settled
      if (data.containsKey('proposal_open_contract')) {
        final poc = data['proposal_open_contract'] as Map<String, dynamic>;
        if (poc['is_sold'] == 1) {
          _tradeResultController.add(poc);
        }
      }

      // Balance subscription update
      if (data.containsKey('balance')) {
        final bal = data['balance'];
        if (bal is Map && bal.containsKey('balance')) {
          _balance.value = (bal['balance'] as num).toDouble();
        }
      }
    } catch (_) {}
  }

  void _onError(dynamic error) {
    _connectionStatus.value = ConnectionStatus.error;
    _scheduleReconnect();
  }

  void _onDone() {
    if (_intentionalDisconnect) return;
    _connectionStatus.value = ConnectionStatus.disconnected;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_intentionalDisconnect || _apiToken == null) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () async {
      if (_intentionalDisconnect) return;
      await connect(_apiToken!);
      // Re-subscribe ticks if we had a market
      if (_currentSymbol != null) {
        await subscribeTicks(_currentSymbol!);
      }
    });
  }

  Future<Map<String, dynamic>> _sendRequest(Map<String, dynamic> request) {
    final id = _reqId++;
    request['req_id'] = id;
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[id] = completer;
    _channel?.sink.add(jsonEncode(request));
    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        _pendingRequests.remove(id);
        return {'error': 'Request timed out'};
      },
    );
  }

  Future<void> subscribeTicks(String symbol) async {
    _currentSymbol = symbol;
    _ticks.clear();
    await _sendRequest({'ticks': symbol, 'subscribe': 1});
  }

  Future<void> unsubscribeTicks() async {
    await _sendRequest({'forget_all': 'ticks'});
  }

  Future<Map<String, dynamic>> buyContract({
    required String symbol,
    required String contractType,
    required double amount,
    int? digitPrediction,
    int duration = 1,
  }) async {
    final proposalReq = <String, dynamic>{
      'proposal': 1,
      'amount': amount,
      'basis': 'stake',
      'contract_type': contractType,
      'currency': _accountInfo.value?.currency ?? 'USD',
      'duration': duration,
      'duration_unit': 't',
      'symbol': symbol,
    };
    if (digitPrediction != null) {
      proposalReq['barrier'] = '$digitPrediction';
    }

    final proposal = await _sendRequest(proposalReq);
    if (proposal.containsKey('error')) return proposal;

    final proposalId = proposal['proposal']?['id'];
    if (proposalId == null) return {'error': 'No proposal ID'};

    final buyResult = await _sendRequest({'buy': proposalId, 'price': amount});

    // Subscribe to contract updates to get settlement
    if (buyResult.containsKey('buy')) {
      final contractId = buyResult['buy']['contract_id'];
      if (contractId != null) {
        _sendRequest({
          'proposal_open_contract': 1,
          'contract_id': contractId,
          'subscribe': 1,
        });
      }
    }

    return buyResult;
  }

  void disconnect() {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _connectionStatus.value = ConnectionStatus.disconnected;
    _pendingRequests.clear();
  }

  @override
  void onClose() {
    disconnect();
    _tickController.close();
    _tradeResultController.close();
    super.onClose();
  }
}
