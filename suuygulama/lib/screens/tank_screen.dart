import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/daily_hydration_provider.dart';
import '../providers/aquarium_provider.dart';
import '../providers/user_provider.dart';
import '../utils/unit_converter.dart';
import '../core/constants/app_constants.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tank/tank_visualization.dart';
import 'drink_gallery_screen.dart';
import 'success_screen.dart';

class TankScreen extends StatefulWidget {
  const TankScreen({super.key});

  @override
  State<TankScreen> createState() => _TankScreenState();
}

class _TankScreenState extends State<TankScreen> with TickerProviderStateMixin {
  late AnimationController _coinAnimationController;
  late Animation<double> _coinScaleAnimation;
  late AnimationController _waveController;
  late AnimationController _fillController;
  late Animation<double> _fillAnimation;
  late AnimationController _bubbleController;
  double _animatedFillPercentage = 0.0;
  final List<TankBubble> _bubbles = [];
  
  @override
  void initState() {
    super.initState();
    
    // Coin animasyonu
    _coinAnimationController = AnimationController(
      duration: AppConstants.defaultAnimationDuration,
      vsync: this,
    );
    _coinScaleAnimation = Tween<double>(
      begin: AppConstants.coinScaleBegin,
      end: AppConstants.coinScaleEnd,
    ).animate(
      CurvedAnimation(
        parent: _coinAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    
    // Dalga animasyonu
    _waveController = AnimationController(
      duration: AppConstants.waveAnimationDuration,
      vsync: this,
    )..repeat();
    
    // Su dolum animasyonu
    _fillController = AnimationController(
      duration: AppConstants.longAnimationDuration,
      vsync: this,
    );
    _fillAnimation = Tween<double>(
      begin: AppConstants.fillAnimationBegin,
      end: AppConstants.fillAnimationEnd,
    ).animate(
      CurvedAnimation(
        parent: _fillController,
        curve: Curves.easeOut,
      ),
    );
    
    // Bubble animasyonu
    _bubbleController = AnimationController(
      duration: AppConstants.bubbleAnimationDuration,
      vsync: this,
    )..repeat();
    
    _generateBubbles();
  }
  
  void _generateBubbles() {
    _bubbles.clear();
    final random = math.Random();
    for (int i = 0; i < AppConstants.bubbleCount; i++) {
      _bubbles.add(TankBubble(
        startX: random.nextDouble() *
                (AppConstants.bubbleXRangeEnd - AppConstants.bubbleXRangeStart) +
            AppConstants.bubbleXRangeStart,
        size: random.nextDouble() *
                (AppConstants.maxBubbleSize - AppConstants.minBubbleSize) +
            AppConstants.minBubbleSize,
        speed: random.nextDouble() *
                (AppConstants.maxBubbleSpeed - AppConstants.minBubbleSpeed) +
            AppConstants.minBubbleSpeed,
        delay: random.nextDouble() * AppConstants.maxBubbleDelay,
      ));
    }
  }
  
  @override
  void dispose() {
    _coinAnimationController.dispose();
    _waveController.dispose();
    _fillController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Layer 1: Background Gradient (FIRST child - fixes white screen)
          Positioned.fill(
            child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppConstants.backgroundGradientColor1,
              AppConstants.backgroundGradientColor2,
              AppConstants.backgroundGradientColor3,
            ],
            stops: [
              AppConstants.backgroundGradientStop1,
              AppConstants.backgroundGradientStop2,
              AppConstants.backgroundGradientStop3,
            ],
          ),
        ),
            ),
          ),
          // Layer 2: Content
          SafeArea(
          child: _buildTankView(),
        ),
        ],
      ),
    );
  }

  Widget _buildTankView() {
    return Consumer3<DailyHydrationProvider, AquariumProvider, UserProvider>(
      builder: (context, dailyHydrationProvider, aquariumProvider, userProvider, child) {
        final currentIntake = dailyHydrationProvider.consumedAmount;
        final dailyGoal = dailyHydrationProvider.dailyGoal;
        final fillPercentage = (dailyGoal > 0) 
            ? (currentIntake / dailyGoal).clamp(0.0, 1.0) 
            : 0.0;
        
        // Animasyonlu dolum: fillPercentage değiştiğinde animasyonu başlat
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          
          final currentAnimatedFill = _animatedFillPercentage.clamp(0.0, 1.0);
          final targetFill = fillPercentage.clamp(0.0, 1.0);
          
          if ((targetFill - currentAnimatedFill).abs() > AppConstants.minFillDifference) {
            _fillController.reset();
            _fillAnimation = Tween<double>(
              begin: currentAnimatedFill,
              end: targetFill,
            ).animate(
              CurvedAnimation(
                parent: _fillController,
                curve: Curves.easeOut,
              ),
            )..addListener(() {
              if (mounted) {
                final newValue = _fillAnimation.value.clamp(0.0, 1.0);
                  if ((newValue - _animatedFillPercentage).abs() >
                      AppConstants.minAnimationValueDifference) {
                  _animatedFillPercentage = newValue;
                  setState(() {});
                }
              }
            });
            _fillController.forward();
          } else if (currentAnimatedFill == 0.0 && targetFill > 0.0) {
            _animatedFillPercentage = targetFill;
            if (mounted) {
              setState(() {});
            }
          }
        });
        
        final progressPercentage = dailyGoal > 0 
            ? (currentIntake / dailyGoal).clamp(0.0, 1.0)
            : 0.0;
        
        return Stack(
          children: [
            // Layer 2: Main Content Column
            SafeArea(
              child: Column(
                children: [
                  // Header Row - Clean design without labels
                Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 16.0,
                      ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        // Left: Fire/Streak Button (no label)
                        _CircleIconButton(
                          icon: Icons.local_fire_department,
                          iconColor: const Color(0xFFFF8A80),
                          progressPercentage: progressPercentage,
                          size: 54,
                          iconSize: 28,
                          progressRingSpacing: 6, // More spacing from button
                          onTap: () {
                            Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SuccessScreen(),
                          ),
                        );
                      },
                    ),
                    
                        const Spacer(),
                    
                        // Right: Coin Button + Menu Button (stacked vertically)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Coin Button (same size as fire button)
                    ScaleTransition(
                      scale: _coinScaleAnimation,
                              child: _CircleIconButton(
                                icon: Icons.monetization_on,
                                iconColor: const Color(0xFFFFD54F),
                                size: 54,
                                iconSize: 28,
                                badgeText: '${dailyHydrationProvider.tankCoins}',
                                onTap: () {
                                  // Could open rewards/shop screen
                                },
                            ),
                    ),
                            const SizedBox(height: 12),
                            // Menu Button (below coin, same size)
                            _GradientMenuButton(
                              size: 54,
                              onTap: () {
                                if (!mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const DrinkGalleryScreen(),
                              ),
                                );
                              },
                        ),
                          ],
                    ),
                  ],
                ),
              ),
              
                  // Spacer (push tank down from larger header)
                  const Spacer(flex: 3),

                  // Water Tank Visualization
                  TankVisualization(
                    fillPercentage: _animatedFillPercentage,
                    fillAnimation: _fillAnimation,
                    bubbleController: _bubbleController,
                    waveController: _waveController,
                    bubbles: _bubbles,
              ),
              
                  // Spacing between tank and text
                  const SizedBox(height: 15),
                  
                  // Daily Goal Text
                  Center(
                  child: Text(
                    'Günlük Hedef: ${UnitConverter.formatVolume(dailyGoal, userProvider.isMetric)}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontSize: AppConstants.dailyGoalFontSize,
                          fontWeight: FontWeight.w500,
                          color: Colors.black45,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                  
                  // Spacer (more space below since controls removed)
                  const Spacer(flex: 3),
                  
                  // Reserve space at bottom for nav bar
                  const SizedBox(height: 100),
                ],
              ),
          ),
          ],
        );
      },
    );
  }
}

/// Circle Icon Button - Clean design without label
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final double? progressPercentage;
  final String? badgeText;
  final double size;
  final double iconSize;
  final double progressRingSpacing;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.iconColor,
    this.progressPercentage,
    this.badgeText,
    this.size = 52,
    this.iconSize = 24,
    this.progressRingSpacing = 4,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ringSize = size + (progressRingSpacing * 2);
    final innerSize = size - 8;

      return GestureDetector(
      onTap: onTap,
        child: SizedBox(
        width: ringSize,
        height: ringSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
            // Progress ring (if provided) - with more spacing
            if (progressPercentage != null && progressPercentage! > 0)
              SizedBox(
                width: ringSize,
                height: ringSize,
                child: CustomPaint(
                  painter: _SoftProgressPainter(
                    progress: progressPercentage!,
                    strokeWidth: 3.0,
                    progressColor: iconColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
            // Main icon container
              Container(
              width: innerSize,
              height: innerSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                    color: iconColor.withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    ),
                  ],
                ),
              child: Stack(
                alignment: Alignment.center,
                  children: [
                    Icon(
                    icon,
                    color: iconColor,
                    size: iconSize,
                  ),
                  // Badge for reward count
                  if (badgeText != null)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: iconColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badgeText!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                        fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
}

/// Gradient Menu Button - With multi-color gradient icon
class _GradientMenuButton extends StatelessWidget {
  final double size;
  final VoidCallback onTap;

  const _GradientMenuButton({
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final innerSize = size - 8;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: innerSize,
        height: innerSize,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
              color: Colors.purple.withValues(alpha: 0.1),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 2),
                          ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF9A9E), // Soft pink
                Color(0xFFFECFEF), // Light pink
                Color(0xFFA18CD1), // Soft purple
                Color(0xFF5FC3E4), // Soft blue
              ],
              stops: [0.0, 0.3, 0.6, 1.0],
            ).createShader(bounds),
            child: Icon(
              Icons.grid_view_rounded,
              color: Colors.white,
              size: size * 0.45,
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft progress ring painter
class _SoftProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color progressColor;

  _SoftProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Background track
    final bgPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, bgPaint);
    
    // Progress arc
    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress;
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SoftProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

