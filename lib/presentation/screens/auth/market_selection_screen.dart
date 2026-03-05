import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_routes.dart';
import '../../controllers/trading_controller.dart';

class MarketSelectionScreen extends StatefulWidget {
  const MarketSelectionScreen({super.key});

  @override
  State<MarketSelectionScreen> createState() => _MarketSelectionScreenState();
}

class _MarketSelectionScreenState extends State<MarketSelectionScreen> {
  Map<String, String>? _selected;
  final TradingController _trading = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Select Market',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: 1,
                ),
              ).animate().fadeIn().slideY(begin: -0.2),
              const SizedBox(height: 4),
              const Text(
                'Choose your trading market to enter',
                style: TextStyle(color: AppTheme.textSecondary),
              ).animate(delay: 100.ms).fadeIn(),
              const SizedBox(height: 28),

              // Market grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: AppConstants.availableMarkets.length,
                  itemBuilder: (context, i) {
                    final market = AppConstants.availableMarkets[i];
                    final isSelected = _selected == market;
                    return _MarketCard(
                          market: market,
                          isSelected: isSelected,
                          onTap: () => setState(() => _selected = market),
                        )
                        .animate(delay: Duration(milliseconds: i * 60))
                        .fadeIn()
                        .slideY(begin: 0.2);
                  },
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected == null
                      ? null
                      : () async {
                          await _trading.startMarket(_selected!);
                          Get.offNamed(AppRoutes.home);
                        },
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor: AppTheme.border,
                    disabledForegroundColor: AppTheme.textMuted,
                  ),
                  child: Text(
                    _selected == null
                        ? 'Select a Market'
                        : 'Enter ${_selected!['short']}',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketCard extends StatelessWidget {
  final Map<String, String> market;
  final bool isSelected;
  final VoidCallback onTap;

  const _MarketCard({
    required this.market,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_rounded,
              color: isSelected ? AppTheme.primary : AppTheme.textMuted,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              market['short'] ?? '',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              market['name'] ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
