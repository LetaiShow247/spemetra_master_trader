import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:the_swing_dad/widgets/common/stat_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/trading_models.dart';
import '../../controllers/trading_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/report_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trading = Get.find<TradingController>();
    final settings = Get.find<SettingsController>();
    final report = Get.find<ReportController>();
    final fmt = NumberFormat('#,##0.00');

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          Obx(
            () => report.isGenerating.value
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: report.downloadPDFReport,
                    icon: const Icon(Icons.download_rounded),
                    tooltip: 'Download PDF Report',
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Account Card ─────────────────────────────────────────────
            Obx(() {
              final account = settings.accountInfo;
              final balance = settings.currentBalance;
              final connStatus = settings.connectionStatus;
              final isAuthorized = connStatus == ConnectionStatus.authorized;
              final statusColor = isAuthorized
                  ? AppTheme.success
                  : AppTheme.danger;

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                  gradient: LinearGradient(
                    colors: [AppTheme.bgCard, AppTheme.bgSurface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primary.withValues(alpha: 0.12),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppTheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account?.fullName.isNotEmpty == true
                                    ? account!.fullName
                                    : 'Trader',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                account?.loginId ?? 'Not connected',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // API Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isAuthorized
                                    ? 'AUTHORIZED'
                                    : connStatus.name.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Balance
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CURRENT BALANCE',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textMuted,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${fmt.format(balance)}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            account?.currency ?? 'USD',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted,
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
            }),

            const SizedBox(height: 16),

            // ── Current Session Table ─────────────────────────────────────
            const _SectionTitle('CURRENT SESSION'),
            const SizedBox(height: 10),
            Obx(() {
              final pnl = trading.totalPnL.value;
              final isConnected =
                  settings.connectionStatus == ConnectionStatus.authorized;
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    _SessionRow(
                      'Session P&L',
                      Text(
                        '${pnl >= 0 ? '+' : ''}\$${fmt.format(pnl)}',
                        style: TextStyle(
                          color: pnl >= 0 ? AppTheme.success : AppTheme.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    _divider(),
                    _SessionRow(
                      'Target',
                      Text(
                        '\$${fmt.format(settings.dailyTarget.value)}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _divider(),
                    _SessionRow(
                      'Stop Loss',
                      Text(
                        '\$${fmt.format(settings.stopLoss.value)}',
                        style: const TextStyle(
                          color: AppTheme.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _divider(),
                    _SessionRow(
                      'Connection',
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isConnected
                                  ? AppTheme.success
                                  : AppTheme.danger,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isConnected ? 'Live' : 'Stopped',
                            style: TextStyle(
                              color: isConnected
                                  ? AppTheme.success
                                  : AppTheme.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // ── Session Stats Grid ────────────────────────────────────────
            const _SectionTitle('SESSION STATS'),
            const SizedBox(height: 10),
            Obx(
              () => GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.8,
                children: [
                  StatCard(
                    label: 'WINS',
                    value: '${trading.wins.value}',
                    color: AppTheme.success,
                    icon: Icons.trending_up_rounded,
                  ),
                  StatCard(
                    label: 'LOSSES',
                    value: '${trading.losses.value}',
                    color: AppTheme.danger,
                    icon: Icons.trending_down_rounded,
                  ),
                  StatCard(
                    label: 'TOTAL TRADES',
                    value: '${trading.totalTrades.value}',
                    color: AppTheme.primary,
                    icon: Icons.swap_horiz_rounded,
                  ),
                  StatCard(
                    label: 'WIN RATE',
                    value: '${trading.winRate.toStringAsFixed(1)}%',
                    color: trading.winRate >= 55
                        ? AppTheme.success
                        : AppTheme.warning,
                    icon: Icons.percent_rounded,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Action Buttons ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showResetDialog(trading),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.warning,
                      side: const BorderSide(color: AppTheme.warning),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('RESET SESSION'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(
                    () => OutlinedButton.icon(
                      onPressed: report.isGenerating.value
                          ? null
                          : report.downloadPDFReport,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: report.isGenerating.value
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            )
                          : const Icon(Icons.download_rounded, size: 18),
                      label: Text(
                        report.isGenerating.value
                            ? 'GENERATING...'
                            : 'PDF REPORT',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(TradingController trading) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Reset Session?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'All session stats and trade history will be cleared.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              trading.resetSession();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: AppTheme.border);
}

class _SessionRow extends StatelessWidget {
  final String label;
  final Widget value;
  const _SessionRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          value,
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        color: AppTheme.textMuted,
        letterSpacing: 1.5,
      ),
    );
  }
}
