import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../providers/user_provider.dart';
import 'unit_selection_screen.dart';
import 'onboarding_screen.dart';
import 'main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _waveController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    
    // Fade-in animasyonu
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );
    
    // Dalga animasyonu (sürekli döngü)
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _waveAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _waveController,
        curve: Curves.linear,
      ),
    );
    
    // Fade-in animasyonunu başlat
    _fadeController.forward();
    
    // Dalga animasyonunu sürekli döngüde çalıştır
    _waveController.repeat();
    
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    // 3 saniye bekle
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      
      final preferredUnit = prefs.getString('preferred_unit');
      
      // Eğer birim seçilmemişse unit selection ekranına yönlendir
      if (preferredUnit == null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const UnitSelectionScreen()),
        );
        return;
      }
      
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      
      // Eğer onboarding tamamlanmamışsa veya weight verisi yoksa onboarding göster
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
    } catch (e) {
      // Hata durumunda unit selection göster
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const UnitSelectionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.verySoftBlue,
      body: SafeArea(
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Dalga animasyonu (arka plan)
              AnimatedBuilder(
                animation: _waveAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(
                      MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height * 0.3,
                    ),
                    painter: WavePainter(
                      waveHeight: 20.0,
                      waveOffset: _waveAnimation.value * 2 * 3.14159,
                    ),
                  );
                },
              ),
              
              // Logo ve başlık (fade-in)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo ikonu (su damlası)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.softPinkButton.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.water_drop,
                        size: 70,
                        color: AppColors.softPinkButton,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Uygulama adı
                    Text(
                      'TankUp',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: AppColors.softPinkButton,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hidrasyon Asistanınız',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFF4A5568).withValues(alpha: 0.7),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dalga çizimi için CustomPainter
class WavePainter extends CustomPainter {
  final double waveHeight;
  final double waveOffset;

  WavePainter({
    required this.waveHeight,
    required this.waveOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.waterColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height / 2 +
          waveHeight * 
          math.sin((x / size.width * 2 * math.pi) + waveOffset);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.waveOffset != waveOffset;
  }
}

