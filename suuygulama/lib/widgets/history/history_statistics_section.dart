import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Statistics cards section showing daily average, completion rate, and total
class HistoryStatisticsSection extends StatelessWidget {
  final String dailyAverage;
  final double completionRate;
  final String total;

  const HistoryStatisticsSection({
    super.key,
    required this.dailyAverage,
    required this.completionRate,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Günlük Ort.',
            value: dailyAverage,
            icon: Icons.water_drop,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Tamamlanma',
            value: '${completionRate.toInt()}%',
            icon: Icons.check_circle,
            color: AppColors.successGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Toplam',
            value: total,
            icon: Icons.show_chart,
            color: AppColors.secondaryAqua,
          ),
        ),
      ],
    );
  }
}

/// Individual statistics card
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
