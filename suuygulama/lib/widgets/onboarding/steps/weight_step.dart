import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../providers/user_provider.dart';
import '../../../theme/app_text_styles.dart';

/// Weight selection step for onboarding flow.
/// 
/// Displays a CupertinoPicker for weight selection with unit toggle (kg/lbs).
/// Uses AppTextStyles for consistent styling.
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
  // WheelPicker için değerler (30-200 arası kg, 66-441 arası lbs)
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
      // kg: 30-200
      weightValues = List.generate(171, (index) => 30 + index);
    } else {
      // lbs: 66-441
      weightValues = List.generate(376, (index) => 66 + index);
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

    // Controller'ı state'te tutmak yerine, her build'de güncelle
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
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Kilonuzu Seçiniz',
            style: AppTextStyles.heading1,
          ),
          const SizedBox(height: 10),
          Text(
            'Hidrasyon hedefinizi hesaplamak için kilonuzu girin',
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          
          // Sol: WheelPicker, Sağ: Birim Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Sol: WheelPicker
              SizedBox(
                width: 120,
                height: 200,
                child: CupertinoPicker(
                  scrollController: widget.weightController,
                  itemExtent: 50,
                  onSelectedItemChanged: (index) {
                    widget.onWeightChanged(weightValues[index]);
                  },
                  children: weightValues.map((weight) {
                    return Center(
                      child: Text(
                        weight.toString(),
                        style: AppTextStyles.dateText.copyWith(fontSize: 24),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(width: 32),
              
              // Sağ: Birim Toggle (kg/lb)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // kg Seçeneği
                        GestureDetector(
                          onTap: () async {
                            final userProvider = Provider.of<UserProvider>(context, listen: false);
                            await userProvider.setIsMetric(true);
                            widget.onWeightUnitChanged(0);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: widget.weightUnit == 0 
                                  ? AppColors.softPinkButton 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Text(
                              'kg',
                              style: AppTextStyles.buttonTextLarge.copyWith(
                                color: widget.weightUnit == 0 
                                    ? Colors.white 
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // lbs Seçeneği
                        GestureDetector(
                          onTap: () async {
                            final userProvider = Provider.of<UserProvider>(context, listen: false);
                            await userProvider.setIsMetric(false);
                            widget.onWeightUnitChanged(1);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: widget.weightUnit == 1 
                                  ? AppColors.softPinkButton 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Text(
                              'lbs',
                              style: AppTextStyles.buttonTextLarge.copyWith(
                                color: widget.weightUnit == 1 
                                    ? Colors.white 
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Seçilen değer gösterimi
          Text(
            widget.selectedWeight > 0 
                ? '${widget.selectedWeight} ${widget.weightUnit == 0 ? 'kg' : 'lbs'}'
                : 'Seçiniz',
            style: AppTextStyles.dateText.copyWith(
              color: widget.selectedWeight > 0 
                  ? AppColors.softPinkButton 
                  : Colors.grey[400],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // İleri Butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.selectedWeight > 0 ? widget.onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.softPinkButton,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 22,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(35),
                ),
                elevation: 0,
              ),
              child: Text(
                'İleri',
                style: AppTextStyles.buttonTextLarge.copyWith(
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

