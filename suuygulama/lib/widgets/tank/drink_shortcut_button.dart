import 'package:flutter/material.dart';
import '../../models/drink_model.dart';
import '../../utils/drink_helpers.dart';
import '../../services/chart_data_service.dart';
import '../../utils/app_colors.dart';

/// Circular shortcut button for quick drink access
class DrinkShortcutButton extends StatelessWidget {
  final Drink drink;
  final VoidCallback onTap;

  const DrinkShortcutButton({
    super.key,
    required this.drink,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = ChartDataService.drinkColors[drink.id] ?? AppColors.secondaryAqua;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 2,
          ),
          // Gölge kaldırıldı - düz görünüm
        ),
        child: Center(
          child: Text(
            DrinkHelpers.getEmoji(drink.id),
            style: const TextStyle(fontSize: 28),
          ),
        ),
      ),
    );
  }
}
