import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:the_swing_dad/data/datasources/deriv_websocket_services.dart';
import 'package:the_swing_dad/data/models/trading_models.dart';
import '../../core/constants/app_constants.dart';

class SettingsController extends GetxController {
  final _box = GetStorage();
  late DerivWebSocketService _wsService;

  final apiToken = ''.obs;
  final stakeAmount = AppConstants.defaultStake.obs;
  final dailyTarget = AppConstants.defaultDailyTarget.obs;
  final stopLoss = AppConstants.defaultStopLoss.obs;
  final isAuthorizing = false.obs;
  final authStatus = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _wsService = Get.find<DerivWebSocketService>();
    _loadCached();
  }

  void _loadCached() {
    apiToken.value = _box.read(AppConstants.apiTokenKey) ?? '';
    stakeAmount.value =
        _box.read(AppConstants.stakeAmountKey) ?? AppConstants.defaultStake;
    dailyTarget.value =
        _box.read(AppConstants.dailyTargetKey) ??
        AppConstants.defaultDailyTarget;
    stopLoss.value =
        _box.read(AppConstants.stopLossKey) ?? AppConstants.defaultStopLoss;
  }

  Future<bool> authorizeAndConnect(String token) async {
    if (token.trim().isEmpty) {
      authStatus.value = 'Please enter your API token.';
      return false;
    }
    isAuthorizing.value = true;
    authStatus.value = 'Connecting...';
    try {
      final success = await _wsService.connect(token.trim());
      if (success) {
        apiToken.value = token.trim();
        _box.write(AppConstants.apiTokenKey, token.trim());
        authStatus.value = 'Authorized ✓';
        return true;
      } else {
        authStatus.value = 'Authorization failed. Check your token.';
        return false;
      }
    } catch (e) {
      authStatus.value = 'Connection error: $e';
      return false;
    } finally {
      isAuthorizing.value = false;
    }
  }

  void saveRiskSettings({
    required double stake,
    required double target,
    required double loss,
  }) {
    stakeAmount.value = stake;
    dailyTarget.value = target;
    stopLoss.value = loss;
    _box.write(AppConstants.stakeAmountKey, stake);
    _box.write(AppConstants.dailyTargetKey, target);
    _box.write(AppConstants.stopLossKey, loss);
    Get.snackbar(
      'Saved',
      'Risk settings saved successfully',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  ConnectionStatus get connectionStatus => _wsService.connectionStatus;
  AccountInfo? get accountInfo => _wsService.accountInfo;
  double get currentBalance => _wsService.balance;
}
