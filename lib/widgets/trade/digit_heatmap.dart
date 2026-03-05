import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class DigitHeatmap extends StatelessWidget {
  final List<int> digits;
  const DigitHeatmap({super.key, required this.digits});

  @override
  Widget build(BuildContext context) {
    if (digits.isEmpty) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Text(
          'Awaiting ticks...',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    // Frequency count
    final freq = List.filled(10, 0);
    final recent = digits.length > 50
        ? digits.sublist(digits.length - 50)
        : digits;
    for (final d in recent) {
      freq[d]++;
    }
    final maxFreq = freq.reduce((a, b) => a > b ? a : b);

    // Last 20 digits display
    final lastDigits = digits.length > 20
        ? digits.sublist(digits.length - 20)
        : digits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heatmap bars for each digit 0-9
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(10, (i) {
              final f = freq[i];
              final ratio = maxFreq > 0 ? f / maxFreq : 0.0;
              final isHot = ratio > 0.7;
              final color = isHot
                  ? AppTheme.accent
                  : AppTheme.primary.withValues(alpha: 0.4 + ratio * 0.6);
              return Column(
                children: [
                  Text(
                    '$f',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 22,
                    height: 4 + ratio * 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$i',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 8),

        // Recent digits scroll
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: lastDigits.length,
            itemBuilder: (context, i) {
              final d = lastDigits[i];
              final isEven = d % 2 == 0;
              final isLast = i == lastDigits.length - 1;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 6),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isLast
                      ? AppTheme.primary
                      : isEven
                      ? AppTheme.bgSurface
                      : AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isLast
                        ? AppTheme.primary
                        : isEven
                        ? AppTheme.primary.withValues(alpha: 0.3)
                        : AppTheme.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$d',
                    style: TextStyle(
                      color: isLast ? AppTheme.bgDark : AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
