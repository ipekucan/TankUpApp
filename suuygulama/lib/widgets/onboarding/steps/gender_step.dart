import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Gender selection step for onboarding flow.
/// 
/// Displays two circular buttons for selecting gender (Male/Female).
/// Uses AppTextStyles for consistent styling.
class GenderStep extends StatelessWidget {
  final String? selectedGender;
  final ValueChanged<String> onGenderSelected;
  final VoidCallback? onNext;

  const GenderStep({
    super.key,
    required this.selectedGender,
    required this.onGenderSelected,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Cinsiyet Seçiniz',
            style: AppTextStyles.heading1,
          ),
          const SizedBox(height: 10),
          Text(
            'Kişisel hidrasyon planınızı oluşturmak için cinsiyetinizi seçin',
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          
          // Yan yana iki dairesel buton
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Erkek Butonu
              _GenderButton(
                isSelected: selectedGender == 'male',
                icon: Icons.person,
                label: 'Erkek',
                onTap: () => onGenderSelected('male'),
              ),
              
              const SizedBox(width: 32),
              
              // Kadın Butonu
              _GenderButton(
                isSelected: selectedGender == 'female',
                icon: Icons.person_outline,
                label: 'Kadın',
                onTap: () => onGenderSelected('female'),
              ),
            ],
          ),
          
          const SizedBox(height: 60),
          
          // İleri Butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedGender != null ? onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.softPinkButton,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[500],
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
        ],
      ),
    );
  }
}

/// Circular gender selection button widget.
class _GenderButton extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GenderButton({
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected 
              ? AppColors.softPinkButton 
              : Colors.white,
          border: Border.all(
            color: isSelected 
                ? AppColors.softPinkButton 
                : Colors.grey[300]!,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.softPinkButton.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 60,
              color: isSelected 
                  ? Colors.white 
                  : AppColors.softPinkButton,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isSelected 
                    ? Colors.white 
                    : const Color(0xFF4A5568),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

