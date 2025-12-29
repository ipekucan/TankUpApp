import 'package:flutter/material.dart';
import '../../services/chart_data_service.dart' show ChartPeriod;

/// Period selector widget for switching between Day/Week/Month views.
/// Uses AppTextStyles for consistent styling.
class PeriodSelector extends StatelessWidget {
  final ChartPeriod selectedPeriod;
  final ValueChanged<ChartPeriod> onPeriodChanged;

  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPeriodButton('Gün', ChartPeriod.day),
        const SizedBox(width: 8),
        _buildPeriodButton('Hafta', ChartPeriod.week),
        const SizedBox(width: 8),
        _buildPeriodButton('Ay', ChartPeriod.month),
      ],
    );
  }

  Widget _buildPeriodButton(String label, ChartPeriod period) {
    final isActive = selectedPeriod == period;
    return GestureDetector(
      onTap: () => onPeriodChanged(period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[800],
            fontWeight: FontWeight.w600,
            fontSize: 17.0,
          ),
        ),
      ),
    );
  }
}

