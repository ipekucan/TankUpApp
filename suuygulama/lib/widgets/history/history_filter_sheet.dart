import 'package:flutter/material.dart';
import '../../models/drink_model.dart';
import '../../utils/drink_helpers.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/app_colors.dart';

class _FilterBottomSheetContent extends StatefulWidget {
  final Set<String> selectedFilters;
  final ValueChanged<Set<String>> onFiltersChanged;

  const _FilterBottomSheetContent({
    required this.selectedFilters,
    required this.onFiltersChanged,
  });

  @override
  State<_FilterBottomSheetContent> createState() => _FilterBottomSheetContentState();
}

class _FilterBottomSheetContentState extends State<_FilterBottomSheetContent> {
  late Set<String> _localSelectedFilters;

  @override
  void initState() {
    super.initState();
    _localSelectedFilters = Set.from(widget.selectedFilters);
  }

  @override
  Widget build(BuildContext context) {
    final allDrinks = DrinkData.getDrinks();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            'İçecekleri Filtrele',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 24),
          // Filter options
          Expanded(
            child: ListView(
              children: [
                // "Tümü" option
                _buildFilterOption(
                  id: '',
                  name: 'Tümü',
                  isSelected: _localSelectedFilters.isEmpty,
                ),
                const Divider(height: 1),
                // Individual drink options
                ...allDrinks.map(
                  (drink) => _buildFilterOption(
                    id: drink.id,
                    name: drink.name,
                    isSelected: _localSelectedFilters.contains(drink.id),
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _localSelectedFilters.clear();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Temizle',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onFiltersChanged(_localSelectedFilters);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.softPinkButton,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Uygula',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption({
    required String id,
    required String name,
    required bool isSelected,
  }) {
    return SizedBox(
      height: 56,
      child: Material(
        color: isSelected ? AppColors.softPinkButton.withValues(alpha: 0.15) : Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (id.isEmpty) {
                // "Tümü" selected
                _localSelectedFilters.clear();
              } else {
                if (_localSelectedFilters.contains(id)) {
                  _localSelectedFilters.remove(id);
                  // If all filters were removed, select "Tümü"
                  if (_localSelectedFilters.isEmpty) {
                    // Keep it empty - means all
                  }
                } else {
                  _localSelectedFilters.add(id);
                }
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? AppColors.softPinkButton : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected ? AppColors.softPinkButton : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                if (id.isNotEmpty) ...[
                  const Spacer(),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: DrinkHelpers.getColor(id).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      DrinkHelpers.getIcon(id),
                      color: DrinkHelpers.getColor(id),
                      size: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}