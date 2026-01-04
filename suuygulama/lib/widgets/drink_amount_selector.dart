import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../models/drink_model.dart';
import '../providers/user_provider.dart';
import '../services/chart_data_service.dart';
import 'amount_slider_bar.dart';
import 'animated_fill_glass.dart'; // Animated glass with fill
import 'circular_close_button.dart';

/// Amount selector card for a specific drink
class DrinkAmountSelector extends StatefulWidget {
  final Drink drink;
  final VoidCallback onBack;
  final Function(double amount) onConfirm;

  const DrinkAmountSelector({
    super.key,
    required this.drink,
    required this.onBack,
    required this.onConfirm,
  });

  @override
  State<DrinkAmountSelector> createState() => _DrinkAmountSelectorState();
}

class _DrinkAmountSelectorState extends State<DrinkAmountSelector> {
  double _selectedAmount = 250.0;
  final double _minAmount = 50.0;
  final double _maxAmount = 1000.0;

  @override
  Widget build(BuildContext context) {
    final color = ChartDataService.drinkColors[widget.drink.id] ?? AppColors.secondaryAqua;

    return Container(
      height: MediaQuery.of(context).size.height * 0.55, // Taller (was 0.42)
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // Solid light blue
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

          // Header with back button, drink name, and close button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.cardBorder.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Close button (right corner)
                CircularCloseButton(
                  onTap: widget.onBack,
                  size: 36,
                ),
              ],
            ),
          ),

          // Drink name centered with underline - Higher position
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8), // Less vertical padding
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.drink.name,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.9), // More bold
                    fontSize: 26, // Larger (was 24)
                    fontWeight: FontWeight.w600, // Bold and rounded (was w300)
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 2, // Thicker underline
                  width: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.0),
                        color.withValues(alpha: 0.4),
                        color.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8), // Less spacing

          // Animated glass with fill in center
          Expanded(
            child: Center(
              child: AnimatedFillGlass(
                liquidColor: color,
                amount: _selectedAmount,
                maxAmount: 1000,
                width: 140, // Bigger (was 120)
                height: 220, // Bigger (was 200)
              ),
            ),
          ),

          // Amount display
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final displayValue = userProvider.isMetric 
                  ? '${_selectedAmount.toStringAsFixed(0)} ml'
                  : '${(_selectedAmount * 0.033814).toStringAsFixed(1)} oz';
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  displayValue,
                  style: AppTextStyles.heading1.copyWith(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
              );
            },
          ),

          // Slider bar (minimal)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: AmountSliderBar(
              value: _selectedAmount,
              min: _minAmount,
              max: _maxAmount,
              color: color,
              onChanged: (value) {
                setState(() {
                  _selectedAmount = (value / 50).round() * 50.0;
                });
              },
            ),
          ),

          const SizedBox(height: 20), // Reduced spacing

          // Pour button - Wide rectangle
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 16), // Wider margins
            child: SizedBox(
              height: 48, // Same compact height
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12), // Less rounded (was 24)
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.9),
                      color.withValues(alpha: 0.75),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => widget.onConfirm(_selectedAmount),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'İç',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
