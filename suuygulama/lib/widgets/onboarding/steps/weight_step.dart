import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';
import '../onboarding_theme.dart';

/// Weight selection step for onboarding flow.
/// 
/// Features a clean wheel picker with soft styling and unit toggle.
class WeightStep extends StatefulWidget {
  final int selectedWeight;
  final int weightUnit; // 0 = kg, 1 = lbs
  final ValueChanged<int> onWeightChanged;
  final ValueChanged<int> onWeightUnitChanged;
  final VoidCallback? onNext;
  final FixedExtentScrollController weightController;

  const WeightStep({
    super.key,
    required this.selectedWeight,
    required this.weightUnit,
    required this.onWeightChanged,
    required this.onWeightUnitChanged,
    this.onNext,
    required this.weightController,
  });

  @override
  State<WeightStep> createState() => _WeightStepState();
}

class _WeightStepState extends State<WeightStep> {
  late List<int> weightValues;

  @override
  void initState() {
    super.initState();
    _updateWeightValues();
  }

  @override
  void didUpdateWidget(WeightStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weightUnit != widget.weightUnit) {
      _updateWeightValues();
    }
  }

  void _updateWeightValues() {
    if (widget.weightUnit == 0) {
      weightValues = List.generate(171, (index) => 30 + index); // 30-200 kg
    } else {
      weightValues = List.generate(376, (index) => 66 + index); // 66-441 lbs
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialWeightIndex = widget.selectedWeight > 0
        ? (widget.weightUnit == 0
            ? (widget.selectedWeight >= 30 && widget.selectedWeight <= 200
                ? widget.selectedWeight - 30
                : 40)
            : (widget.selectedWeight >= 66 && widget.selectedWeight <= 441
                ? widget.selectedWeight - 66
                : 100))
        : (widget.weightUnit == 0 ? 40 : 100);

    if (widget.weightController.hasClients && 
        widget.weightController.selectedItem != initialWeightIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.weightController.hasClients && 
            widget.weightController.selectedItem != initialWeightIndex) {
          widget.weightController.animateToItem(
            initialWeightIndex,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.all(OnboardingTheme.pagePadding),
      child: Column(
        children: [
          const Spacer(flex: 2),
          
          // Header
          const OnboardingHeader(
            title: 'Kilonuzu Girin',
            subtitle: 'Günlük su ihtiyacınızı doğru hesaplayabilmemiz için kilonuza ihtiyacımız var',
          ),
          
          const Spacer(flex: 2),
          
          // Weight Picker Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: OnboardingTheme.softShadow,
              border: Border.all(
                color: OnboardingTheme.borderColor,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Wheel Picker
                SizedBox(
                  width: 100,
                  height: 180,
                  child: CupertinoPicker(
                    scrollController: widget.weightController,
                    itemExtent: 50,
                    selectionOverlay: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: OnboardingTheme.primaryAccent.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          bottom: BorderSide(
                            color: OnboardingTheme.primaryAccent.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    onSelectedItemChanged: (index) {
                      widget.onWeightChanged(weightValues[index]);
                    },
                    children: weightValues.map((weight) {
                      return Center(
                        child: Text(
                          weight.toString(),
                          style: OnboardingTheme.valueDisplayStyle.copyWith(
                            fontSize: 28,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                const SizedBox(width: 24),
                
                // Unit Toggle
                _UnitToggle(
                  selectedUnit: widget.weightUnit,
                  onUnitChanged: widget.onWeightUnitChanged,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Selected Value Display
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              widget.selectedWeight > 0 
                  ? '${widget.selectedWeight} ${widget.weightUnit == 0 ? 'kg' : 'lbs'}'
                  : 'Seçim yapın',
              key: ValueKey('${widget.selectedWeight}_${widget.weightUnit}'),
              style: OnboardingTheme.valueDisplayStyle.copyWith(
                color: widget.selectedWeight > 0 
                    ? OnboardingTheme.primaryAccent 
                    : OnboardingTheme.textTertiary,
                fontSize: 32,
              ),
            ),
          ),
          
          const Spacer(flex: 3),
          
          // Continue Button
          OnboardingPrimaryButton(
            label: 'Devam Et',
            onPressed: widget.selectedWeight > 0 ? widget.onNext : null,
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Unit toggle (kg/lbs) with soft styling
class _UnitToggle extends StatelessWidget {
  final int selectedUnit;
  final ValueChanged<int> onUnitChanged;

  const _UnitToggle({
    required this.selectedUnit,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: OnboardingTheme.primaryAccentLight,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _UnitButton(
                label: 'kg',
                isSelected: selectedUnit == 0,
                onTap: () async {
                  await userProvider.setIsMetric(true);
                  onUnitChanged(0);
                },
              ),
              const SizedBox(height: 4),
              _UnitButton(
                label: 'lbs',
                isSelected: selectedUnit == 1,
                onTap: () async {
                  await userProvider.setIsMetric(false);
                  onUnitChanged(1);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UnitButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnitButton({
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
