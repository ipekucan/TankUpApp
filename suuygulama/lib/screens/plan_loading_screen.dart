import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';
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
  late AnimationController _bubbleController;
  late Animation<double> _fillAnimation;
  double _fillProgress = 0.0;
  final List<Bubble> _bubbles = [];

  @override
  void initState() {
    super.initState();
    
    // Dalga animasyonu
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    // Dolum animasyonu (3.5 saniye - makul süre)
    _fillController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );
    
    _fillAnimation = Tween<double>(begin: 0.0, end: 1.0).animate( // %100 tam doluluk
      CurvedAnimation(
        parent: _fillController,
        curve: Curves.easeInOut,
      ),
    )..addListener(() {
      setState(() {
        _fillProgress = _fillAnimation.value;
      });
    });
    
    // Animasyon bitiş kontrolü - otomatik yönlendirme
    _fillController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        // Animasyon tamamlandığında planı kaydet ve yönlendir
        _navigateToHome();
      }
    });
    
    // Kabarcık animasyonu
    _bubbleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    // Kabarcıkları oluştur
    _generateBubbles();
    
    // Dolum animasyonunu başlat
    _fillController.forward();
    
    // Zaman aşımı (Timeout) - 5 saniye sonra her halükarda yönlendir
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _navigateToHome();
      }
    });
  }
  
  void _navigateToHome() {
    if (!mounted) return;
    
    // Önce planı kaydet
    _calculateAndSavePlan();
  }
  
  void _generateBubbles() {
    _bubbles.clear();
    final random = math.Random();
    for (int i = 0; i < 8; i++) {
      _bubbles.add(Bubble(
        startX: random.nextDouble() * 0.8 + 0.1, // 0.1 - 0.9 arası
        size: random.nextDouble() * 8 + 4, // 4-12 arası boyut
        speed: random.nextDouble() * 0.3 + 0.1, // 0.1 - 0.4 arası hız
        delay: random.nextDouble() * 2, // 0-2 saniye gecikme
      ));
    }
  }
  
  @override
  void dispose() {
    _waveController.dispose();
    _fillController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  Future<void> _calculateAndSavePlan() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final waterProvider = Provider.of<WaterProvider>(context, listen: false);
    
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
    
    // Güvenli navigasyon - context hatası önleme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // Ana sayfaya yönlendir (geri tuşuyla dönüşü engelle)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    });
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
              SizedBox(
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
                        animation: Listenable.merge([_fillAnimation, _bubbleController]),
                        builder: (context, child) {
                          // Tankın iç çapı: 250 - (6 * 2) = 238
                          final innerDiameter = 238.0;
                          final waterHeight = innerDiameter * _fillProgress; // Su yüksekliği
                          final waterTop = innerDiameter - waterHeight; // Su seviyesinin üst noktası
                          
                          return SizedBox(
                            width: innerDiameter, // Tank çapıyla eşit
                            height: innerDiameter, // Tank çapıyla eşit
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                // Ana su katmanı (dibinden başlayarak)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  height: waterHeight,
                                  child: Container(
                                    color: AppColors.waterColor.withValues(alpha: 0.8),
                                  ),
                                ),
                                
                                // Wave efekti (sadece su seviyesinin üstünde görünür)
                                if (_fillProgress > 0.1)
                                  Positioned(
                                    bottom: waterHeight - 20, // Wave'in su seviyesinin biraz altında başlaması
                                    left: 0,
                                    right: 0,
                                    height: 40,
                                    child: ClipRect(
                                      child: ClipOval(
                                        child: WaveWidget(
                                          config: CustomConfig(
                                            gradients: [
                                              [
                                                AppColors.waterColor.withValues(alpha: 0.3),
                                                AppColors.waterColor.withValues(alpha: 0.5),
                                              ],
                                              [
                                                AppColors.waterColor.withValues(alpha: 0.4),
                                                AppColors.waterColor.withValues(alpha: 0.6),
                                              ],
                                            ],
                                            durations: [4000, 5000],
                                            heightPercentages: [0.20, 0.25],
                                          ),
                                          waveAmplitude: 5.0,
                                          waveFrequency: 1.5,
                                          backgroundColor: Colors.transparent,
                                          size: Size(innerDiameter, 40),
                                        ),
                                      ),
                                    ),
                                  ),
                                
                                // Yükselen kabarcıklar
                                ..._bubbles.map((bubble) {
                                  final bubbleProgress = ((_bubbleController.value * 2 + bubble.delay) % 2) / 2;
                                  final bubbleY = innerDiameter - (bubbleProgress * waterHeight * 0.8);
                                  final bubbleX = bubble.startX * innerDiameter;
                                  
                                  // Sadece su içindeyse göster
                                  if (bubbleY > waterTop && bubbleY < innerDiameter) {
                                    return Positioned(
                                      left: bubbleX - bubble.size / 2,
                                      bottom: innerDiameter - bubbleY - bubble.size / 2,
                                      child: Opacity(
                                        opacity: math.max(0, 1 - bubbleProgress * 1.5),
                                        child: Container(
                                          width: bubble.size,
                                          height: bubble.size,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withValues(alpha: 0.3),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.5),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }),
                              ],
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

// Kabarcık veri modeli
class Bubble {
  final double startX; // 0.0 - 1.0 arası (tank genişliğine göre)
  final double size; // Kabarcık boyutu
  final double speed; // Yükselme hızı
  final double delay; // Başlangıç gecikmesi

  Bubble({
    required this.startX,
    required this.size,
    required this.speed,
    required this.delay,
  });
}

