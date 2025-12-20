import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:async';
import '../utils/app_colors.dart';
import '../providers/water_provider.dart';
import '../providers/aquarium_provider.dart';
import '../models/decoration_item.dart';
import 'shop_screen.dart';

class TankRoomScreen extends StatefulWidget {
  const TankRoomScreen({super.key});

  @override
  State<TankRoomScreen> createState() => _TankRoomScreenState();
}

class _TankRoomScreenState extends State<TankRoomScreen>
    with TickerProviderStateMixin {
  Timer? _dirtyCheckTimer;

  @override
  void initState() {
    super.initState();
    
    // Her saniye tank kirliliğini kontrol et
    _dirtyCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {}); // Kirlilik durumunu güncelle
      }
    });
  }

  @override
  void dispose() {
    _dirtyCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.verySoftBlue,
      body: Consumer2<WaterProvider, AquariumProvider>(
        builder: (context, waterProvider, aquariumProvider, child) {
          // Zen Odası'nda tank her zaman %100 dolu (sabit)
          const fillPercentage = 1.0;
          final isDirty = waterProvider.isTankDirty;
          
          return Stack(
            children: [
              // Tam ekran tank görünümü
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Yosunlanma efekti - Yeşil %30 opaklıkta overlay
                      Visibility(
                        visible: isDirty,
                        child: Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Stack(
                              children: [
                                // Yosun çizimleri
                                CustomPaint(
                                  painter: _AlgaePainter(),
                                  size: Size(
                                    MediaQuery.of(context).size.width * 0.9,
                                    MediaQuery.of(context).size.height * 0.85,
                                  ),
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          height: MediaQuery.of(context).size.height * 0.85 * fillPercentage,
                          decoration: BoxDecoration(
                            color: isDirty
                                ? AppColors.waterColor.withValues(alpha: 0.5)
                                : AppColors.waterColor.withValues(alpha: 0.7),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(40),
                              bottomRight: Radius.circular(40),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.waterColor.withValues(alpha: 0.3),
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
                          MediaQuery.of(context).size.width * 0.9,
                          MediaQuery.of(context).size.height * 0.85,
                        );
                      }),
                    ],
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
