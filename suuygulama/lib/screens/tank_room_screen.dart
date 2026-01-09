import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:async';
import '../utils/app_colors.dart';
import '../providers/daily_hydration_provider.dart';
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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  Timer? _dirtyCheckTimer;
  Timer? _bubbleTimer;
  final List<BubbleModel> _bubbles = [];
  final math.Random _random = math.Random();
  double _animationTime = 0.0;
  late AnimationController _godRayAnimationController; // Işık hüzmeleri için AnimationController
  bool _isAppInForeground = true; // Track app lifecycle state

  @override
  void initState() {
    super.initState();
    
    // Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    
    // Işık hüzmeleri AnimationController (10 saniye, repeat reverse)
    _godRayAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    
    _startTimers();
  }
  
  /// Start both timers (called on init and resume)
  void _startTimers() {
    // Cancel existing timers first
    _stopTimers();
    
    // Her saniye tank kirliliğini kontrol et
    _dirtyCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isAppInForeground) {
        setState(() {}); // Kirlilik durumunu güncelle
      }
    });

    // Baloncuk animasyon döngüsü (60fps = 16ms)
    _bubbleTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted || !_isAppInForeground) return;

      _animationTime += 0.016; // Zaman ilerlemesi

      // Rastgele aralıklarla yeni baloncuk üret (alt kısımdan) - ENHANCED DENSITY
      if (_random.nextDouble() < 0.025) { // Increased spawn rate for more bubbles (2.5% chance)
        final size = 8 + _random.nextDouble() * 24; // 8-32 arası boyut (larger variation)
        
        // Hız: Çok yavaş hareket (premium relaxing feel)
        final normalizedSize = (size - 8) / 24; // 8-32 -> 0.0-1.0
        final baseSpeed = 0.0003; // Much slower minimum speed
        final speedRange = 0.0008; // Slower speed range
        final speed = baseSpeed + (normalizedSize * speedRange);
        
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
        
        // Sinüs fonksiyonu ile sağa-sola yalpalama (wobble) - GENTLER
        final wobblePhase = bubble.wobbleOffset + (_animationTime * bubble.wobbleSpeed);
        bubble.x += math.sin(wobblePhase + bubble.id) * 0.0008; // Reduced wobble for smoother movement
        
        // Ekranın tepesinden çıkanları sil
        return bubble.y < -0.1;
      });

      if (mounted) {
        setState(() {});
      }
    });
  }
  
  /// Stop all timers (called on pause and dispose)
  void _stopTimers() {
    _dirtyCheckTimer?.cancel();
    _dirtyCheckTimer = null;
    _bubbleTimer?.cancel();
    _bubbleTimer = null;
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - restart timers
        _isAppInForeground = true;
        _godRayAnimationController.repeat(reverse: true);
        _startTimers();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App went to background - stop timers to prevent ANR
        _isAppInForeground = false;
        _godRayAnimationController.stop();
        _stopTimers();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimers();
    _godRayAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Extend behind status bar
      backgroundColor: Colors.transparent,
      body: Consumer2<DailyHydrationProvider, AquariumProvider>(
        builder: (context, dailyHydrationProvider, aquariumProvider, child) {
          final screenSize = MediaQuery.of(context).size;
          
          return Stack(
            children: [
              // LAYER 1: FULL-SCREEN SOFT PASTEL BLUE GRADIENT (Edge-to-Edge)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFD4F1F4), // Soft pastel cyan - top
                        Color(0xFFB8E6E9), // Light aqua - middle top
                        Color(0xFFA0DDE2), // Medium turquoise - middle
                        Color(0xFF87D4DB), // Deeper turquoise - bottom
                      ],
                      stops: [0.0, 0.3, 0.6, 1.0],
                    ),
                  ),
                ),
              ),

              // LAYER 1.5: GOD RAYS (Light Shafts from top-left)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _godRayAnimationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _GodRaysPainter(
                        animationValue: _godRayAnimationController.value,
                      ),
                    );
                  },
                ),
              ),

              // LAYER 2: PREMIUM BUBBLES - Highly transparent, slow, varied sizes
              ...List.generate(_bubbles.length, (index) {
                final bubble = _bubbles[index];
                final bubbleX = bubble.x * screenSize.width;
                final bubbleY = bubble.y * screenSize.height;
                
                return Positioned(
                  left: bubbleX - bubble.size / 2,
                  top: bubbleY - bubble.size / 2,
                  child: Container(
                    width: bubble.size,
                    height: bubble.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.3, -0.3),
                        radius: 1.0,
                        colors: [
                          Colors.white.withValues(alpha: 0.15), // Very subtle center
                          Colors.white.withValues(alpha: 0.08), // Ultra transparent middle
                          Colors.white.withValues(alpha: 0.0), // Fully transparent edge
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2), // Very subtle border
                        width: 1.0,
                      ),
                    ),
                  ),
                );
              }),

              // LAYER 3: FISH & DECORATIONS (Between background and HUD)
              Positioned.fill(
                child: Stack(
                  children: aquariumProvider.activeDecorationsList.map((decoration) {
                    return _buildDecoration(
                      decoration,
                      screenSize.width,
                      screenSize.height,
                    );
                  }).toList(),
                ),
              ),
              
              // LAYER 4: TOP-RIGHT HUD - Pixel Perfect Geometry
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0, right: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. SHOP BUTTON (Green Squircle)
                        Container(
                          height: 54,
                          width: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC1E27C), // Pastel Green
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFC1E27C).withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                _stopTimers(); // STOP BEFORE PUSH
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ShopScreen(),
                                  ),
                                );
                                _startTimers(); // RESTART AFTER POP
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: const Center(
                                child: Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 20), // Spacer

                        // 2. COIN CAPSULE (Seamless Stack Layout)
                        Stack(
                          alignment: Alignment.centerLeft,
                          clipBehavior: Clip.none,
                          children: [
                            // The Tail (White Pill) - Starts from center of coin
                            Container(
                              height: 54,
                              margin: const EdgeInsets.only(left: 27), // Starts exactly at coin center radius
                              padding: const EdgeInsets.only(left: 36, right: 32), // Extra padding for length
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(27),
                                  bottomRight: Radius.circular(27),
                                  // Left side is hidden/square because it's under the coin, or rounded doesn't matter
                                  topLeft: Radius.circular(0), 
                                  bottomLeft: Radius.circular(0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${dailyHydrationProvider.tankCoins}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF5D4037),
                                ),
                              ),
                            ),
                            
                            // The Head (Yellow Coin) - Sits on top
                            Container(
                              height: 54,
                              width: 54,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E38D), // Pastel Yellow
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF3E38D).withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.monetization_on_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  // Dekorasyon çizimi (adjusted for full screen)
  Widget _buildDecoration(DecorationItem decoration, double screenWidth, double screenHeight) {
    final x = decoration.left * screenWidth;
    final y = (1.0 - decoration.bottom) * screenHeight;

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
            color: AppColors.softPinkButton.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: AppColors.softPinkButton,
            size: 28,
          ),
        );
    }
  }
}

/// God Rays Painter - Light shafts from top-left
class _GodRaysPainter extends CustomPainter {
  final double animationValue;

  _GodRaysPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.softLight;

    // Create 5 light rays from top-left
    final rayCount = 5;
    final rayWidth = size.width * 0.2;
    final startX = -size.width * 0.3;
    
    for (int i = 0; i < rayCount; i++) {
      final xOffset = i * (size.width * 0.3) + (animationValue * 20); // Subtle animation
      final path = Path();
      
      // Start point (top)
      path.moveTo(startX + xOffset, 0);
      path.lineTo(startX + xOffset + rayWidth, 0);
      
      // End point (bottom, spreading wider)
      path.lineTo(startX + xOffset + rayWidth * 2.5, size.height);
      path.lineTo(startX + xOffset + rayWidth * 0.3, size.height);
      path.close();
      
      // Gradient for each ray
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.12 - (i * 0.02)), // Varying opacity
          Colors.white.withValues(alpha: 0.06 - (i * 0.01)),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.4, 1.0],
      );
      
      paint.shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GodRaysPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}


