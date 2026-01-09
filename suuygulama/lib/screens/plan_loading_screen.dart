import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import '../providers/daily_hydration_provider.dart';
import '../services/notification_service.dart';
import 'main_navigation_screen.dart';
import '../core/services/logger_service.dart';

/// Plan loading screen with liquid vortex animation
class PlanLoadingScreen extends StatefulWidget {
  final double? customGoal;

  const PlanLoadingScreen({
    super.key,
    this.customGoal,
  });

  @override
  State<PlanLoadingScreen> createState() => _PlanLoadingScreenState();
}

class _PlanLoadingScreenState extends State<PlanLoadingScreen> {
  @override
  void initState() {
    super.initState();
    _calculateAndSavePlan();
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
    return const Scaffold(
      backgroundColor: Color(0xFFF7F7F7), // Clean off-white
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Liquid vortex animation
              _LiquidVortexWidget(),
              
              SizedBox(height: 48),
              
              // Pulsing status text
              _PulsingStatusText(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Liquid vortex animation widget with rotating layers
class _LiquidVortexWidget extends StatefulWidget {
  const _LiquidVortexWidget();

  @override
  State<_LiquidVortexWidget> createState() => _LiquidVortexWidgetState();
}

class _LiquidVortexWidgetState extends State<_LiquidVortexWidget>
    with TickerProviderStateMixin {
  // Color palette
  static const Color _primaryLiquid = Color(0xFF85B7D2);
  static const Color _secondaryLiquid = Color(0xFFD2ECF9);
  
  late AnimationController _layer1Controller;
  late AnimationController _layer2Controller;
  late AnimationController _layer3Controller;
  
  @override
  void initState() {
    super.initState();
    
    // Layer 1: Slow clockwise rotation
    _layer1Controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    // Layer 2: Medium counter-clockwise rotation
    _layer2Controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    // Layer 3: Fast clockwise rotation
    _layer3Controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _layer1Controller.dispose();
    _layer2Controller.dispose();
    _layer3Controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Layer 3: Innermost circle (fastest)
          _buildRotatingLayer(
            controller: _layer3Controller,
            size: 60,
            color: _primaryLiquid.withValues(alpha: 0.4),
            offset: const Offset(-10, 10),
          ),
          
          // Layer 2: Middle circle (medium speed)
          _buildRotatingLayer(
            controller: _layer2Controller,
            size: 90,
            color: _secondaryLiquid.withValues(alpha: 0.6),
            offset: const Offset(8, -8),
          ),
          
          // Layer 1: Outermost circle (slowest)
          _buildRotatingLayer(
            controller: _layer1Controller,
            size: 120,
            color: _primaryLiquid.withValues(alpha: 0.3),
            offset: const Offset(-5, 5),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRotatingLayer({
    required AnimationController controller,
    required double size,
    required Color color,
    required Offset offset,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: controller.value * 2 * 3.14159,
          child: Transform.translate(
            offset: offset,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Pulsing status text widget
class _PulsingStatusText extends StatefulWidget {
  const _PulsingStatusText();

  @override
  State<_PulsingStatusText> createState() => _PulsingStatusTextState();
}

class _PulsingStatusTextState extends State<_PulsingStatusText>
    with SingleTickerProviderStateMixin {
  static const Color _textColor = Color(0xFF85B7D2);
  
  late AnimationController _pulseController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _opacityAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: const Text(
              'Plan Hesaplanıyor...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textColor,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
