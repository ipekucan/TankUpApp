import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import 'onboarding_screen.dart';
import 'main_navigation_screen.dart';

class UnitSelectionScreen extends StatefulWidget {
  const UnitSelectionScreen({super.key});

  @override
  State<UnitSelectionScreen> createState() => _UnitSelectionScreenState();
}

class _UnitSelectionScreenState extends State<UnitSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
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
    
    // Fade-in animasyonu
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );
    
    // Animasyonları başlat
    _fadeController.forward();
    _waveController.repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _selectUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_unit', unit); // 'ml' veya 'oz'
    
    if (!mounted) return;
    
    // Onboarding kontrolü
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    
    if (!onboardingCompleted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.verySoftBlue,
      body: SafeArea(
        child: Stack(
          children: [
            // Dalga animasyonu (arka plan)
            AnimatedBuilder(
              animation: _waveAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(
                    MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height,
                  ),
                  painter: WavePainter(
                    waveHeight: 30.0,
                    waveOffset: _waveAnimation.value,
                  ),
                );
              },
            ),
            
            // İçerik
            FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Tercih Ettiğiniz Birimi Seçin',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A5568),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 60),
                      
                      // ml Butonu - Uzun ince dikdörtgen
                      _buildUnitButton(
                        label: 'ml',
                        subtitle: 'Mililitre',
                        onTap: () => _selectUnit('ml'),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // oz Butonu - Uzun ince dikdörtgen
                      _buildUnitButton(
                        label: 'oz',
                        subtitle: 'Ons',
                        onTap: () => _selectUnit('oz'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitButton({
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40), // Oval köşeler
          boxShadow: [
            BoxShadow(
              color: AppColors.softPinkButton.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.softPinkButton,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF4A5568).withValues(alpha: 0.7),
              ),
            ),
          ],
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
      ..color = AppColors.waterColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.7 +
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

