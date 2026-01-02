import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../providers/user_provider.dart';
import '../onboarding_theme.dart';

/// Goal selection step for onboarding flow.
/// 
/// Allows users to set their daily water intake goal with a beautiful UI.
class GoalStep extends StatefulWidget {
  final double customGoal;
  final int selectedWeight;
  final int weightUnit; // 0 = kg, 1 = lbs
  final double calculatedWaterGoal;
  final ValueChanged<double> onGoalChanged;
  final VoidCallback onComplete;
  final GlobalKey? showcaseKey;
  final TextEditingController amountController;

  const GoalStep({
    super.key,
    required this.customGoal,
    required this.selectedWeight,
    required this.weightUnit,
    required this.calculatedWaterGoal,
    required this.onGoalChanged,
    required this.onComplete,
    this.showcaseKey,
    required this.amountController,
  });

  @override
  State<GoalStep> createState() => _GoalStepState();
}

class _GoalStepState extends State<GoalStep> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isMetric = userProvider.isMetric;

    // Sync controller with current value
    String text = isMetric 
        ? widget.customGoal.toStringAsFixed(0)
        : widget.customGoal.toStringAsFixed(1);
    if (widget.amountController.text != text) {
      widget.amountController.text = text;
    }

    return Padding(
      padding: const EdgeInsets.all(OnboardingTheme.pagePadding),
      child: Column(
        children: [
          const Spacer(flex: 2),
          
          // Header
          const OnboardingHeader(
            title: 'Günlük Hedefiniz',
            subtitle: 'Her gün içmek istediğiniz su miktarını belirleyin',
          ),
          
          const Spacer(flex: 2),
          
          // Goal adjustment card with showcase
          if (widget.showcaseKey != null)
            Showcase(
              key: widget.showcaseKey!,
              title: 'Hedefini Belirle',
              description: 'Butonlarla veya direkt yazarak günlük su hedefini ayarla.',
              overlayColor: Colors.black.withValues(alpha: 0.5),
              overlayOpacity: 0.5,
              titleTextStyle: OnboardingTheme.optionLabelStyle,
              descTextStyle: OnboardingTheme.subtitleStyle.copyWith(color: Colors.black87),
              tooltipBackgroundColor: Colors.white,
              textColor: OnboardingTheme.textPrimary,
              tooltipPadding: const EdgeInsets.all(16),
              targetBorderRadius: BorderRadius.circular(28),
              child: _buildGoalAdjustmentCard(isMetric),
            )
          else
            _buildGoalAdjustmentCard(isMetric),
          
          const SizedBox(height: 20),
          
          // Unit toggle
          _buildUnitToggle(isMetric),
          
          // Smart suggestion
          if (widget.selectedWeight > 0 && widget.calculatedWaterGoal > 0) ...[
            const SizedBox(height: 24),
            _buildSmartSuggestion(isMetric),
          ],
          
          const Spacer(flex: 3),
          
          // Complete Button
          OnboardingPrimaryButton(
            label: 'Planı Oluştur',
            onPressed: widget.onComplete,
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildGoalAdjustmentCard(bool isMetric) {
    String unit = isMetric ? 'ml' : 'oz';

    void increment() {
      double newGoal = widget.customGoal + (isMetric ? 50.0 : 2.0);
      widget.onGoalChanged(newGoal);
    }

    void decrement() {
      double newGoal = widget.customGoal - (isMetric ? 50.0 : 2.0);
      if (newGoal < 0) newGoal = 0;
      widget.onGoalChanged(newGoal);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: OnboardingTheme.primaryAccent.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: OnboardingTheme.primaryAccent.withValues(alpha: 0.1),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Decrement button
          _CircleButton(
            icon: Icons.remove_rounded,
            onTap: decrement,
            isPrimary: false,
          ),
          
          // Value display
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Text field for value
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: widget.amountController,
                        keyboardType: TextInputType.numberWithOptions(decimal: !isMetric),
                        textAlign: TextAlign.center,
                        style: OnboardingTheme.valueDisplayStyle.copyWith(
                          color: OnboardingTheme.primaryAccent,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onChanged: (value) {
                          final numValue = double.tryParse(value);
                          if (numValue != null && numValue >= 0) {
                            widget.onGoalChanged(numValue);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        unit,
                        style: OnboardingTheme.unitStyle.copyWith(
                          color: OnboardingTheme.primaryAccent,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Increment button
          _CircleButton(
            icon: Icons.add_rounded,
            onTap: increment,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildUnitToggle(bool isMetric) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: OnboardingTheme.primaryAccentLight,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ml button
              _UnitToggleButton(
                label: 'ml',
                isSelected: isMetric,
                onTap: () async {
                  if (isMetric) return;
                  final currentOz = widget.customGoal;
                  final newMl = currentOz / 0.033814;
                  widget.onGoalChanged(newMl.roundToDouble());
                  await userProvider.setIsMetric(true);
                  widget.amountController.text = newMl.roundToDouble().toStringAsFixed(0);
                },
              ),
              const SizedBox(width: 4),
              // oz button
              _UnitToggleButton(
                label: 'oz',
                isSelected: !isMetric,
                onTap: () async {
                  if (!isMetric) return;
                  final currentMl = widget.customGoal;
                  final newOz = currentMl * 0.033814;
                  widget.onGoalChanged(double.parse(newOz.toStringAsFixed(1)));
                  await userProvider.setIsMetric(false);
                  widget.amountController.text = newOz.toStringAsFixed(1);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmartSuggestion(bool isMetric) {
    if (widget.selectedWeight == 0) return const SizedBox.shrink();
    
    final weightInKg = widget.weightUnit == 1 
        ? widget.selectedWeight * 0.453592 
        : widget.selectedWeight.toDouble();
    
    final idealMl = (weightInKg * 35).round();
    
    double calculatedValue;
    String unit;
    String displayValue;
    
    if (isMetric) {
      calculatedValue = idealMl.toDouble();
      unit = 'ml';
      displayValue = calculatedValue.toStringAsFixed(0);
    } else {
      calculatedValue = idealMl * 0.033814;
      unit = 'oz';
      displayValue = calculatedValue.toStringAsFixed(1);
    }
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OnboardingTheme.primaryAccentLight,
            OnboardingTheme.primaryAccent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: OnboardingTheme.primaryAccent.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: OnboardingTheme.primaryAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: OnboardingTheme.primaryAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Önerilen Miktar',
                  style: OnboardingTheme.optionLabelStyle.copyWith(
                    fontSize: 14,
                    color: OnboardingTheme.primaryAccentDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$displayValue $unit / gün',
                  style: OnboardingTheme.subtitleStyle.copyWith(
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Apply suggestion button
          GestureDetector(
            onTap: () {
              widget.onGoalChanged(calculatedValue);
              widget.amountController.text = displayValue;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: OnboardingTheme.primaryAccent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: OnboardingTheme.primaryAccent.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Uygula',
                style: OnboardingTheme.buttonTextStyle.copyWith(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circle button for increment/decrement
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    OnboardingTheme.primaryAccent,
                    OnboardingTheme.primaryAccentDark,
                  ],
                )
              : null,
          color: isPrimary ? null : OnboardingTheme.primaryAccent.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: OnboardingTheme.primaryAccent.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isPrimary ? Colors.white : OnboardingTheme.primaryAccent,
          size: 28,
        ),
      ),
    );
  }
}

/// Unit toggle button
class _UnitToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnitToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? OnboardingTheme.primaryAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: OnboardingTheme.primaryAccent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: OnboardingTheme.buttonTextStyle.copyWith(
            color: isSelected ? Colors.white : OnboardingTheme.textSecondary,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}