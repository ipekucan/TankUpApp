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
        _buildPeriodButton('Son 7 Gün', ChartPeriod.day),
        const SizedBox(width: 8),
        _buildPeriodButton('Son 4 Hafta', ChartPeriod.week),
        const SizedBox(width: 8),
        _buildPeriodButton('Son 12 Ay', ChartPeriod.month),
      ],
    );
  }

  Widget _buildPeriodButton(String label, ChartPeriod period) {
    final isActive = selectedPeriod == period;
    return GestureDetector(
      onTap: () => onPeriodChanged(period),
      child: Container(
        height: 38.0, // Fixed height for consistent button size
        padding: const EdgeInsets.symmetric(horizontal: 24.0), // Only horizontal padding
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center, // Center alignment for container
        child: Center(
          // Center widget wrapper to guarantee absolute middle positioning
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[800],
              fontWeight: FontWeight.w600,
              fontSize: 17.0,
              height: 1.0, // Tight line height to remove default font padding
              leadingDistribution: TextLeadingDistribution.even, // Force glyphs to be centered within line height
            ),
            textAlign: TextAlign.center, // Center text alignment
          ),
        ),
      ),
    );
  }
}

