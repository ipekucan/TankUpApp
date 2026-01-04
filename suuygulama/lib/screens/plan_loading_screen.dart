import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import '../providers/daily_hydration_provider.dart';
import '../services/notification_service.dart';
import '../utils/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'main_navigation_screen.dart';
import '../core/services/logger_service.dart';

class PlanLoadingScreen extends StatefulWidget {
  final double? customGoal;

  const PlanLoadingScreen({
    super.key,
    this.customGoal,
  });

  @override
  State<PlanLoadingScreen> createState() => _PlanLoadingScreenState();
}

class _PlanLoadingScreenState extends State<PlanLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Fade animation for text
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _calculateAndSavePlan();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _calculateAndSavePlan() async {
    try {
      final userProvider = context.read<UserProvider>();
      final dailyHydrationProvider = context.read<DailyHydrationProvider>();

      if (!mounted) return;

      final idealGoal = widget.customGoal ?? userProvider.calculateIdealWaterGoal();
      await dailyHydrationProvider.updateDailyGoal(idealGoal);

      if (!mounted) return;
      await dailyHydrationProvider.resetCoins();

      if (!mounted) return;

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_completed', true);
      } catch (e, stackTrace) {
        LoggerService.logError('Failed to save onboarding status', e, stackTrace);
      }

      if (!mounted) return;

      final notificationService = NotificationService();
      notificationService.scheduleDailyNotifications().catchError((e) {});

      await Future.delayed(const Duration(milliseconds: 2500));

      if (!mounted) return;

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    } catch (e, stackTrace) {
      LoggerService.logError('Failed to initialize hydration plan', e, stackTrace);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE1F5FE), // Soft light blue
              Color(0xFFF3E5F5), // Soft purple/lilac
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Loading text
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'Sizin için kişisel planınız oluşturuluyor...',
                      style: AppTextStyles.heading2.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary.withValues(alpha: 0.85),
                        letterSpacing: 0.3,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Loading indicator
                _buildLoadingIndicator(),

                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 2500),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return LinearProgressIndicator(
              value: value,
              backgroundColor: AppColors.cardBorder.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFFE1BEE7), // Soft purple
              ),
              minHeight: 6,
            );
          },
        ),
      ),
    );
  }
}
