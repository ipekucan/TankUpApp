import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import '../core/services/logger_service.dart';
import 'onboarding_screen.dart';
import 'main_navigation_screen.dart';

/// Splash screen with sophisticated breathing welcome animation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;
  
  @override
  void initState() {
    super.initState();
    _startNavigationTimer();
  }
  
  void _startNavigationTimer() {
    // Wait 3 seconds for animation to complete
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_hasNavigated) {
        _navigateToNextScreen();
      }
    });
  }

  Future<void> _navigateToNextScreen() async {
    if (_hasNavigated || !mounted) return;
    
    _hasNavigated = true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      
      // Check if onboarding is needed
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final hasWeight = userProvider.userData.weight != null;
      
      if (!mounted) return;
      
      if (!onboardingCompleted || !hasWeight) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      } else {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    } catch (e, stackTrace) {
      LoggerService.logError('Failed to check onboarding status', e, stackTrace);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7F7F7), // Clean off-white
      body: SafeArea(
        child: _SplashBackground(),
      ),
    );
  }
}

/// Background layout wrapper for splash screen
class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: _BreathingLogo(),
    );
  }
}

/// Breathing logo widget with sophisticated entrance and breathing animations
class _BreathingLogo extends StatefulWidget {
  const _BreathingLogo();

  @override
  State<_BreathingLogo> createState() => _BreathingLogoState();
}

class _BreathingLogoState extends State<_BreathingLogo>
    with SingleTickerProviderStateMixin {
  // Theme color
  static const Color _themeColor = Color(0xFF85B7D2);
  
  late AnimationController _controller;
  late Animation<double> _entranceOpacity;
  late Animation<double> _entranceScale;
  late Animation<double> _breathingScale;
  
  bool _entranceComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    // Single controller for both phases
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800), // Phase 1 duration
      vsync: this,
    );
    
    // Phase 1: Entrance animation (0.0 - 1.0)
    _entranceOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut, // Safe curve for opacity (no overshoot)
      ),
    );
    
    _entranceScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack, // Pop effect (safe for scale)
      ),
    );
    
    // Phase 2: Breathing animation (1.0 - 1.05)
    _breathingScale = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    // Add status listener for phase transition
    _controller.addStatusListener(_onAnimationStatus);
    
    // Start entrance animation immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward();
      }
    });
  }
  
  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_entranceComplete) {
      if (!mounted) return;
      
      // Entrance complete, start breathing loop
      setState(() {
        _entranceComplete = true;
      });
      
      // Reset controller for breathing phase
      _controller.duration = const Duration(milliseconds: 1500);
      _controller.repeat(reverse: true); // Infinite breathing loop
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Clamp opacity to valid range [0.0, 1.0]
        final opacity = (_entranceComplete ? 1.0 : _entranceOpacity.value).clamp(0.0, 1.0);
        final scale = _entranceComplete ? _breathingScale.value : _entranceScale.value;
        
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo icon (water drop in circle)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _themeColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.water_drop,
                    size: 70,
                    color: _themeColor,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // App name
                const Text(
                  'TankUp',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: _themeColor,
                    letterSpacing: 1.5,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  'Hidrasyon Asistanınız',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _themeColor.withValues(alpha: 0.6),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}