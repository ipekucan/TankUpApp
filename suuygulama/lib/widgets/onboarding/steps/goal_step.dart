import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../utils/app_colors.dart';
import '../../../providers/user_provider.dart';
import '../../../theme/app_text_styles.dart';

/// Goal selection step for onboarding flow.
/// 
/// Displays amount adjustment bar, unit toggle, and smart goal suggestion.
/// Uses AppTextStyles for consistent styling.
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

    // Controller'ı güncel değerle senkronize et
    String text;
    if (isMetric) {
      text = widget.customGoal.toStringAsFixed(0);
    } else {
      text = widget.customGoal.toStringAsFixed(1);
    }
    if (widget.amountController.text != text) {
      widget.amountController.text = text;
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
          // Başlık - Ortalanmış
          Text(
            'Günlük Hedef',
            style: AppTextStyles.heading1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          
          // Alt açıklama metni
          Text(
            'Günlük su hedefinizi belirleyin',
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 80),
          
          // Miktar Ayarlama Barı ve Birim Toggle - Showcase ile sarmalanmış
          if (widget.showcaseKey != null)
            Showcase(
              key: widget.showcaseKey!,
              title: 'Hedefini Belirle',
              description: 'Günlük su hedefini buradaki butonlarla veya birim değiştiriciyle ayarlayabilirsin.',
              overlayColor: Colors.black.withValues(alpha: 0.5),
              overlayOpacity: 0.5,
              titleTextStyle: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              descTextStyle: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              tooltipBackgroundColor: const Color(0xFFFFF59D), // Soft Sarı
              textColor: Colors.black,
              tooltipPadding: const EdgeInsets.all(12),
              targetBorderRadius: BorderRadius.circular(16),
              targetShapeBorder: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.black, width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Miktar Ayarlama Barı
                  _buildAmountAdjustmentBar(isMetric),
                  
                  // Birim Seçim Toggle
                  const SizedBox(height: 24),
                  _buildUnitToggle(isMetric),
                ],
              ),
            )
          else
            Column(
              children: [
                _buildAmountAdjustmentBar(isMetric),
                const SizedBox(height: 24),
                _buildUnitToggle(isMetric),
              ],
            ),
          
          // Akıllı Hedef Önerisi
          if (widget.selectedWeight > 0 && widget.calculatedWaterGoal > 0) ...[
            const SizedBox(height: 24),
            _buildSmartGoalSuggestion(isMetric),
          ],
          
          const Spacer(),
          
          // Planı Oluştur Butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onComplete,
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
                'Planı Oluştur',
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

  Widget _buildAmountAdjustmentBar(bool isMetric) {
    String getDisplayUnit() {
      return isMetric ? 'ml' : 'oz';
    }

    void incrementAmount() {
      double newGoal = widget.customGoal;
      if (isMetric) {
        newGoal += 10.0; // 10 ml artır
      } else {
        newGoal += 10.0; // 10 oz artır
      }
      widget.onGoalChanged(newGoal);
    }

    void decrementAmount() {
      double newGoal = widget.customGoal;
      if (isMetric) {
        newGoal -= 10.0; // 10 ml azalt
      } else {
        newGoal -= 10.0; // 10 oz azalt
      }
      if (newGoal < 0) newGoal = 0.0;
      widget.onGoalChanged(newGoal);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.softPinkButton.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.softPinkButton.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // AZALT BUTONU
          GestureDetector(
            onTap: decrementAmount,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.softPinkButton.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.remove,
                color: AppColors.softPinkButton,
                size: 28,
              ),
            ),
          ),
          
          // TEXTFIELD VE BİRİM
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120,
                child: TextField(
                  controller: widget.amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: !isMetric),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.dateText.copyWith(
                    fontSize: 32,
                    letterSpacing: 0.5,
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
              const SizedBox(width: 8),
              Text(
                getDisplayUnit(),
                style: AppTextStyles.dateText.copyWith(
                  fontSize: 32,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          
          // ARTIR BUTONU
          GestureDetector(
            onTap: incrementAmount,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.softPinkButton,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.softPinkButton.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.softPinkButton.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.softPinkButton.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ml Butonu
              GestureDetector(
                onTap: () async {
                  if (isMetric) return; // Zaten ml seçili
                  
                  // Oz'dan ml'ye dönüştür
                  final currentOz = widget.customGoal;
                  final newMl = currentOz / 0.033814; // oz'dan ml'ye çevir
                  
                  widget.onGoalChanged(newMl.roundToDouble());
                  
                  // UserProvider'ı güncelle
                  await userProvider.setIsMetric(true);
                  
                  // Controller'ı güncelle
                  widget.amountController.text = newMl.roundToDouble().toStringAsFixed(0);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMetric ? AppColors.softPinkButton : Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Text(
                    'ml',
                    style: AppTextStyles.buttonText.copyWith(
                      color: isMetric ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              
              // oz Butonu
              GestureDetector(
                onTap: () async {
                  if (!isMetric) return; // Zaten oz seçili
                  
                  // Ml'den oz'a dönüştür
                  final currentMl = widget.customGoal;
                  final newOz = currentMl * 0.033814; // ml'den oz'a çevir
                  
                  widget.onGoalChanged(double.parse(newOz.toStringAsFixed(1)));
                  
                  // UserProvider'ı güncelle
                  await userProvider.setIsMetric(false);
                  
                  // Controller'ı güncelle
                  widget.amountController.text = newOz.toStringAsFixed(1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: !isMetric ? AppColors.softPinkButton : Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Text(
                    'oz',
                    style: AppTextStyles.buttonText.copyWith(
                      color: !isMetric ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmartGoalSuggestion(bool isMetric) {
    // Kilo girilene kadar 0 döndür
    if (widget.selectedWeight == 0) {
      return const SizedBox.shrink();
    }
    
    // Kilo dönüşümü (Lbs ise Kg'ye çevir)
    final weightInKg = widget.weightUnit == 1 
        ? widget.selectedWeight * 0.453592 
        : widget.selectedWeight.toDouble();
    
    // Temel formül: kilo * 35 (ml cinsinden)
    final idealMl = (weightInKg * 35).round();
    
    // Birime göre dönüştür
    double calculatedValue;
    String unit;
    String displayValue;
    
    if (isMetric) {
      // ml: ideal değerini olduğu gibi kullan
      calculatedValue = idealMl.toDouble();
      unit = 'ml';
      displayValue = calculatedValue.toStringAsFixed(0);
    } else {
      // oz: (ideal * 0.033814).round() işlemini yap
      calculatedValue = (idealMl * 0.033814);
      unit = 'oz';
      displayValue = calculatedValue.toStringAsFixed(1);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.softPinkButton.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.softPinkButton.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: AppColors.softPinkButton,
            size: 20,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Kilonuza ve bilgilerinize göre günlük su ihtiyacınız: $displayValue $unit',
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFF4A5568),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

