import 'package:equatable/equatable.dart';

// Tick data from Deriv
class TickData extends Equatable {
  final double quote;
  final int epoch;
  final int lastDigit;
  final String symbol;

  const TickData({
    required this.quote,
    required this.epoch,
    required this.lastDigit,
    required this.symbol,
  });

  factory TickData.fromJson(Map<String, dynamic> json) {
    final q = (json['quote'] as num).toDouble();
    final digit = q.toString().replaceAll('.', '').split('').last;
    return TickData(
      quote: q,
      epoch: json['epoch'] as int,
      lastDigit: int.tryParse(digit) ?? 0,
      symbol: json['symbol'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [epoch, quote, symbol];
}

// Trade Record
class TradeRecord extends Equatable {
  final String id;
  final String contractType;
  final double stake;
  final double payout;
  final bool isWin;
  final DateTime timestamp;
  final int? predictedDigit;
  final int? actualDigit;
  final double aiConfidence;

  const TradeRecord({
    required this.id,
    required this.contractType,
    required this.stake,
    required this.payout,
    required this.isWin,
    required this.timestamp,
    this.predictedDigit,
    this.actualDigit,
    required this.aiConfidence,
  });

  double get profitLoss => isWin ? payout - stake : -stake;

  @override
  List<Object?> get props => [id];
}

// Session Stats — plain class (no Equatable) so the PDF report can read it
class SessionStats {
  final int totalTrades;
  final int wins;
  final int losses;
  final double totalPnL;
  final double highestWin;
  final double biggestLoss;
  final DateTime sessionStart;

  const SessionStats({
    this.totalTrades = 0,
    this.wins = 0,
    this.losses = 0,
    this.totalPnL = 0,
    this.highestWin = 0,
    this.biggestLoss = 0,
    required this.sessionStart,
  });

  double get winRate => totalTrades == 0 ? 0 : (wins / totalTrades) * 100;

  SessionStats copyWith({
    int? totalTrades,
    int? wins,
    int? losses,
    double? totalPnL,
    double? highestWin,
    double? biggestLoss,
  }) {
    return SessionStats(
      totalTrades: totalTrades ?? this.totalTrades,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      totalPnL: totalPnL ?? this.totalPnL,
      highestWin: highestWin ?? this.highestWin,
      biggestLoss: biggestLoss ?? this.biggestLoss,
      sessionStart: sessionStart,
    );
  }
}

// AI Prediction
class AIPrediction extends Equatable {
  final String contractType;
  final int? targetDigit;
  final double confidence;
  final String marketHealth; // excellent, good, fair, poor
  final String reason;

  const AIPrediction({
    required this.contractType,
    this.targetDigit,
    required this.confidence,
    required this.marketHealth,
    required this.reason,
  });

  @override
  List<Object?> get props => [contractType, confidence, marketHealth];
}

// Account Info
class AccountInfo extends Equatable {
  final String loginId;
  final String currency;
  final double balance;
  final String fullName;
  final bool isVirtual;

  const AccountInfo({
    required this.loginId,
    required this.currency,
    required this.balance,
    required this.fullName,
    required this.isVirtual,
  });

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      loginId: json['loginid'] ?? '',
      currency: json['currency'] ?? 'USD',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      fullName: json['fullname'] ?? '',
      isVirtual: json['is_virtual'] == 1,
    );
  }

  @override
  List<Object?> get props => [loginId, balance];
}

enum ConnectionStatus { disconnected, connecting, connected, authorized, error }

enum TradingStatus { idle, watching, analyzing, striking, learning }

enum MarketHealth { excellent, good, fair, poor }
