import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';


class HistoryFilterButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool hasActiveFilters;

  const HistoryFilterButton({
    super.key,
    required this.onTap,
    required this.hasActiveFilters,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: hasActiveFilters ? AppColors.softPinkButton : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: hasActiveFilters
              ? Border.all(color: AppColors.softPinkButton)
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_alt,
              size: 18,
              color: hasActiveFilters ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              'Filtre',
              style: TextStyle(
                fontSize: 12,
                color: hasActiveFilters ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}