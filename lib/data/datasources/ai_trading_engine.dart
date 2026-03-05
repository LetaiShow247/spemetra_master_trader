import 'dart:math';
import '../models/trading_models.dart';
import '../../core/constants/app_constants.dart';

/// Core AI/ML Engine - Pattern Recognition & Prediction System
class AITradingEngine {
  final List<TickData> _tickBuffer = [];
  final List<int> _digitHistory = [];
  final List<TradeRecord> _tradeHistory = [];

  // Pattern memory - frequency maps
  final Map<String, int> _patternWins = {};
  final Map<String, int> _patternLosses = {};

  // Last prediction
  AIPrediction? _lastPrediction;
  AIPrediction? get lastPrediction => _lastPrediction;

  void addTick(TickData tick) {
    _tickBuffer.add(tick);
    _digitHistory.add(tick.lastDigit);
    if (_tickBuffer.length > AppConstants.tickBufferSize) {
      _tickBuffer.removeAt(0);
      _digitHistory.removeAt(0);
    }
  }

  void recordTradeResult(TradeRecord trade) {
    _tradeHistory.add(trade);
    final pattern = _getRecentPattern(5);
    if (trade.isWin) {
      _patternWins[pattern] = (_patternWins[pattern] ?? 0) + 1;
    } else {
      _patternLosses[pattern] = (_patternLosses[pattern] ?? 0) + 1;
    }
  }

  // ─── Main Prediction Engine ──────────────────────────────────────────────
  AIPrediction analyze(String contractCategory) {
    if (_digitHistory.length < 10) {
      return const AIPrediction(
        contractType: 'DIGITODD',
        confidence: 0.5,
        marketHealth: 'analyzing',
        reason: 'Collecting market data...',
      );
    }

    final health = _assessMarketHealth();
    final healthStr = _healthToString(health);

    switch (contractCategory) {
      case 'odd_even':
        return _predictOddEven(healthStr);
      case 'match_differ':
        return _predictMatchDiffer(healthStr);
      case 'under_over':
        return _predictUnderOver(healthStr);
      default:
        return _predictOddEven(healthStr);
    }
  }

  // ─── Odd/Even Prediction ──────────────────────────────────────────────────
  AIPrediction _predictOddEven(String health) {
    final recent = _digitHistory.length >= 20
        ? _digitHistory.sublist(_digitHistory.length - 20)
        : _digitHistory;

    final oddCount = recent.where((d) => d % 2 != 0).length;
    final evenCount = recent.length - oddCount;
    final oddRatio = oddCount / recent.length;

    // Pattern: if heavy bias toward one side, expect reversion
    String contractType;
    double confidence;
    String reason;

    if (oddRatio > 0.65) {
      // Too many odds → predict even (mean reversion)
      contractType = 'DIGITEVEN';
      confidence = _calculateConfidence(oddRatio, 0.65, 1.0);
      reason =
          'Odd digit overrepresentation detected ($oddCount/${recent.length}). Reversion expected.';
    } else if (oddRatio < 0.35) {
      // Too many evens → predict odd
      contractType = 'DIGITODD';
      confidence = _calculateConfidence(1 - oddRatio, 0.65, 1.0);
      reason =
          'Even digit overrepresentation detected ($evenCount/${recent.length}). Reversion expected.';
    } else {
      // Balanced - use momentum (last 5)
      final last5 = _digitHistory.length >= 5
          ? _digitHistory.sublist(_digitHistory.length - 5)
          : _digitHistory;
      final last5Odd = last5.where((d) => d % 2 != 0).length;
      if (last5Odd >= 4) {
        contractType = 'DIGITEVEN';
        confidence = 0.62;
        reason = 'Short-term odd momentum → counter signal.';
      } else if (last5Odd <= 1) {
        contractType = 'DIGITODD';
        confidence = 0.62;
        reason = 'Short-term even momentum → counter signal.';
      } else {
        contractType = oddRatio >= 0.5 ? 'DIGITEVEN' : 'DIGITODD';
        confidence = 0.55;
        reason = 'Market is balanced. Slight bias detected.';
      }
    }

    // Pattern learning boost
    final patternBoost = _getPatternBoost(contractType);
    confidence = (confidence + patternBoost).clamp(0.1, 0.98);

    _lastPrediction = AIPrediction(
      contractType: contractType,
      confidence: confidence,
      marketHealth: health,
      reason: reason,
    );
    return _lastPrediction!;
  }

  // ─── Digit Match/Differ Prediction ────────────────────────────────────────
  AIPrediction _predictMatchDiffer(String health) {
    if (_digitHistory.length < 15) {
      return AIPrediction(
        contractType: 'DIGITDIFF',
        targetDigit: 5,
        confidence: 0.55,
        marketHealth: health,
        reason: 'Collecting data...',
      );
    }

    // Find the least frequent digit in last 30 ticks
    final recent = _digitHistory.length >= 30
        ? _digitHistory.sublist(_digitHistory.length - 30)
        : _digitHistory;

    final freq = List.filled(10, 0);
    for (final d in recent) {
      freq[d]++;
    }

    // Most frequent digit - likely to recur (match)
    int maxDigit = 0;
    int maxFreq = 0;
    // ignore: unused_local_variable
    int minDigit = 0;
    int minFreq = 999;

    for (int i = 0; i < 10; i++) {
      if (freq[i] > maxFreq) {
        maxFreq = freq[i];
        maxDigit = i;
      }
      if (freq[i] < minFreq) {
        minFreq = freq[i];
        minDigit = i;
      }
    }

    // Volatility check
    final stdDev = _digitStdDev(recent);
    String contractType;
    int targetDigit;
    double confidence;
    String reason;

    if (stdDev < 2.5) {
      // Low volatility - match dominant digit
      contractType = 'DIGITMATCH';
      targetDigit = maxDigit;
      confidence = 0.60 + (maxFreq / recent.length) * 0.3;
      reason =
          'Low volatility. Digit $maxDigit appears ${maxFreq}x in last ${recent.length} ticks.';
    } else {
      // High volatility - differ from overrepresented
      contractType = 'DIGITDIFF';
      targetDigit = maxDigit;
      confidence = 0.62 + (1 - minFreq / recent.length) * 0.2;
      reason = 'High volatility. Avoiding dominant digit $maxDigit.';
    }

    confidence = confidence.clamp(0.1, 0.95);
    _lastPrediction = AIPrediction(
      contractType: contractType,
      targetDigit: targetDigit,
      confidence: confidence,
      marketHealth: health,
      reason: reason,
    );
    return _lastPrediction!;
  }

  // ─── Under/Over Prediction ────────────────────────────────────────────────
  AIPrediction _predictUnderOver(String health) {
    if (_digitHistory.length < 10) {
      return AIPrediction(
        contractType: 'DIGITUNDER',
        targetDigit: 5,
        confidence: 0.55,
        marketHealth: health,
        reason: 'Collecting data...',
      );
    }

    final recent = _digitHistory.length >= 20
        ? _digitHistory.sublist(_digitHistory.length - 20)
        : _digitHistory;

    final avg = recent.reduce((a, b) => a + b) / recent.length;
    final overCount = recent.where((d) => d >= 5).length;
    final underCount = recent.length - overCount;

    String contractType;
    int barrier;
    double confidence;
    String reason;

    if (avg > 5.5 && overCount > recent.length * 0.6) {
      contractType = 'DIGITUNDER';
      barrier = 5;
      confidence = 0.60 + (overCount / recent.length - 0.5) * 0.5;
      reason = 'High digits dominating. Under-5 reversion signal.';
    } else if (avg < 4.5 && underCount > recent.length * 0.6) {
      contractType = 'DIGITOVER';
      barrier = 4;
      confidence = 0.60 + (underCount / recent.length - 0.5) * 0.5;
      reason = 'Low digits dominating. Over-4 reversion signal.';
    } else {
      // Use trend momentum
      final last5 = _digitHistory.length >= 5
          ? _digitHistory.sublist(_digitHistory.length - 5)
          : _digitHistory;
      final last5Avg = last5.reduce((a, b) => a + b) / last5.length;
      if (last5Avg > 5) {
        contractType = 'DIGITUNDER';
        barrier = 5;
        confidence = 0.57;
        reason = 'Recent trend above 5. Under signal.';
      } else {
        contractType = 'DIGITOVER';
        barrier = 4;
        confidence = 0.57;
        reason = 'Recent trend below 5. Over signal.';
      }
    }

    confidence = confidence.clamp(0.1, 0.95);
    _lastPrediction = AIPrediction(
      contractType: contractType,
      targetDigit: barrier,
      confidence: confidence,
      marketHealth: health,
      reason: reason,
    );
    return _lastPrediction!;
  }

  // ─── Market Health Assessment ──────────────────────────────────────────────
  MarketHealth _assessMarketHealth() {
    if (_digitHistory.length < 20) return MarketHealth.fair;

    final recent = _digitHistory.sublist(_digitHistory.length - 20);
    final stdDev = _digitStdDev(recent);
    final entropy = _calculateEntropy(recent);
    final consecutive = _maxConsecutiveSame(recent);

    // Good market: high entropy, moderate volatility, no long streaks
    if (entropy > 2.8 && stdDev > 2.0 && stdDev < 4.0 && consecutive <= 3) {
      return MarketHealth.excellent;
    } else if (entropy > 2.2 && consecutive <= 4) {
      return MarketHealth.good;
    } else if (consecutive > 5 || stdDev > 4.5) {
      return MarketHealth.poor;
    }
    return MarketHealth.fair;
  }

  String _healthToString(MarketHealth h) {
    switch (h) {
      case MarketHealth.excellent:
        return 'excellent';
      case MarketHealth.good:
        return 'good';
      case MarketHealth.fair:
        return 'fair';
      case MarketHealth.poor:
        return 'poor';
    }
  }

  // ─── Market Optimizer ──────────────────────────────────────────────────────
  /// Returns score 0-100 for a list of digits (for market comparison)
  double scoreMarketHealth(List<int> digits) {
    if (digits.length < 15) return 50.0;
    final stdDev = _digitStdDev(digits);
    final entropy = _calculateEntropy(digits);
    final consecutive = _maxConsecutiveSame(digits);

    double score = entropy * 20; // max ~66
    score += (stdDev > 1.5 && stdDev < 4.5) ? 20 : 0;
    score -= consecutive * 5;
    return score.clamp(0, 100);
  }

  // ─── Math Helpers ──────────────────────────────────────────────────────────
  double _digitStdDev(List<int> digits) {
    if (digits.isEmpty) return 0;
    final mean = digits.reduce((a, b) => a + b) / digits.length;
    final variance =
        digits.map((d) => pow(d - mean, 2)).reduce((a, b) => a + b) /
        digits.length;
    return sqrt(variance);
  }

  double _calculateEntropy(List<int> digits) {
    final freq = <int, int>{};
    for (final d in digits) {
      freq[d] = (freq[d] ?? 0) + 1;
    }
    double entropy = 0;
    for (final count in freq.values) {
      final p = count / digits.length;
      if (p > 0) entropy -= p * log(p) / log(2);
    }
    return entropy;
  }

  int _maxConsecutiveSame(List<int> digits) {
    int max = 1, current = 1;
    for (int i = 1; i < digits.length; i++) {
      if (digits[i] == digits[i - 1]) {
        current++;
        if (current > max) max = current;
      } else {
        current = 1;
      }
    }
    return max;
  }

  double _calculateConfidence(double ratio, double min, double max) {
    return 0.55 + ((ratio - min) / (max - min)) * 0.4;
  }

  String _getRecentPattern(int length) {
    final recent = _digitHistory.length >= length
        ? _digitHistory.sublist(_digitHistory.length - length)
        : _digitHistory;
    return recent.map((d) => d % 2 == 0 ? 'E' : 'O').join();
  }

  double _getPatternBoost(String contractType) {
    final pattern = _getRecentPattern(5);
    final wins = _patternWins[pattern] ?? 0;
    final losses = _patternLosses[pattern] ?? 0;
    final total = wins + losses;
    if (total < 3) return 0;
    final wr = wins / total;
    return (wr - 0.5) * 0.1;
  }

  // ─── Digit History Getter ─────────────────────────────────────────────────
  List<int> get digitHistory => List.unmodifiable(_digitHistory);

  void reset() {
    _tickBuffer.clear();
    _digitHistory.clear();
  }
}
