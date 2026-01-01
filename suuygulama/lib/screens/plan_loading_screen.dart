import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import '../providers/water_provider.dart';
import '../services/notification_service.dart';
import 'main_navigation_screen.dart';

// Baloncuk Modeli
class Bubble {
  double x; // Yatay pozisyon (0.0 - 1.0)
  double y; // Dikey pozisyon (0.0 = alt, 1.0 = üst)
  double size; // Baloncuk boyutu (piksel)
  double speed; // Yükselme hızı (0.0 - 1.0 arası)
  double opacity; // Opaklık (0.0 - 1.0)

  Bubble({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });

  // Baloncuğu yukarı hareket ettir
  void update(double deltaTime) {
    y -= speed * deltaTime;
    // Ekranın üstünden çıkınca alttan tekrar başla
    if (y < -0.1) {
      y = 1.1; // Ekranın altından başla
      x = math.Random().nextDouble(); // Yeni rastgele x pozisyonu
    }
  }
}

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
  late AnimationController _bubbleController; // Baloncuk animasyonu
  final List<Bubble> _bubbles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    
    // Baloncuk animasyonu (60 FPS - smooth animasyon)
    _bubbleController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    
    // Baloncukları oluştur (20-30 arası)
    _initializeBubbles();
    
    // Planı hesapla ve kaydet, sonra yönlendir
    _calculateAndSavePlan();
  }
  
  void _initializeBubbles() {
    _bubbles.clear();
    final bubbleCount = 20 + _random.nextInt(11); // 20-30 arası
    
    for (int i = 0; i < bubbleCount; i++) {
      _bubbles.add(Bubble(
        x: _random.nextDouble(), // Rastgele yatay pozisyon
        y: 0.8 + _random.nextDouble() * 0.3, // Ekranın alt kısmından başla (0.8-1.1)
        size: 8.0 + _random.nextDouble() * 20.0, // 8-28 piksel arası
        speed: 0.3 + _random.nextDouble() * 0.4, // 0.3-0.7 arası hız
        opacity: 0.2 + _random.nextDouble() * 0.2, // 0.2-0.4 arası opaklık
      ));
    }
  }
  
  @override
  void dispose() {
    _bubbleController.dispose();
    super.dispose();
  }

  Future<void> _calculateAndSavePlan() async {
    try {
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
      
      if (!mounted) return;
      
      // Coin'i sıfırla
      await waterProvider.resetCoins();
      
      if (!mounted) return;
      
      // Onboarding tamamlandı flag'ini kaydet
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_completed', true);
      } catch (e) {
        // Hata durumunda sessizce devam et
      }
      
      if (!mounted) return;
      
      // Bildirimleri varsayılan saatlerle ayarla (await etmeden devam et)
      final notificationService = NotificationService();
      notificationService.scheduleDailyNotifications().catchError((e) {
        // Hata durumunda sessizce devam et
      });
      
      // Kısa bir gecikme ekle (kullanıcıya loading animasyonunu göstermek için)
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      // Güvenli navigasyon - context hatası önleme
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      // Hata durumunda yine de navigasyon yap
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Sabit Su Altı Mavisi Gradyanı
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4FC3F7), // Üst: Aydınlık mavi
              Color(0xFF0288D1), // Alt: Derin mavi
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Yükselen Baloncuklar (Arka Plan)
              AnimatedBuilder(
                animation: _bubbleController,
                builder: (context, child) {
                  // Her frame'de baloncukları güncelle
                  // AnimationController 1 saniyede 1 tur döner, bu yüzden deltaTime = 1/60 ≈ 0.0167
                  final deltaTime = 0.0167; // ~60 FPS
                  for (var bubble in _bubbles) {
                    bubble.update(deltaTime);
                  }
                  
                  return CustomPaint(
                    size: screenSize,
                    painter: _BubblePainter(_bubbles, screenSize),
                  );
                },
              ),
              
              // Merkez İçerik (Ön Plan)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Su Damlası İkonu
                    const Icon(
                      Icons.water_drop,
                      size: 60,
                      color: Colors.white,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Metin
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Sizin için kişisel planınız oluşturuluyor...',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
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

// Baloncuk Çizim Painter'ı
class _BubblePainter extends CustomPainter {
  final List<Bubble> bubbles;
  final Size screenSize;

  _BubblePainter(this.bubbles, this.screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    for (var bubble in bubbles) {
      // Y pozisyonunu ekran koordinatlarına çevir (0.0 = alt, 1.0 = üst)
      final y = screenSize.height * (1.0 - bubble.y); // Ters çevir (yukarı pozitif)
      final x = screenSize.width * bubble.x;
      
      // Baloncuğu çiz
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: bubble.opacity)
        ..style = PaintingStyle.fill;
      
      // Ana baloncuk (daire)
      canvas.drawCircle(
        Offset(x, y),
        bubble.size / 2,
        paint,
      );
      
      // Hafif parlaklık efekti (kenar)
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: bubble.opacity * 1.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      canvas.drawCircle(
        Offset(x, y),
        bubble.size / 2,
        borderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) {
    return true; // Her frame'de yeniden çiz
  }
}


