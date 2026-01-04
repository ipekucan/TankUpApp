import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/drink_model.dart';
import '../../utils/drink_helpers.dart';
import '../../services/chart_data_service.dart';

/// Filter button widget for drink filtering
class HistoryFilterButton extends StatelessWidget {
  final VoidCallback onTap;
  final int activeFilterCount;

  const HistoryFilterButton({
    super.key,
    required this.onTap,
    required this.activeFilterCount,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = activeFilterCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: hasActiveFilters ? AppColors.primaryBlue : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasActiveFilters ? AppColors.primaryBlue : AppColors.cardBorder,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list,
              size: 20,
              color: hasActiveFilters ? AppColors.textWhite : AppColors.textSecondary,
            ),
            if (hasActiveFilters) const SizedBox(width: 6),
            if (hasActiveFilters)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.textWhite.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$activeFilterCount',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Filter Bottom Sheet
class HistoryFilterBottomSheet extends StatefulWidget {
  final Set<String> initialFilters;
  final Function(Set<String>) onApply;

  const HistoryFilterBottomSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<HistoryFilterBottomSheet> createState() => _HistoryFilterBottomSheetState();
}

class _HistoryFilterBottomSheetState extends State<HistoryFilterBottomSheet> {
  late Set<String> _selectedFilters;

  @override
  void initState() {
    super.initState();
    _selectedFilters = Set<String>.from(widget.initialFilters);
  }

  @override
  Widget build(BuildContext context) {
    final allDrinks = DrinkData.getDrinks();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Divider(height: 1, color: AppColors.cardBorder),
          _buildDrinkList(allDrinks),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('İçecek Filtresi', style: AppTextStyles.heading3),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDrinkList(List<Drink> allDrinks) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FilterItem(
            isAll: true,
            isSelected: _selectedFilters.isEmpty,
            emoji: '🌊',
            name: 'Tümü',
            onTap: () => setState(() => _selectedFilters.clear()),
          ),
          const SizedBox(height: 8),
          ...allDrinks.map((drink) {
            final isSelected = _selectedFilters.contains(drink.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FilterItem(
                isSelected: isSelected,
                emoji: DrinkHelpers.getEmoji(drink.id),
                name: drink.name,
                color: ChartDataService.drinkColors[drink.id],
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedFilters.remove(drink.id);
                    } else {
                      _selectedFilters.add(drink.id);
                    }
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _selectedFilters.clear()),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppColors.cardBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Temizle',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(Set<String>.from(_selectedFilters));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Uygula',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textWhite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual filter item widget
class _FilterItem extends StatelessWidget {
  final bool isAll;
  final bool isSelected;
  final String emoji;
  final String name;
  final Color? color;
  final VoidCallback onTap;

  const _FilterItem({
    this.isAll = false,
    required this.isSelected,
    required this.emoji,
    required this.name,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withValues(alpha: 0.1)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            _buildCheckbox(),
            const SizedBox(width: 16),
            _buildIcon(),
            const SizedBox(width: 16),
            _buildName(),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? AppColors.primaryBlue : Colors.transparent,
        border: Border.all(
          color: isSelected ? AppColors.primaryBlue : AppColors.cardBorder,
          width: 2,
        ),
      ),
      child: isSelected
          ? Icon(Icons.check, color: AppColors.textWhite, size: 16)
          : null,
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: (color ?? AppColors.primaryBlue).withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  Widget _buildName() {
    return Expanded(
      child: Text(
        name,
        style: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}
