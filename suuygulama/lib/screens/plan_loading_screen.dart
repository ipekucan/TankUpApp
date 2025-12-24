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
                    
                    // Su Dolumu - Animasyonlu (ClipOval ile tankın dairesel sınırlarına uyumlu)
                    ClipOval(
                      clipBehavior: Clip.antiAlias, // Pürüzsüz kenarlar için
                      child: AnimatedBuilder(
                        animation: _fillAnimation,
                        builder: (context, child) {
                          // Tankın iç çapı: 250 - (6 * 2) = 238
                          final innerDiameter = 238.0;
                          return SizedBox(
                            width: innerDiameter,
                            height: innerDiameter,
                            child: CustomPaint(
                              size: Size(innerDiameter, innerDiameter),
                              painter: CircularTankWavePainter(
                                fillPercentage: _fillProgress,
                                waveOffset: _waveController.value * 2 * math.pi,
                                tankDiameter: innerDiameter,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32), // Dengeli mesafe
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: const Text(
                  'Sizin için kişisel planınız oluşturuluyor...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF4A5568),
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
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
  final double tankDiameter;

  CircularTankWavePainter({
    required this.fillPercentage,
    required this.waveOffset,
    required this.tankDiameter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPercentage <= 0) return;
    
    // Tankın merkezi ve yarıçapı (tam iç çap)
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = tankDiameter / 2;
    
    // Su seviyesi hesaplama (alt kısımdan yukarı doğru)
    // fillPercentage 0.0-1.0 arası, 1.0 = tam dolu
    final waterHeight = size.height * fillPercentage;
    final waterTop = size.height - waterHeight;
    
    // Su rengi
    final waterPaint = Paint()
      ..color = AppColors.waterColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    
    // Su dolu alanı çiz (dairesel formda, tankın taban merkezinden başlayarak)
    final path = Path();
    
    // Su seviyesine kadar dairesel formda çiz
    if (waterTop < size.height) {
      // Alt yarıyı çiz (su seviyesinin altındaki kısım - tam dairesel)
      // π'den 2π'ye kadar (alt yarı)
      bool isFirstPoint = true;
      for (double angle = math.pi; angle <= 2 * math.pi; angle += 0.01) {
        final x = centerX + radius * math.cos(angle);
        final y = centerY + radius * math.sin(angle);
        if (isFirstPoint) {
          path.moveTo(x, y); // Başlangıç noktası (tankın sol alt noktası)
          isFirstPoint = false;
        } else {
          path.lineTo(x, y);
        }
      }
      
      // Üst yarıyı çiz (su seviyesine göre ayarlanmış, dalga efekti ile)
      // 0'dan π'ye kadar (üst yarı)
      for (double angle = 0; angle <= math.pi; angle += 0.01) {
        final x = centerX + radius * math.cos(angle);
        final y = centerY + radius * math.sin(angle);
        
        // Eğer bu nokta su seviyesinin altındaysa, su seviyesine göre ayarla
        if (y >= waterTop) {
          // Dalga efekti ekle (sadece üst kısımda)
          final waveHeight = 5.0 * math.sin((angle * 2 * math.pi) + waveOffset);
          final adjustedY = math.max(waterTop + waveHeight, y);
          path.lineTo(x, adjustedY);
        } else {
          // Su seviyesinin üstündeki kısım - tankın kenarını takip et
          path.lineTo(x, y);
        }
      }
      
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

