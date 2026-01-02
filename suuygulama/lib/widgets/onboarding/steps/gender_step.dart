import 'package:flutter/material.dart';
import '../onboarding_theme.dart';

/// Gender selection step for onboarding flow.
/// 
/// Clean, airy design with soft pastel tones and gentle animations.
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
      padding: const EdgeInsets.all(OnboardingTheme.pagePadding),
      child: Column(
        children: [
          const Spacer(flex: 2),
          
          // Header
          const OnboardingHeader(
            title: 'Cinsiyetinizi Seçin',
            subtitle: 'Kişiselleştirilmiş hidrasyon planınızı oluşturmak için bu bilgiye ihtiyacımız var',
          ),
          
          const Spacer(flex: 3),
          
          // Gender Selection Circles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Male
              _GenderCircle(
                isSelected: selectedGender == 'male',
                icon: Icons.male_rounded,
                label: 'Erkek',
                color: const Color(0xFF7EC8E3), // Soft blue
                onTap: () => onGenderSelected('male'),
              ),
              
              const SizedBox(width: 32),
              
              // Female
              _GenderCircle(
                isSelected: selectedGender == 'female',
                icon: Icons.female_rounded,
                label: 'Kadın',
                color: const Color(0xFFE8A0BF), // Soft pink
                onTap: () => onGenderSelected('female'),
              ),
            ],
          ),
          
          const Spacer(flex: 4),
          
          // Continue Button
          OnboardingPrimaryButton(
            label: 'Devam Et',
            onPressed: selectedGender != null ? onNext : null,
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Custom gender selection circle with unique styling
class _GenderCircle extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GenderCircle({
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color,
                    color.withValues(alpha: 0.8),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.transparent : color.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ]
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                size: 52,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: OnboardingTheme.optionLabelStyle.copyWith(
                color: isSelected ? Colors.white : OnboardingTheme.textPrimary,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
