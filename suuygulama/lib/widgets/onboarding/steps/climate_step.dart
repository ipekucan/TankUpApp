import 'package:flutter/material.dart';
import '../onboarding_theme.dart';

/// Climate selection step for onboarding flow.
/// 
/// Displays four climate options with weather-themed icons and colors.
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
      padding: const EdgeInsets.all(OnboardingTheme.pagePadding),
      child: Column(
        children: [
          const Spacer(flex: 2),
          
          // Header
          const OnboardingHeader(
            title: 'İkliminizi Seçin',
            subtitle: 'Yaşadığınız bölgenin iklimi su ihtiyacınızı etkiler',
          ),
          
          const Spacer(flex: 2),
          
          // Climate Options - 2x2 Grid
          Row(
            children: [
              Expanded(
                child: _ClimateCard(
                  title: 'Çok Sıcak',
                  icon: Icons.wb_sunny_rounded,
                  isSelected: selectedClimate == 'very_hot',
                  color: const Color(0xFFF7A072), // Warm coral
                  onTap: () => onClimateSelected('very_hot'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _ClimateCard(
                  title: 'Sıcak',
                  icon: Icons.wb_twilight_rounded,
                  isSelected: selectedClimate == 'hot',
                  color: const Color(0xFFFFB347), // Soft orange
                  onTap: () => onClimateSelected('hot'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 14),
          
          Row(
            children: [
              Expanded(
                child: _ClimateCard(
                  title: 'Ilıman',
                  icon: Icons.cloud_outlined,
                  isSelected: selectedClimate == 'warm',
                  color: const Color(0xFF7EC8E3), // Soft blue
                  onTap: () => onClimateSelected('warm'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _ClimateCard(
                  title: 'Soğuk',
                  icon: Icons.ac_unit_rounded,
                  isSelected: selectedClimate == 'cold',
                  color: const Color(0xFFB8D4E3), // Cool blue
                  onTap: () => onClimateSelected('cold'),
                ),
              ),
            ],
          ),
          
          const Spacer(flex: 3),
          
          // Continue Button
          OnboardingPrimaryButton(
            label: 'Devam Et',
            onPressed: selectedClimate != null ? onNext : null,
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Square climate selection card with icon and soft styling
class _ClimateCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ClimateCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        height: 130,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color,
                    color.withValues(alpha: 0.85),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.transparent : color.withValues(alpha: 0.25),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ]
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with animation
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white.withValues(alpha: 0.25) 
                      : color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Title
            Text(
              title,
              style: OnboardingTheme.optionLabelStyle.copyWith(
                color: isSelected ? Colors.white : OnboardingTheme.textPrimary,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            
            // Checkmark indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: isSelected ? 4 : 0,
              width: isSelected ? 24 : 0,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
