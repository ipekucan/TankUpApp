import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Climate selection step for onboarding flow.
/// 
/// Displays four horizontal buttons for climate types (Very Hot, Hot, Warm, Cold).
/// Uses AppTextStyles for consistent styling.
class ClimateStep extends StatelessWidget {
  final String? selectedClimate;
  final ValueChanged<String> onClimateSelected;
  final VoidCallback? onNext;

  const ClimateStep({
    super.key,
    required this.selectedClimate,
    required this.onClimateSelected,
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
            'İklim Seçiniz',
            style: AppTextStyles.heading1,
          ),
          const SizedBox(height: 10),
          Text(
            'Yaşadığınız bölgenin iklim tipini seçin',
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          
          // 4 Yatay Dikdörtgen Buton
          Column(
            children: [
              // Çok Sıcak
              _ClimateButton(
                title: 'Çok Sıcak',
                icon: Icons.wb_sunny,
                isSelected: selectedClimate == 'very_hot',
                onTap: () => onClimateSelected('very_hot'),
              ),
              
              const SizedBox(height: 16),
              
              // Sıcak
              _ClimateButton(
                title: 'Sıcak',
                icon: Icons.wb_twilight,
                isSelected: selectedClimate == 'hot',
                onTap: () => onClimateSelected('hot'),
              ),
              
              const SizedBox(height: 16),
              
              // Ilıman
              _ClimateButton(
                title: 'Ilıman',
                icon: Icons.wb_cloudy,
                isSelected: selectedClimate == 'warm',
                onTap: () => onClimateSelected('warm'),
              ),
              
              const SizedBox(height: 16),
              
              // Soğuk
              _ClimateButton(
                title: 'Soğuk',
                icon: Icons.ac_unit,
                isSelected: selectedClimate == 'cold',
                onTap: () => onClimateSelected('cold'),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // İleri Butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedClimate != null ? onNext : null,
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
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Climate selection button widget.
class _ClimateButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClimateButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.softPinkButton.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected 
                ? AppColors.softPinkButton 
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.softPinkButton.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Sol: Metin
            Text(
              title,
              style: AppTextStyles.heading3.copyWith(
                fontSize: 20,
                color: isSelected 
                    ? AppColors.softPinkButton 
                    : const Color(0xFF4A5568),
              ),
            ),
            
            // Sağ: İkon
            Icon(
              icon,
              size: 32,
              color: isSelected 
                  ? AppColors.softPinkButton 
                  : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}

