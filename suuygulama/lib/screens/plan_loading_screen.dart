import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../providers/user_provider.dart';
import '../providers/water_provider.dart';
import '../services/notification_service.dart';
import 'main_navigation_screen.dart';

class PlanLoadingScreen extends StatefulWidget {
  final double? customGoal;

  const PlanLoadingScreen({
    super.key,
    this.customGoal,
  });

  @override
  State<PlanLoadingScreen> createState() => _PlanLoadingScreenState();
}

class _PlanLoadingScreenState extends State<PlanLoadingScreen> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _fillController;
  late Animation<double> _fillAnimation;
  double _fillProgress = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Dalga animasyonu
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    // Dolum animasyonu
    _fillController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fillAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fillController,
        curve: Curves.easeInOut,
      ),
    )..addListener(() {
      setState(() {
        _fillProgress = _fillAnimation.value;
      });
    });
    
    // Dolum animasyonunu başlat
    _fillController.forward();
    
    _calculateAndSavePlan();
  }
  
  @override
  void dispose() {
    _waveController.dispose();
    _fillController.dispose();
    super.dispose();
  }

  Future<void> _calculateAndSavePlan() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final waterProvider = Provider.of<WaterProvider>(context, listen: false);
    
    // Kısa bir gecikme (animasyon için)
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Bilimsel hesaplama: VKE ve su hedefi
    // VKE = Kilo / (Boy/100)² (UserProvider'da zaten var)
    // Su hedefi = Kilo × 35ml + Aktivite bonusu (UserProvider'da zaten var)
    // Eğer özel hedef varsa onu kullan, yoksa hesaplanan hedefi kullan
    final idealGoal = widget.customGoal ?? userProvider.calculateIdealWaterGoal();
    
    // Su hedefini ayarla
    await waterProvider.updateDailyGoal(idealGoal);
    
    // Coin'i sıfırla
    await waterProvider.resetCoins();
    
    // Onboarding tamamlandı flag'ini kaydet
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
    
    if (!mounted) return;
    
    // Bildirimleri varsayılan saatlerle ayarla
    final notificationService = NotificationService();
    notificationService.scheduleDailyNotifications().catchError((e) {
      // Hata durumunda sessizce devam et
    });
    
    if (!mounted) return;
    
    // Ana sayfaya yönlendir
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.verySoftBlue,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Tank Animasyonu
              Container(
                width: 250,
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Dış Çerçeve - Yuvarlak Fanus
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.softPinkButton,
                          width: 6,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.softPinkButton.withValues(alpha: 0.1),
                            const Color(0xFF9B7EDE).withValues(alpha: 0.1),
                            const Color(0xFF6B9BD1).withValues(alpha: 0.1),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.softPinkButton.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    
                    // Su Dolumu - Animasyonlu
                    ClipOval(
                      child: AnimatedBuilder(
                        animation: _fillAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(250, 250),
                            painter: CircularTankWavePainter(
                              fillPercentage: _fillProgress,
                              waveOffset: _waveController.value * 2 * math.pi,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              const Text(
                'Sizin için kişisel planınız oluşturuluyor...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF4A5568),
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tank dalga animasyonu için CustomPainter
class CircularTankWavePainter extends CustomPainter {
  final double fillPercentage;
  final double waveOffset;

  CircularTankWavePainter({
    required this.fillPercentage,
    required this.waveOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPercentage <= 0) return;
    
    // Su seviyesi hesaplama (alt kısımdan yukarı doğru)
    final waterHeight = size.height * fillPercentage;
    final waterTop = size.height - waterHeight;
    
    // Su rengi
    final waterPaint = Paint()
      ..color = AppColors.waterColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    
    // Yuvarlak tank için su dolumu
    final centerX = size.width / 2;
    final radius = size.width / 2 - 6; // Border için boşluk
    
    // Su dolu alanı çiz (yuvarlak formda)
    final path = Path();
    
    // Alt kısımdan başla
    path.moveTo(0, size.height);
    
    // Su seviyesine kadar düz çizgi
    if (waterTop < size.height) {
      path.lineTo(0, waterTop);
      
      // Dalga çizgisi (yuvarlak form için)
      for (double x = 0; x <= size.width; x += 1.5) {
        final normalizedX = (x - centerX) / radius;
        if (normalizedX.abs() <= 1.0) {
          final y = waterTop + 
              5 * math.sin((x / size.width * 2 * math.pi) + waveOffset);
          path.lineTo(x, y);
        }
      }
      
      path.lineTo(size.width, size.height);
      path.close();
      
      canvas.drawPath(path, waterPaint);
    }
  }

  @override
  bool shouldRepaint(CircularTankWavePainter oldDelegate) {
    return oldDelegate.fillPercentage != fillPercentage ||
        oldDelegate.waveOffset != waveOffset;
  }
}

