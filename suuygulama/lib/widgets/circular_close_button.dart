import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Circular close button for modal dialogs
class CircularCloseButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;

  const CircularCloseButton({
    super.key,
    required this.onTap,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.cardBackground.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.cardBorder.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.close,
          size: size * 0.5,
          color: AppColors.textSecondary.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
