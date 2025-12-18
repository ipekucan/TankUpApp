import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:async';
import '../utils/app_colors.dart';
import '../providers/water_provider.dart';
import '../providers/axolotl_provider.dart';
import '../models/axolotl_model.dart';
import 'shop_screen.dart';

class TankRoomScreen extends StatefulWidget {
  const TankRoomScreen({super.key});

  @override
  State<TankRoomScreen> createState() => _TankRoomScreenState();
}

class _TankRoomScreenState extends State<TankRoomScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _messageController;
  int _currentMessageIndex = 0;
  bool _showMessage = false;
  Timer? _dirtyCheckTimer;

  // Aksolotun günlüğü mesajları
  final List<String> _axolotlMessages = [
    'Bugün harika bir gün! 💙',
    'Su içmeyi unutma! 💧',
    'Seni çok seviyorum! 🌊',
    'Birlikte büyüyoruz! ✨',
    'Her gün daha iyi oluyoruz! 💪',
    'Su içmek çok önemli! 💙',
    'Seninle olmak harika! 🌟',
    'Bugün de harika bir gün olacak! ☀️',
  ];
  
  // Tank kirliyse gösterilecek özel mesaj
  final String _dirtyTankMessage = 'Burası çok yosunlanmış, temizlemek için biraz su içelim mi? 💧';

  @override
  void initState() {
    super.initState();
    _messageController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    // İlk mesajı göster
    _showRandomMessage();
    _messageController.forward();
    
    // Her saniye tank kirliliğini kontrol et
    _dirtyCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final waterProvider = Provider.of<WaterProvider>(context, listen: false);
        if (waterProvider.isTankDirty) {
          setState(() {
            _showMessage = true;
          });
          if (!_messageController.isAnimating) {
            _messageController.forward();
          }
        }
      }
    });
    
    // Her 8 saniyede bir yeni mesaj göster (tank temizse)
    _messageController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _messageController.reset();
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            final waterProvider = Provider.of<WaterProvider>(context, listen: false);
            if (!waterProvider.isTankDirty) {
              _showRandomMessage();
              _messageController.forward();
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _dirtyCheckTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tank durumunu kontrol et ve mesaj göster
    final waterProvider = Provider.of<WaterProvider>(context, listen: false);
    if (waterProvider.isTankDirty && !_showMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _showMessage = true;
          });
          if (!_messageController.isAnimating) {
            _messageController.forward();
          }
        }
      });
    }
  }

  void _showRandomMessage() {
    setState(() {
      _showMessage = true;
      _currentMessageIndex = math.Random().nextInt(_axolotlMessages.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.verySoftBlue,
      body: Consumer2<WaterProvider, AxolotlProvider>(
        builder: (context, waterProvider, axolotlProvider, child) {
          // Zen Odası'nda tank her zaman %100 dolu (sabit)
          const fillPercentage = 1.0; // %100 dolu
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
                      // Yosunlanma efekti - Yeşil %30 opaklıkta overlay (24 saat geçtiyse)
                      Visibility(
                        visible: isDirty,
                        child: Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.3), // %30 opaklık
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
                      
                      // Su seviyesi
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
                      
                      // Tank dekorasyonları
                      ...axolotlProvider.tankDecorations.map((decoration) {
                        return _buildTankDecoration(
                          decoration,
                          MediaQuery.of(context).size.width * 0.9,
                          MediaQuery.of(context).size.height * 0.85,
                        );
                      }).toList(),
                      
                      // Aksolot maskot
                      Center(
                        child: _FloatingAxolotl(
                          axolotlProvider: axolotlProvider,
                          fillPercentage: fillPercentage,
                          tankHeight: MediaQuery.of(context).size.height * 0.85,
                          buildAxolotl: _buildAxolotl,
                        ),
                      ),
                      
                      // Konuşma balonu - Aksolotun günlüğü
                      // Tank kirliyse özel mesaj göster, değilse normal mesajlar
                      if (_showMessage || isDirty)
                        Positioned(
                          top: MediaQuery.of(context).size.height * 0.1,
                          left: MediaQuery.of(context).size.width * 0.05,
                          right: MediaQuery.of(context).size.width * 0.05,
                          child: FadeTransition(
                            opacity: _messageController,
                            child: _buildSpeechBubble(
                              isDirty 
                                  ? _dirtyTankMessage 
                                  : _axolotlMessages[_currentMessageIndex],
                            ),
                          ),
                        ),
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

  // Konuşma balonu widget'ı
  Widget _buildSpeechBubble(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            color: AppColors.softPinkButton,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A5568),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Aksolot maskot çizimi
  Widget _buildAxolotl(AxolotlProvider provider) {
    final skinColor = _getSkinColor(provider.skinColor);
    final eyeColor = _getEyeColor(provider.eyeColor);
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Aksolot gövdesi
        Container(
          width: 110,
          height: 90,
          decoration: BoxDecoration(
            color: skinColor,
            borderRadius: BorderRadius.circular(55),
            boxShadow: [
              BoxShadow(
                color: skinColor.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        // Sol yanak
        Positioned(
          left: 15,
          top: 35,
          child: Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: skinColor.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Sağ yanak
        Positioned(
          right: 15,
          top: 35,
          child: Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: skinColor.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Sol göz
        Positioned(
          left: 30,
          top: 25,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: eyeColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: eyeColor.withValues(alpha: 0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
        // Sağ göz
        Positioned(
          right: 30,
          top: 25,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: eyeColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: eyeColor.withValues(alpha: 0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
        // Gülümseme
        Positioned(
          bottom: 25,
          child: Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: eyeColor.withValues(alpha: 0.8),
                  width: 3,
                ),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
          ),
        ),
        // Şapka (varsa)
        if (provider.accessories.any((a) => a.type == 'hat'))
          Positioned(
            top: -15,
            child: Container(
              width: 75,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.hatColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.hatColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        // Gözlük (varsa)
        if (provider.accessories.any((a) => a.type == 'glasses'))
          Positioned(
            top: 20,
            child: Container(
              width: 65,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.glassesColor.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.glassesColor,
                  width: 2,
                ),
              ),
            ),
          ),
        // Atkı (varsa)
        if (provider.accessories.any((a) => a.type == 'scarf'))
          Positioned(
            bottom: -8,
            child: Container(
              width: 90,
              height: 15,
              decoration: BoxDecoration(
                color: AppColors.scarfColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.scarfColor.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Tank dekorasyonu çizimi
  Widget _buildTankDecoration(TankDecoration decoration, double tankWidth, double tankHeight) {
    final x = decoration.x * tankWidth;
    final y = decoration.y * tankHeight;

    Widget decorationWidget;
    
    switch (decoration.type) {
      case 'coral':
        decorationWidget = Container(
          width: 40,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B9D).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B9D).withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(left: 5, top: 10, child: Container(width: 8, height: 20, decoration: BoxDecoration(color: const Color(0xFFFF8FAB).withValues(alpha: 0.9), borderRadius: BorderRadius.circular(4)))),
              Positioned(right: 5, top: 15, child: Container(width: 8, height: 18, decoration: BoxDecoration(color: const Color(0xFFFF8FAB).withValues(alpha: 0.9), borderRadius: BorderRadius.circular(4)))),
              Positioned(left: 16, top: 5, child: Container(width: 8, height: 15, decoration: BoxDecoration(color: const Color(0xFFFF8FAB).withValues(alpha: 0.9), borderRadius: BorderRadius.circular(4)))),
            ],
          ),
        );
        break;
      case 'starfish':
        decorationWidget = Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD93D).withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD93D).withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _StarfishPainter(),
          ),
        );
        break;
      case 'bubbles':
        decorationWidget = Stack(
          children: [
            Container(width: 20, height: 20, decoration: BoxDecoration(color: AppColors.waterColor.withValues(alpha: 0.6), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2))),
            Positioned(left: 15, top: 5, child: Container(width: 15, height: 15, decoration: BoxDecoration(color: AppColors.waterColor.withValues(alpha: 0.5), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5)))),
            Positioned(left: 8, top: 20, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: AppColors.waterColor.withValues(alpha: 0.4), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1)))),
          ],
        );
        break;
      default:
        decorationWidget = const SizedBox.shrink();
    }

    return Positioned(
      left: x - (decoration.type == 'coral' ? 20 : decoration.type == 'starfish' ? 17.5 : 15),
      top: y - (decoration.type == 'coral' ? 25 : decoration.type == 'starfish' ? 17.5 : 15),
      child: decorationWidget,
    );
  }

  Color _getSkinColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'pink':
        return AppColors.pinkSkin;
      case 'blue':
        return AppColors.blueSkin;
      case 'yellow':
        return AppColors.yellowSkin;
      case 'green':
        return AppColors.greenSkin;
      default:
        return AppColors.pinkSkin;
    }
  }

  Color _getEyeColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'black':
        return AppColors.blackEye;
      case 'brown':
        return AppColors.brownEye;
      case 'blue':
        return AppColors.blueEye;
      default:
        return AppColors.blackEye;
    }
  }
}

// Floating animasyonlu aksolot widget'ı
class _FloatingAxolotl extends StatefulWidget {
  final AxolotlProvider axolotlProvider;
  final double fillPercentage;
  final double tankHeight;
  final Widget Function(AxolotlProvider) buildAxolotl;

  const _FloatingAxolotl({
    required this.axolotlProvider,
    required this.fillPercentage,
    required this.tankHeight,
    required this.buildAxolotl,
  });

  @override
  State<_FloatingAxolotl> createState() => _FloatingAxolotlState();
}

class _FloatingAxolotlState extends State<_FloatingAxolotl>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waterHeight = widget.tankHeight * widget.fillPercentage;
    final minPosition = widget.tankHeight * 0.2;
    final waterTopPosition = waterHeight;
    final targetPosition = waterTopPosition > minPosition 
        ? waterTopPosition - 60
        : minPosition;
    final baseOffset = targetPosition - (widget.tankHeight / 2);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, baseOffset + _animation.value),
          child: widget.buildAxolotl(widget.axolotlProvider),
        );
      },
    );
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

// Deniz yıldızı çizim painter'ı
class _StarfishPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFE66D)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * 3.14159 / 5) - (3.14159 / 2);
      final x = center.dx + radius * 0.8 * math.cos(angle);
      final y = center.dy + radius * 0.8 * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

