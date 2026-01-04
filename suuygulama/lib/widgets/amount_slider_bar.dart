import 'package:flutter/material.dart';

/// Horizontal slider bar for amount selection
class AmountSliderBar extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final Color color;
  final ValueChanged<double> onChanged;

  const AmountSliderBar({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value - min) / (max - min);
    
    return Container(
      height: 32, // Visible container
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Progress fill
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.4),
                      color.withValues(alpha: 0.25),
                    ],
                  ),
                ),
              ),
            ),
            // Slider
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 0,
                thumbColor: color,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 11,
                  elevation: 3,
                ),
                overlayShape: RoundSliderOverlayShape(
                  overlayRadius: 18,
                ),
                overlayColor: color.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: ((max - min) / 50).round(),
                onChanged: onChanged,
                activeColor: Colors.transparent,
                inactiveColor: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
