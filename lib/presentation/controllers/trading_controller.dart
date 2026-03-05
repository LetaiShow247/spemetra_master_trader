import 'dart:async';
import 'package:get/get.dart';
import 'package:the_swing_dad/data/datasources/deriv_websocket_services.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/ai_trading_engine.dart';
import '../../data/models/trading_models.dart';
import '../../core/constants/app_constants.dart';
import 'settings_controller.dart';

class TradingController extends GetxController {
  late DerivWebSocketService _wsService;
  late SettingsController _settings;
  final _ai = AITradingEngine();
  final _uuid = const Uuid();

  // Reactive state
  final selectedMarket = AppConstants.availableMarkets.first.obs;
  final selectedCategory = 'odd_even'.obs;
  final tradingStatus = TradingStatus.idle.obs;
  final isAutoTrading = false.obs;
  final isOptimizing = false.obs;
  final currentPrediction = Rxn<AIPrediction>();
  final tradeHistory = <TradeRecord>[].obs;
  final lastTradeResult = Rxn<TradeRecord>();
  final digitHistory = <int>[].obs;

  // ── Session stats as individual Rx primitives so UI always rebuilds ──────
  final totalTrades = 0.obs;
  final wins = 0.obs;
  final losses = 0.obs;
  final totalPnL = 0.0.obs;
  final highestWin = 0.0.obs;
  final biggestLoss = 0.0.obs;
  final sessionStart = Rx<DateTime>(DateTime.now());

  // Opening balance captured when session starts / resets
  final openingBalance = 0.0.obs;

  // Computed helpers (non-reactive, read inside Obx blocks)
  double get winRate =>
      totalTrades.value == 0 ? 0 : (wins.value / totalTrades.value) * 100;

  // Keep a SessionStats view for PDF / report use
  SessionStats get sessionStats => SessionStats(
    totalTrades: totalTrades.value,
    wins: wins.value,
    losses: losses.value,
    totalPnL: totalPnL.value,
    highestWin: highestWin.value,
    biggestLoss: biggestLoss.value,
    sessionStart: sessionStart.value,
  );

  Timer? _autoTradeTimer;
  StreamSubscription? _tickSub;
  StreamSubscription? _tradeResultSub;

  @override
  void onInit() {
    super.onInit();
    _wsService = Get.find<DerivWebSocketService>();
    _settings = Get.find<SettingsController>();
    _listenToTradeResults();
  }

  Future<void> startMarket(Map<String, String> market) async {
    selectedMarket.value = market;
    await _wsService.unsubscribeTicks();
    _tickSub?.cancel();
    _ai.reset();
    digitHistory.clear();

    // Capture opening balance when entering a market
    if (openingBalance.value == 0.0) {
      openingBalance.value = _wsService.balance;
    }

    tradingStatus.value = TradingStatus.watching;
    await _wsService.subscribeTicks(market['symbol']!);

    _tickSub = _wsService.tickStream.listen((tick) {
      _ai.addTick(tick);
      digitHistory.add(tick.lastDigit);
      if (digitHistory.length > 100) digitHistory.removeAt(0);
      _runAnalysis();
    });
  }

  void _runAnalysis() {
    if (tradingStatus.value == TradingStatus.idle) return;
    tradingStatus.value = TradingStatus.analyzing;
    final prediction = _ai.analyze(selectedCategory.value);
    currentPrediction.value = prediction;
    tradingStatus.value = TradingStatus.watching;
  }

  // ─── Auto Trading ──────────────────────────────────────────────────────────
  void toggleAutoTrading() {
    if (isAutoTrading.value) {
      stopAutoTrading();
    } else {
      startAutoTrading();
    }
  }

  void startAutoTrading() {
    if (_wsService.connectionStatus != ConnectionStatus.authorized) {
      Get.snackbar(
        'Not Connected',
        'Please authorize your API token in Settings.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    isAutoTrading.value = true;
    tradingStatus.value = TradingStatus.watching;
    _scheduleNextTrade();
  }

  void stopAutoTrading() {
    isAutoTrading.value = false;
    _autoTradeTimer?.cancel();
    tradingStatus.value = TradingStatus.watching;
  }

  void _scheduleNextTrade() {
    if (!isAutoTrading.value) return;
    _autoTradeTimer?.cancel();
    _autoTradeTimer = Timer(const Duration(seconds: 3), () async {
      if (!isAutoTrading.value) return;
      await _executeTrade();
      if (isAutoTrading.value) _scheduleNextTrade();
    });
  }

  Future<void> executeSingleTrade() async {
    if (_wsService.connectionStatus != ConnectionStatus.authorized) {
      Get.snackbar(
        'Not Connected',
        'Please authorize your API token in Settings.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    await _executeTrade();
  }

  Future<void> _executeTrade() async {
    final prediction = currentPrediction.value;
    if (prediction == null) return;

    // Risk checks
    if (totalPnL.value <= -_settings.stopLoss.value) {
      stopAutoTrading();
      Get.snackbar(
        'Stop Loss Hit',
        'Daily stop loss reached. Trading stopped.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (totalPnL.value >= _settings.dailyTarget.value) {
      stopAutoTrading();
      Get.snackbar(
        'Target Reached',
        'Daily target achieved! 🎉',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    tradingStatus.value = TradingStatus.striking;

    try {
      final result = await _wsService.buyContract(
        symbol: selectedMarket['symbol']!,
        contractType: prediction.contractType,
        amount: _settings.stakeAmount.value,
        digitPrediction: prediction.targetDigit,
      );

      if (result.containsKey('error')) {
        tradingStatus.value = TradingStatus.watching;
        return;
      }

      tradingStatus.value = TradingStatus.learning;
      await Future.delayed(const Duration(seconds: 3));
      tradingStatus.value = TradingStatus.watching;
    } catch (_) {
      tradingStatus.value = TradingStatus.watching;
    }
  }

  void _listenToTradeResults() {
    _tradeResultSub = _wsService.tradeResultStream.listen((poc) {
      final isWin = poc['profit'] != null && (poc['profit'] as num) > 0;
      final buyPrice =
          (poc['buy_price'] as num?)?.toDouble() ?? _settings.stakeAmount.value;
      final sellPrice = (poc['sell_price'] as num?)?.toDouble() ?? 0;

      final record = TradeRecord(
        id: _uuid.v4(),
        contractType: poc['contract_type'] ?? '',
        stake: buyPrice,
        payout: sellPrice,
        isWin: isWin,
        timestamp: DateTime.now(),
        aiConfidence: currentPrediction.value?.confidence ?? 0.5,
        predictedDigit: currentPrediction.value?.targetDigit,
      );

      tradeHistory.add(record);
      lastTradeResult.value = record;
      _ai.recordTradeResult(record);

      // ── Update each primitive individually — UI always rebuilds ──────────
      totalTrades.value += 1;
      if (isWin) {
        wins.value += 1;
        if (record.profitLoss > highestWin.value) {
          highestWin.value = record.profitLoss;
        }
      } else {
        losses.value += 1;
        if (record.profitLoss.abs() > biggestLoss.value) {
          biggestLoss.value = record.profitLoss.abs();
        }
      }
      totalPnL.value = double.parse(
        (totalPnL.value + record.profitLoss).toStringAsFixed(2),
      );
    });
  }

  // ─── Market Optimizer ─────────────────────────────────────────────────────
  Future<void> optimizeMarket() async {
    if (isOptimizing.value) return;
    isOptimizing.value = true;

    Map<String, String>? bestMarket;
    double bestScore = -1;

    for (final market in AppConstants.availableMarkets) {
      await _wsService.subscribeTicks(market['symbol']!);
      await Future.delayed(const Duration(seconds: 2));
      final digits = _wsService.ticks.map((t) => t.lastDigit).toList();
      final score = _ai.scoreMarketHealth(digits);
      if (score > bestScore) {
        bestScore = score;
        bestMarket = market;
      }
    }

    isOptimizing.value = false;
    if (bestMarket != null) {
      await startMarket(bestMarket);
      Get.snackbar(
        'Best Market Found',
        '${bestMarket['name']} selected (Score: ${bestScore.toStringAsFixed(0)}/100)',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void resetSession() {
    totalTrades.value = 0;
    wins.value = 0;
    losses.value = 0;
    totalPnL.value = 0.0;
    highestWin.value = 0.0;
    biggestLoss.value = 0.0;
    sessionStart.value = DateTime.now();
    openingBalance.value = _wsService.balance;
    tradeHistory.clear();
    lastTradeResult.value = null;
  }

  void setCategory(String category) {
    selectedCategory.value = category;
    currentPrediction.value = null;
  }

  // ─── Goal Progress ─────────────────────────────────────────────────────────
  double get goalProgress {
    final target = _settings.dailyTarget.value;
    if (target <= 0) return 0;
    return (totalPnL.value / target).clamp(0, 1);
  }

  double get stopLossProgress {
    final sl = _settings.stopLoss.value;
    if (sl <= 0) return 0;
    return (totalPnL.value.abs() / sl).clamp(0, 1);
  }

  @override
  void onClose() {
    _autoTradeTimer?.cancel();
    _tickSub?.cancel();
    _tradeResultSub?.cancel();
    super.onClose();
  }
}
