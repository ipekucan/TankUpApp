import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/drink_helpers.dart';
import '../theme/app_text_styles.dart';
import '../models/drink_model.dart';
import '../providers/daily_hydration_provider.dart';
import '../providers/user_provider.dart';
import '../utils/unit_converter.dart';
import '../services/chart_data_service.dart';
import 'drink_amount_selector.dart';

/// Modern drink selection modal with horizontal scrollable drink buttons
class DrinkSelectionModal extends StatefulWidget {
  const DrinkSelectionModal({super.key});

  @override
  State<DrinkSelectionModal> createState() => _DrinkSelectionModalState();
}

class _DrinkSelectionModalState extends State<DrinkSelectionModal> {
  late PageController _pageController;
  String? _selectedDrinkId;
  int _currentPage = 0;
  bool _showAmountSelector = false;
  Drink? _selectedDrink;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
  }

  // First page drinks (8 drinks including water)
  final List<String> _firstPageDrinks = [
    'water',
    'coffee',
    'tea',
    'juice',
    'milk',
    'soda',
    'sports',
    'lemonade',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<List<String>> _getDrinkPages() {
    final allDrinks = DrinkData.getDrinks();
    final allDrinkIds = allDrinks.map((d) => d.id).toList();
    
    // Remaining drinks after first page
    final remainingDrinks = allDrinkIds
        .where((id) => !_firstPageDrinks.contains(id))
        .toList();

    final pages = <List<String>>[];
    pages.add(_firstPageDrinks);

    // Add remaining drinks in groups of 8
    for (int i = 0; i < remainingDrinks.length; i += 8) {
      final endIndex = (i + 8 < remainingDrinks.length) 
          ? i + 8 
          : remainingDrinks.length;
      pages.add(remainingDrinks.sublist(i, endIndex));
    }

    return pages;
  }

  void _onDrinkSelected(String drinkId) {
    final drink = DrinkData.getDrinks().firstWhere((d) => d.id == drinkId);
    setState(() {
      _selectedDrinkId = drinkId;
      _selectedDrink = drink;
      _showAmountSelector = true;
    });
  }

  void _onBackToSelection() {
    setState(() {
      _showAmountSelector = false;
      _selectedDrinkId = null;
      _selectedDrink = null;
      // Preserve page state - recreate controller with current page
      _pageController = PageController(initialPage: _currentPage);
    });
  }

  void _addDrink(double amount) async {
    if (_selectedDrinkId == null) return;

    final dailyHydrationProvider = context.read<DailyHydrationProvider>();
    final userProvider = context.read<UserProvider>();

    final drink = DrinkData.getDrinks().firstWhere((d) => d.id == _selectedDrinkId);
    final result = await dailyHydrationProvider.drink(
      drink,
      amount,
      context: context,
    );

    if (!mounted) return;

    if (result.success) {
      await userProvider.addToTotalWater(amount * drink.hydrationFactor);

      if (!mounted) return;

      // Success notification
      final formattedAmount = UnitConverter.formatVolume(amount, userProvider.isMetric);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(DrinkHelpers.getEmoji(_selectedDrinkId!), style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$formattedAmount ${drink.name} eklendi!',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primaryBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );

      if (dailyHydrationProvider.hasReachedDailyGoal) {
        await userProvider.updateConsecutiveDays(true);
      }

      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show amount selector if drink is selected
    if (_showAmountSelector && _selectedDrink != null) {
      return DrinkAmountSelector(
        drink: _selectedDrink!,
        onBack: _onBackToSelection,
        onConfirm: _addDrink,
      );
    }

    // Show drink selection grid
    final drinkPages = _getDrinkPages();

    return Container(
      height: MediaQuery.of(context).size.height * 0.42, // Shorter (was 0.5)
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // Solid light blue, not half opaque
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardBorder.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'İçecek Seç',
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.5,
              ),
            ),
          ),

          // Drink buttons - Horizontal scrollable pages
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemCount: drinkPages.length,
              itemBuilder: (context, pageIndex) {
                return _buildDrinkGrid(drinkPages[pageIndex]);
              },
            ),
          ),

          // Page indicator at bottom
          if (drinkPages.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  drinkPages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == index ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.primaryBlue.withValues(alpha: 0.8)
                          : AppColors.textSecondary.withValues(alpha: 0.4), // More visible
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDrinkGrid(List<String> drinkIds) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.85, // Taller for icon + name
      ),
      itemCount: drinkIds.length,
      itemBuilder: (context, index) {
        final drinkId = drinkIds[index];
        final drink = DrinkData.getDrinks().firstWhere((d) => d.id == drinkId);
        final isSelected = _selectedDrinkId == drinkId;
        final color = ChartDataService.drinkColors[drinkId] ?? AppColors.secondaryAqua;

        return GestureDetector(
          onTap: () {
            _onDrinkSelected(drinkId);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with shadow
              Container(
                decoration: BoxDecoration(
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  DrinkHelpers.getEmoji(drinkId),
                  style: TextStyle(
                    fontSize: 52,
                    shadows: isSelected
                        ? [
                            Shadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ]
                        : [],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Name below icon
              Text(
                drink.name,
                style: TextStyle(
                  fontSize: 10, // Smaller font (was 11)
                  fontWeight: FontWeight.w500,
                  color: isSelected 
                      ? color 
                      : AppColors.textSecondary.withValues(alpha: 0.8),
                  letterSpacing: -0.3,
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
