import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_card.dart';

/// Control panel for challenges with breathing start button and onboarding card.
class ChallengeControlPanel extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onStartPressed;

  const ChallengeControlPanel({
    super.key,
    required this.isActive,
    this.onStartPressed,
  });

  @override
  State<ChallengeControlPanel> createState() => _ChallengeControlPanelState();
}

class _ChallengeControlPanelState extends State<ChallengeControlPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  bool _showOnboardingCard = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  /// Check if onboarding card should be shown (first time only).
  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('challenge_onboarding_seen') ?? false;
    if (!hasSeenOnboarding) {
      setState(() {
        _showOnboardingCard = true;
      });
    }
  }

  /// Dismiss onboarding card and mark as seen.
  Future<void> _dismissOnboardingCard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('challenge_onboarding_seen', true);
    setState(() {
      _showOnboardingCard = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Onboarding Info Card (if first time)
        if (_showOnboardingCard) _buildOnboardingCard(),

        const SizedBox(height: AppConstants.mediumSpacing),

        // Breathing Start Button
        _buildBreathingStartButton(),
      ],
    );
  }

  /// Build the onboarding info card with fade-in from blur animation.
  Widget _buildOnboardingCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, opacity, child) {
        return Transform.scale(
          scale: 0.9 + (opacity * 0.1), // Scale from 0.9 to 1.0
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: AppCard(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        borderRadius: AppConstants.defaultBorderRadius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Mücadelelere Hoşgeldin',
                    style: AppTextStyles.heading3,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: _dismissOnboardingCard,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallSpacing),
            Text(
              'Burası günlük su hedefini her gün senin için daha eğlenceli hale getiren yol haritan. Hadi birlikte zorlu görevlerin üstesinden gelelim ve hem kendimizi hem balıklarımızı suya doyuralım.',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  /// Build the breathing start button with gradient and animation.
  Widget _buildBreathingStartButton() {
    return AnimatedBuilder(
      animation: _breathingAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isActive ? _breathingAnimation.value : 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF6B35)
                            .withValues(alpha: 0.3 * _breathingAnimation.value),
                        blurRadius: 20 * _breathingAnimation.value,
                        spreadRadius: 2 * _breathingAnimation.value,
                      ),
                    ]
                  : [],
            ),
            child: ElevatedButton(
              onPressed: widget.isActive ? widget.onStartPressed : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.largePadding * 2,
                  vertical: AppConstants.defaultPadding,
                ),
                backgroundColor: widget.isActive
                    ? null // Use gradient
                    : Colors.grey[300],
                foregroundColor: widget.isActive ? Colors.white : Colors.grey[600],
                disabledForegroundColor: Colors.grey[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
                ),
                elevation: 0,
              ).copyWith(
                // Apply gradient for active state
                backgroundColor: widget.isActive
                    ? WidgetStateProperty.all<Color>(Colors.transparent)
                    : null,
              ),
              child: Container(
                decoration: widget.isActive
                    ? BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFF6B35), // Vibrant orange
                            Color(0xFFFF8C42), // Lighter orange
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
                      )
                    : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.largePadding * 2,
                  vertical: AppConstants.defaultPadding,
                ),
                child: Text(
                  'Başla',
                  style: AppTextStyles.buttonText.copyWith(
                    fontSize: AppConstants.largeFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

