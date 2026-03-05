import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:the_swing_dad/widgets/trade/confidance_gauge.dart';
import 'package:the_swing_dad/widgets/trade/digit_heatmap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/trading_models.dart';
import '../../controllers/trading_controller.dart';
import '../../controllers/settings_controller.dart';

class TradeScreen extends StatelessWidget {
  const TradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trading = Get.find<TradingController>();
    final settings = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Obx(
          () => Text(
            trading.selectedMarket['short'] ?? 'Trade',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              fontSize: 18,
            ),
          ),
        ),
        actions: [
          Obx(() {
            final status = settings.connectionStatus;
            final color = status == ConnectionStatus.authorized
                ? AppTheme.success
                : status == ConnectionStatus.connecting
                ? AppTheme.warning
                : AppTheme.danger;
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Trading Status ────────────────────────────────────────────
            Obx(
              () => _StatusRow(
                status: trading.tradingStatus.value,
                isAutoTrading: trading.isAutoTrading.value,
              ),
            ),
            const SizedBox(height: 16),

            // ── AI Confidence + Market Health ─────────────────────────────
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: ConfidenceGauge(
                      prediction: trading.currentPrediction.value,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MarketHealthCard(
                      prediction: trading.currentPrediction.value,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Category Selector ─────────────────────────────────────────
            Obx(
              () => _CategorySelector(
                selected: trading.selectedCategory.value,
                onSelect: trading.setCategory,
              ),
            ),
            const SizedBox(height: 16),

            // ── Prediction Card ───────────────────────────────────────────
            Obx(
              () =>
                  _PredictionCard(prediction: trading.currentPrediction.value),
            ),
            const SizedBox(height: 16),

            // ── Digit Heatmap ─────────────────────────────────────────────
            const _SectionTitle('Last Digits'),
            const SizedBox(height: 8),
            Obx(() => DigitHeatmap(digits: trading.digitHistory.toList())),
            const SizedBox(height: 16),

            // ── Goal Progress ─────────────────────────────────────────────
            Obx(
              () => _GoalProgress(
                pnl: trading.totalPnL.value,
                target: settings.dailyTarget.value,
                stopLoss: settings.stopLoss.value,
                goalProgress: trading.goalProgress,
                stopLossProgress: trading.stopLossProgress,
              ),
            ),
            const SizedBox(height: 16),

            // ── Control Buttons ───────────────────────────────────────────
            Obx(
              () => _ControlButtons(
                isAutoTrading: trading.isAutoTrading.value,
                isOptimizing: trading.isOptimizing.value,
                isStriking:
                    trading.tradingStatus.value == TradingStatus.striking,
                onToggleAuto: trading.toggleAutoTrading,
                onTradeNow: trading.executeSingleTrade,
                onOptimize: trading.optimizeMarket,
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ─── Status Row ───────────────────────────────────────────────────────────────
class _StatusRow extends StatelessWidget {
  final TradingStatus status;
  final bool isAutoTrading;
  const _StatusRow({required this.status, required this.isAutoTrading});

  Color _color() {
    switch (status) {
      case TradingStatus.striking:
        return AppTheme.accent;
      case TradingStatus.analyzing:
        return AppTheme.warning;
      case TradingStatus.learning:
        return AppTheme.primary;
      case TradingStatus.watching:
        return AppTheme.secondary;
      case TradingStatus.idle:
        return AppTheme.textMuted;
    }
  }

  IconData _icon() {
    switch (status) {
      case TradingStatus.striking:
        return Icons.bolt_rounded;
      case TradingStatus.analyzing:
        return Icons.analytics_outlined;
      case TradingStatus.learning:
        return Icons.psychology_outlined;
      case TradingStatus.watching:
        return Icons.visibility_outlined;
      case TradingStatus.idle:
        return Icons.pause_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(_icon(), color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            status.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          if (isAutoTrading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.smart_toy_outlined,
                    color: AppTheme.secondary,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'AUTO',
                    style: TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Market Health ────────────────────────────────────────────────────────────
class _MarketHealthCard extends StatelessWidget {
  final AIPrediction? prediction;
  const _MarketHealthCard({this.prediction});

  Color _healthColor(String h) {
    switch (h) {
      case 'excellent':
        return AppTheme.success;
      case 'good':
        return AppTheme.secondary;
      case 'fair':
        return AppTheme.warning;
      case 'poor':
        return AppTheme.danger;
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final health = prediction?.marketHealth ?? 'analyzing';
    final color = _healthColor(health);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MARKET HEALTH',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.favorite_rounded, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                health.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Category Selector ────────────────────────────────────────────────────────
class _CategorySelector extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;
  const _CategorySelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'key': 'odd_even', 'label': 'Odd / Even'},
      {'key': 'match_differ', 'label': 'Match / Differ'},
      {'key': 'under_over', 'label': 'Under / Over'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Prediction Type'),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) {
              final isSelected = selected == cat['key'];
              return GestureDetector(
                onTap: () => onSelect(cat['key']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.15)
                        : AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    cat['label']!,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Prediction Card ──────────────────────────────────────────────────────────
class _PredictionCard extends StatelessWidget {
  final AIPrediction? prediction;
  const _PredictionCard({this.prediction});

  @override
  Widget build(BuildContext context) {
    if (prediction == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Center(
          child: Text(
            'Collecting market data...',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
      );
    }
    final p = prediction!;
    final confidenceColor = p.confidence >= 0.75
        ? AppTheme.success
        : p.confidence >= 0.60
        ? AppTheme.warning
        : AppTheme.danger;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
        gradient: LinearGradient(
          colors: [AppTheme.primary.withValues(alpha: 0.05), AppTheme.bgCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AI PREDICTION',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: confidenceColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(p.confidence * 100).toStringAsFixed(0)}% CONF',
                  style: TextStyle(
                    color: confidenceColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                p.contractType,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                  letterSpacing: 1,
                ),
              ),
              if (p.targetDigit != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    border: Border.all(color: AppTheme.primary),
                  ),
                  child: Text(
                    '${p.targetDigit}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            p.reason,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ─── Goal Progress ─────────────────────────────────────────────────────────────
class _GoalProgress extends StatelessWidget {
  final double pnl;
  final double target;
  final double stopLoss;
  final double goalProgress;
  final double stopLossProgress;

  const _GoalProgress({
    required this.pnl,
    required this.target,
    required this.stopLoss,
    required this.goalProgress,
    required this.stopLossProgress,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = pnl >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'GOAL PROGRESS',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                '${pnl >= 0 ? '+' : ''}\$${pnl.toStringAsFixed(2)} / \$${target.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isPositive ? AppTheme.success : AppTheme.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearPercentIndicator(
            percent: goalProgress.clamp(0.0, 1.0),
            lineHeight: 12,
            backgroundColor: AppTheme.border,
            progressColor: isPositive ? AppTheme.success : AppTheme.danger,
            barRadius: const Radius.circular(6),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '\$0.00',
                style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
              ),
              Text(
                'Target: \$${target.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Stop Loss: \$${stopLoss.toStringAsFixed(2)} | '
            '${stopLossProgress >= 0.5 ? '⚠️ ' : ''}'
            '${(stopLossProgress * 100).toStringAsFixed(0)}% used',
            style: TextStyle(
              fontSize: 11,
              color: stopLossProgress >= 0.7
                  ? AppTheme.danger
                  : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Control Buttons ──────────────────────────────────────────────────────────
class _ControlButtons extends StatelessWidget {
  final bool isAutoTrading;
  final bool isOptimizing;
  final bool isStriking;
  final VoidCallback onToggleAuto;
  final VoidCallback onTradeNow;
  final VoidCallback onOptimize;

  const _ControlButtons({
    required this.isAutoTrading,
    required this.isOptimizing,
    required this.isStriking,
    required this.onToggleAuto,
    required this.onTradeNow,
    required this.onOptimize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onToggleAuto,
            style: ElevatedButton.styleFrom(
              backgroundColor: isAutoTrading
                  ? AppTheme.danger
                  : AppTheme.primary,
              foregroundColor: isAutoTrading ? Colors.white : AppTheme.bgDark,
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            icon: Icon(
              isAutoTrading ? Icons.stop_rounded : Icons.play_arrow_rounded,
            ),
            label: Text(isAutoTrading ? 'STOP AUTO TRADE' : 'START AUTO TRADE'),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isStriking ? null : onTradeNow,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: const Text('TRADE NOW'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isOptimizing ? null : onOptimize,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.secondary,
                  side: const BorderSide(color: AppTheme.secondary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: isOptimizing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.secondary,
                        ),
                      )
                    : const Icon(Icons.travel_explore_rounded, size: 18),
                label: Text(isOptimizing ? 'SCANNING...' : 'OPTIMIZE'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        color: AppTheme.textMuted,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
