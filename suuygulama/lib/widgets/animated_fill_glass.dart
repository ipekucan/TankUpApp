import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';
import '../core/constants/app_constants.dart';

/// Animated glass widget with wave and bubble effects (same as tank screen).
class AnimatedFillGlass extends StatefulWidget {
  final Color liquidColor;
  final double amount; // ml
  final double maxAmount; // ml (e.g., 1000)
  final double width;
  final double height;

  const AnimatedFillGlass({
    super.key,
    required this.liquidColor,
    required this.amount,
    required this.maxAmount,
    this.width = 140,
    this.height = 220,
  });

  @override
  State<AnimatedFillGlass> createState() => _AnimatedFillGlassState();
}

class _AnimatedFillGlassState extends State<AnimatedFillGlass>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _bubbleController;
  final List<_GlassBubble> _bubbles = [];

  @override
  void initState() {
    super.initState();

    // Wave animation (same as tank screen)
    _waveController = AnimationController(
      duration: AppConstants.waveAnimationDuration,
      vsync: this,
    )..repeat();

    // Bubble animation (same as tank screen)
    _bubbleController = AnimationController(
      duration: AppConstants.bubbleAnimationDuration,
      vsync: this,
    )..repeat();

    _generateBubbles();
  }

  void _generateBubbles() {
    final random = math.Random();
    _bubbles.clear();
    for (int i = 0; i < 8; i++) {
      _bubbles.add(_GlassBubble(
        startX: random.nextDouble(),
        size: random.nextDouble() * 6 + 3,
        speed: random.nextDouble() * 0.5 + 0.5,
        delay: random.nextDouble(),
      ));
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fillPercentage = (widget.amount / widget.maxAmount).clamp(0.0, 1.0);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Glass outline with rounded corners
          CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _RoundedGlassPainter(
              color: widget.liquidColor,
            ),
          ),

          // Water fill with wave and bubbles
          Positioned.fill(
            child: ClipPath(
              clipper: _GlassClipper(),
              child: AnimatedBuilder(
                animation: Listenable.merge([_waveController, _bubbleController]),
                builder: (context, child) {
                  final waterHeight = widget.height * 0.8 * fillPercentage;
                  final waterTop = widget.height * 0.1 + (widget.height * 0.8 * (1 - fillPercentage));

                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // Main water layer
                      if (waterHeight > 0)
                        Positioned(
                          bottom: widget.height * 0.1,
                          left: widget.width * 0.15,
                          right: widget.width * 0.15,
                          height: waterHeight,
                          child: Container(
                            color: widget.liquidColor.withValues(alpha: 0.7),
                          ),
                        ),

                      // Wave effect (same as tank screen)
                      if (fillPercentage > 0.05 && waterHeight > 30)
                        Positioned(
                          bottom: widget.height * 0.1 + waterHeight - 15,
                          left: widget.width * 0.15,
                          right: widget.width * 0.15,
                          height: 30,
                          child: ClipRect(
                            child: WaveWidget(
                              config: CustomConfig(
                                gradients: [
                                  [
                                    widget.liquidColor.withValues(alpha: 0.4),
                                    widget.liquidColor.withValues(alpha: 0.3),
                                  ],
                                  [
                                    widget.liquidColor.withValues(alpha: 0.3),
                                    widget.liquidColor.withValues(alpha: 0.2),
                                  ],
                                ],
                                durations: const [
                                  AppConstants.waveGradientDuration1,
                                  AppConstants.waveGradientDuration2,
                                ],
                                heightPercentages: const [
                                  AppConstants.waveHeightPercentage1,
                                  AppConstants.waveHeightPercentage2,
                                ],
                              ),
                              waveAmplitude: 3.0,
                              waveFrequency: 1.5,
                              backgroundColor: Colors.transparent,
                              size: Size(
                                widget.width * 0.7,
                                30,
                              ),
                            ),
                          ),
                        ),

                      // Bubbles (same as tank screen)
                      if (waterHeight > 0)
                        ..._bubbles.map((bubble) {
                          final bubbleProgress =
                              (((_bubbleController.value * 2 + bubble.delay) % 2) / 2);
                          final bubbleY = widget.height * 0.1 +
                              (widget.height * 0.8 - bubbleProgress * waterHeight * 1.2);

                          if (bubbleY > waterTop && bubbleY < widget.height * 0.9 && waterHeight > 40) {
                            final bubbleX =
                                widget.width * 0.15 + bubble.startX * (widget.width * 0.7);
                            return Positioned(
                              left: bubbleX - bubble.size / 2,
                              bottom: widget.height - bubbleY - bubble.size / 2,
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
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bubble data for glass
class _GlassBubble {
  final double startX;
  final double size;
  final double speed;
  final double delay;

  _GlassBubble({
    required this.startX,
    required this.size,
    required this.speed,
    required this.delay,
  });
}

/// Clipper for glass shape
class _GlassClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final glassWidth = size.width * 0.7;
    final glassHeight = size.height * 0.8;
    final left = (size.width - glassWidth) / 2;
    final top = size.height * 0.1;

    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, glassWidth, glassHeight),
        const Radius.circular(15),
      ),
    );

    return path;
  }

  @override
  bool shouldReclip(_GlassClipper oldClipper) => false;
}

/// Painter for rounded glass outline
class _RoundedGlassPainter extends CustomPainter {
  final Color color;

  _RoundedGlassPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final glassWidth = size.width * 0.7;
    final glassHeight = size.height * 0.8;
    final glassLeft = (size.width - glassWidth) / 2;
    final glassTop = size.height * 0.1;

    // Rounded rectangle outline
    final outlineRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(glassLeft, glassTop, glassWidth, glassHeight),
      const Radius.circular(15),
    );

    final outlinePaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(outlineRect, outlinePaint);

    // Volume marks (3 horizontal lines)
    final markPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 1; i <= 3; i++) {
      final y = glassTop + (glassHeight / 4) * i;
      canvas.drawLine(
        Offset(glassLeft + 10, y),
        Offset(glassLeft + glassWidth - 10, y),
        markPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RoundedGlassPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
