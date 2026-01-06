import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// Selection button widget for onboarding sheets
class SelectionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  
  const SelectionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.secondaryAqua.withValues(alpha: 0.3) 
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? AppColors.secondaryAqua 
                  : Colors.grey[700],
              size: 28,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? AppColors.secondaryAqua 
                    : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
