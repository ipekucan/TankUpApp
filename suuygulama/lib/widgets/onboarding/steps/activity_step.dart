import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../providers/user_provider.dart';
import '../../../theme/app_text_styles.dart';

/// Activity level selection step for onboarding flow.
/// 
/// Displays three horizontal buttons for activity levels (Low, Medium, High).
/// Uses AppTextStyles for consistent styling.
class ActivityStep extends StatelessWidget {
  final String? selectedActivityLevel;
  final ValueChanged<String> onActivityLevelSelected;
  final VoidCallback? onNext;

  const ActivityStep({
    super.key,
    required this.selectedActivityLevel,
    required this.onActivityLevelSelected,
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
            'Aktivite Seviyeniz',
            style: AppTextStyles.heading1,
          ),
          const SizedBox(height: 10),
          Text(
            'Günlük aktivite seviyenizi seçin',
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          
          // 3 Yatay Dikdörtgen Buton
          Column(
            children: [
              // Düşük Aktivite
              _ActivityButton(
                title: 'Düşük',
                icon: Icons.directions_walk,
                isSelected: selectedActivityLevel == 'low',
                onTap: () => onActivityLevelSelected('low'),
              ),
              
              const SizedBox(height: 16),
              
              // Orta Aktivite
              _ActivityButton(
                title: 'Orta',
                icon: Icons.directions_run,
                isSelected: selectedActivityLevel == 'medium',
                onTap: () => onActivityLevelSelected('medium'),
              ),
              
              const SizedBox(height: 16),
              
              // Yüksek Aktivite
              _ActivityButton(
                title: 'Yüksek',
                icon: Icons.sports_gymnastics,
                isSelected: selectedActivityLevel == 'high',
                onTap: () => onActivityLevelSelected('high'),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // İleri Butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedActivityLevel != null
                  ? () async {
                      // Provider'a kaydet
                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                      await userProvider.updateProfile(activityLevel: selectedActivityLevel);
                      // Sonraki sayfaya geç
                      onNext?.call();
                    }
                  : null,
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

/// Activity level selection button widget.
class _ActivityButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActivityButton({
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

