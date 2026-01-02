import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';
import '../onboarding_theme.dart';

/// Activity level selection step for onboarding flow.
/// 
/// Displays three beautiful option cards for activity levels.
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
      padding: const EdgeInsets.all(OnboardingTheme.pagePadding),
      child: Column(
        children: [
          const Spacer(flex: 2),
          
          // Header
          const OnboardingHeader(
            title: 'Aktivite Seviyeniz',
            subtitle: 'Günlük aktivite düzeyinize göre su ihtiyacınızı ayarlayacağız',
          ),
          
          const Spacer(flex: 2),
          
          // Activity Options
          _ActivityOptionCard(
            title: 'Düşük Aktivite',
            subtitle: 'Masa başı iş, az hareket',
            icon: Icons.weekend_outlined,
            isSelected: selectedActivityLevel == 'low',
            color: const Color(0xFF98D4BB), // Soft mint
            onTap: () => onActivityLevelSelected('low'),
          ),
          
          const SizedBox(height: 14),
          
          _ActivityOptionCard(
            title: 'Orta Aktivite',
            subtitle: 'Hafif egzersiz, günlük yürüyüş',
            icon: Icons.directions_walk_rounded,
            isSelected: selectedActivityLevel == 'medium',
            color: const Color(0xFF7EC8E3), // Soft blue
            onTap: () => onActivityLevelSelected('medium'),
          ),
          
          const SizedBox(height: 14),
          
          _ActivityOptionCard(
            title: 'Yüksek Aktivite',
            subtitle: 'Yoğun spor, ağır fiziksel iş',
            icon: Icons.fitness_center_rounded,
            isSelected: selectedActivityLevel == 'high',
            color: const Color(0xFFE8A0BF), // Soft pink
            onTap: () => onActivityLevelSelected('high'),
          ),
          
          const Spacer(flex: 3),
          
          // Continue Button
          OnboardingPrimaryButton(
            label: 'Devam Et',
            onPressed: selectedActivityLevel != null
                ? () async {
                    final userProvider = Provider.of<UserProvider>(context, listen: false);
                    await userProvider.updateProfile(activityLevel: selectedActivityLevel);
                    onNext?.call();
                  }
                : null,
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Custom activity option card with unique color accent
class _ActivityOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ActivityOptionCard({
    required this.title,
    required this.subtitle,
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
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? color : OnboardingTheme.borderColor,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 16,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ]
              : OnboardingTheme.softShadow,
        ),
        child: Row(
          children: [
            // Icon Container
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, color.withValues(alpha: 0.8)],
                      )
                    : null,
                color: isSelected ? null : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : color,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: OnboardingTheme.optionLabelStyle.copyWith(
                      color: isSelected ? color : OnboardingTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: OnboardingTheme.subtitleStyle.copyWith(
                      fontSize: 13,
                      color: OnboardingTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Checkmark
            AnimatedScale(
              scale: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
