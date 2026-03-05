import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/trading_models.dart';

class ConfidenceGauge extends StatelessWidget {
  final AIPrediction? prediction;
  const ConfidenceGauge({super.key, this.prediction});

  @override
  Widget build(BuildContext context) {
    final confidence = prediction?.confidence ?? 0;
    final color = confidence >= 0.75
        ? AppTheme.success
        : confidence >= 0.60
        ? AppTheme.warning
        : AppTheme.danger;

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
            'AI CONFIDENCE',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: confidence,
                  strokeWidth: 7,
                  backgroundColor: AppTheme.border,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${(confidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              confidence >= 0.75
                  ? 'HIGH'
                  : confidence >= 0.60
                  ? 'MEDIUM'
                  : 'LOW',
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
