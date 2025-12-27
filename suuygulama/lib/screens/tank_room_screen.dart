import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:async';
import '../utils/app_colors.dart';
import '../providers/water_provider.dart';
import '../providers/aquarium_provider.dart';
import '../models/decoration_item.dart';
import 'shop_screen.dart';

// Baloncuk Modeli
class BubbleModel {
  double x;
  double y;
  double size;
  double speed;
  double wobbleOffset;
  double wobbleSpeed;
  double id; // Baloncuk için benzersiz ID (wobble hesaplaması için)

  BubbleModel({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.wobbleOffset,
    required this.wobbleSpeed,
    required this.id,
  });
}

class TankRoomScreen extends StatefulWidget {
  const TankRoomScreen({super.key});

  @override
  State<TankRoomScreen> createState() => _TankRoomScreenState();
}

class _TankRoomScreenState extends State<TankRoomScreen>
    with TickerProviderStateMixin {
  Timer? _dirtyCheckTimer;
  Timer? _bubbleTimer;
  final List<BubbleModel> _bubbles = [];
  final math.Random _random = math.Random();
  double _animationTime = 0.0;
  late AnimationController _godRayAnimationController; // Işık hüzmeleri için AnimationController

  @override
  void initState() {
    super.initState();
    
    // Işık hüzmeleri AnimationController (10 saniye, repeat reverse)
    _godRayAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    
    // Her saniye tank kirliliğini kontrol et
    _dirtyCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {}); // Kirlilik durumunu güncelle
      }
    });

    // Baloncuk animasyon döngüsü (60fps = 16ms)
    _bubbleTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) return;

      _animationTime += 0.016; // Zaman ilerlemesi

      // Rastgele aralıklarla yeni baloncuk üret (alt kısımdan)
      if (_random.nextDouble() < 0.02) { // %2 şansla her frame'de
        final size = 6 + _random.nextDouble() * 20; // 6-26 arası boyut
        
        // Hız: Büyük baloncuklar daha hızlı, küçükler daha yavaş
        // Normalize edilmiş boyut (0.0-1.0) ile hız hesapla
        final normalizedSize = (size - 6) / 20; // 6-26 -> 0.0-1.0
        final baseSpeed = 0.0006; // Minimum hız
        final speedRange = 0.0014; // Hız aralığı
        final speed = baseSpeed + (normalizedSize * speedRange); // Büyükler daha hızlı
        
        _bubbles.add(BubbleModel(
          x: _random.nextDouble(),
          y: 1.0, // Alt kısımdan başla (normalized: 1.0 = alt, 0.0 = üst)
          size: size,
          speed: speed,
          wobbleOffset: _random.nextDouble() * 2 * math.pi, // Rastgele başlangıç fazı
          wobbleSpeed: 0.8 + _random.nextDouble() * 1.2, // 0.8-2.0 arası salınım hızı
          id: _random.nextDouble() * 1000, // Benzersiz ID
        ));
      }

      // Baloncukları hareket ettir (Gelişmiş fizik)
      _bubbles.removeWhere((bubble) {
        // Yukarı hareket (Suyun akışkanlığına uygun yavaş hız)
        bubble.y -= bubble.speed;
        
        // Sinüs fonksiyonu ile sağa-sola yalpalam (wobble)
        final wobblePhase = bubble.wobbleOffset + (_animationTime * bubble.wobbleSpeed);
        bubble.x += math.sin(wobblePhase + bubble.id) * 0.0015; // Gerçekçi yalpalam
        
        // Ekranın tepesinden çıkanları sil
        return bubble.y < -0.1;
      });

      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _dirtyCheckTimer?.cancel();
    _bubbleTimer?.cancel();
    _godRayAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer2<WaterProvider, AquariumProvider>(
        builder: (context, waterProvider, aquariumProvider, child) {
          final isDirty = waterProvider.isTankDirty;
          final screenSize = MediaQuery.of(context).size;
          
          // Tank boyutları ve pozisyonu
          final tankWidth = screenSize.width - 40.0; // Yatay padding: 20 * 2
          final tankHeight = screenSize.height - 100.0; // Dikey padding: 50 * 2
          
          return Stack(
            children: [
              // KATMAN 1: DERİN OKYANUS GRADYANI (Arka Plan)
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF006994), // Okyanus Mavisi (Üst)
                      Color(0xFF001E3C), // Derin Karanlık (Alt)
                    ],
                  ),
                ),
              ),

              // KATMAN 1.5: HAREKETLİ IŞIK HÜZMELERİ (God Rays) - AnimatedBuilder ile parıldama efekti
              AnimatedBuilder(
                animation: _godRayAnimationController,
                builder: (context, child) {
                  return Stack(
                    children: List.generate(4, (index) {
                      // Farklı açılar (-pi/12, -pi/10, pi/10, pi/12 gibi doğal açılar)
                      final angles = [-math.pi / 12, -math.pi / 10, math.pi / 10, math.pi / 12];
                      final angle = angles[index % angles.length];
                      
                      final screenWidth = screenSize.width;
                      final rayWidth = 280.0;
                      
                      // Ekranı 4'e böl ve dağıt
                      final offsetX = (screenWidth / 4) * index - (rayWidth / 2);
                      
                      // Her hüzme için farklı offset ile sinüs dalgası (doğal parıldama)
                      final offset = index * (math.pi / 2); // Farklı offset'ler (0, pi/2, pi, 3pi/2)
                      final opacityValue = 0.1 + 0.2 * math.sin(
                        _godRayAnimationController.value * 2 * math.pi + offset
                      );
                      
                      return Positioned(
                        top: -100, // Ekranın tepesinden başla
                        left: offsetX,
                        width: rayWidth,
                        height: screenSize.height + 200, // Ekranın dışına taşan uzun hüzme
                        child: Transform.rotate(
                          angle: angle,
                          child: Opacity(
                            opacity: opacityValue.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: const [0.0, 0.3, 0.7, 1.0],
                                  colors: [
                                    Colors.white.withValues(alpha: 0.8), // Üst: Parlak
                                    Colors.white.withValues(alpha: 0.4), // Orta üst: Orta parlaklık
                                    Colors.white.withValues(alpha: 0.1), // Orta alt: Soluk
                                    Colors.white.withValues(alpha: 0.0), // Alt: Tam şeffaf
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),

              // KATMAN 3: MEVCUT BALIKLAR VE İÇERİK (Tank Container)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
                  child: Container(
                    width: tankWidth,
                    height: tankHeight,
                    clipBehavior: Clip.antiAlias, // KRİTİK: İçeriği tank sınırları içinde tutar
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // KATMAN 2: Baloncuklar
                        ..._bubbles.map((bubble) {
                          // Baloncuk pozisyonlarını tank sınırlarına göre hesapla
                          final tankX = bubble.x * tankWidth;
                          final tankY = (1.0 - bubble.y) * tankHeight; // Y eksenini ters çevir
                          
                          // Sadece tank sınırları içindeki baloncukları göster
                          if (tankX < -bubble.size / 2 || tankX > tankWidth + bubble.size / 2 ||
                              tankY < -bubble.size / 2 || tankY > tankHeight + bubble.size / 2) {
                            return const SizedBox.shrink();
                          }
                          
                          return Positioned(
                            left: tankX - bubble.size / 2,
                            top: tankY - bubble.size / 2,
                            child: Container(
                              width: bubble.size,
                              height: bubble.size,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                // 3D Baloncuk efekti: RadialGradient (gerçekçi içi boş görünüm)
                                gradient: RadialGradient(
                                  center: Alignment.topLeft,
                                  radius: 1.0,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.1), // Merkez: Neredeyse şeffaf
                                    Colors.white.withValues(alpha: 0.6), // Kenarlar: Parlak beyaz kenarlık
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          );
                        }),
                        
                        // Yosunlanma efekti - Yeşil %30 opaklıkta overlay
                        Visibility(
                          visible: isDirty,
                          child: Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Stack(
                                children: [
                                  // Yosun çizimleri
                                  CustomPaint(
                                    painter: _AlgaePainter(),
                                    size: Size(tankWidth, tankHeight),
                                  ),
                                  // Köşelerde yosun ikonları
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    child: Icon(
                                      Icons.eco,
                                      color: Colors.green.withValues(alpha: 0.6),
                                      size: 20,
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Icon(
                                      Icons.eco,
                                      color: Colors.green.withValues(alpha: 0.6),
                                      size: 20,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    left: 10,
                                    child: Icon(
                                      Icons.eco,
                                      color: Colors.green.withValues(alpha: 0.6),
                                      size: 20,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: Icon(
                                      Icons.eco,
                                      color: Colors.green.withValues(alpha: 0.6),
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Su seviyesi (her zaman %100)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: tankHeight,
                            decoration: BoxDecoration(
                              color: isDirty
                                  ? AppColors.waterColor.withValues(alpha: 0.4)
                                  : AppColors.waterColor.withValues(alpha: 0.5),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.waterColor.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Modüler dekorasyonlar - Katmanlı yapı (layerOrder'a göre sıralı)
                        ...aquariumProvider.activeDecorationsList.map((decoration) {
                          return _buildDecoration(
                            decoration,
                            tankWidth,
                            tankHeight,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Mağaza butonu - Sağ alt köşe
              Positioned(
                bottom: 30,
                right: 30,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ShopScreen(),
                      ),
                    );
                  },
                  backgroundColor: AppColors.softPinkButton,
                  elevation: 8,
                  child: const Icon(
                    Icons.shopping_bag,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),


              // KATMAN 5: SU ALTI FİLTRESİ (Overlay)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Dekorasyon çizimi
  Widget _buildDecoration(DecorationItem decoration, double tankWidth, double tankHeight) {
    final x = decoration.left * tankWidth;
    final y = (1.0 - decoration.bottom) * tankHeight; // bottom 0.0 = alt, 1.0 = üst

    // Kategoriye göre dekorasyon widget'ı
    Widget decorationWidget = _buildDecorationByCategory(decoration);

    return Positioned(
      left: x - 30, // Merkezleme için
      top: y - 30,
      child: decorationWidget,
    );
  }

  // Kategoriye göre dekorasyon widget'ı
  Widget _buildDecorationByCategory(DecorationItem decoration) {
    switch (decoration.category) {
      case 'Zemin/Kum':
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFD4A574).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFFD4A574).withValues(alpha: 0.9),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.landscape,
            color: Color(0xFF8B6F47),
            size: 32,
          ),
        );
      case 'Arka Plan':
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF6B9BD1).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: const Color(0xFF6B9BD1).withValues(alpha: 0.8),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.water,
            color: Color(0xFF4A7BA7),
            size: 40,
          ),
        );
      case 'Süs':
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B9D).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: const Color(0xFFFF6B9D).withValues(alpha: 0.9),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.star,
            color: Color(0xFFFF8FAB),
            size: 28,
          ),
        );
      default:
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.softPink.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: AppColors.softPink,
            size: 28,
          ),
        );
    }
  }
}

// Yosun çizim painter'ı
class _AlgaePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final random = math.Random(42);
    
    // Rastgele yosun çizgileri ve lekeler
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      
      // Yosun çizgileri
      final length = 15 + random.nextDouble() * 40;
      canvas.drawLine(
        Offset(x, y),
        Offset(x, y + length),
        paint..strokeWidth = 2 + random.nextDouble() * 4,
      );
      
      // Yosun lekeleri (küçük daireler)
      if (i % 3 == 0) {
        final radius = 3 + random.nextDouble() * 8;
        canvas.drawCircle(
          Offset(x, y),
          radius,
          paint..color = Colors.green.withValues(alpha: 0.5),
        );
      }
    }
    
    // Köşelerde daha yoğun yosun
    final cornerPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    
    // Sol üst köşe
    canvas.drawCircle(const Offset(20, 20), 15, cornerPaint);
    // Sağ üst köşe
    canvas.drawCircle(Offset(size.width - 20, 20), 15, cornerPaint);
    // Sol alt köşe
    canvas.drawCircle(Offset(20, size.height - 20), 15, cornerPaint);
    // Sağ alt köşe
    canvas.drawCircle(Offset(size.width - 20, size.height - 20), 15, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
