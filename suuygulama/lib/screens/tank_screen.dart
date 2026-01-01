import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../providers/water_provider.dart';
import '../providers/aquarium_provider.dart';
import '../providers/user_provider.dart';
import '../providers/achievement_provider.dart';
import '../models/achievement_model.dart';
import '../widgets/interactive_cup_modal.dart';
import '../utils/unit_converter.dart';
import '../core/constants/app_constants.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tank/tank_visualization.dart';
import '../widgets/tank/tank_controls.dart';
import '../widgets/tank/achievement_dialog.dart';
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
    return Consumer4<WaterProvider, AquariumProvider, UserProvider, AchievementProvider>(
      builder: (context, waterProvider, aquariumProvider, userProvider, achievementProvider, child) {
        final currentIntake = waterProvider.consumedAmount;
        final dailyGoal = waterProvider.dailyGoal;
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
                  // Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.defaultHorizontalPadding,
                      vertical: AppConstants.defaultVerticalPadding,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Status Toggle Button (Fire Icon with Progress Ring)
                        _StatusToggleButton(
                          progressPercentage: progressPercentage,
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
                        
                        // Right: Coin Balance Button (matching Fire button size)
                        ScaleTransition(
                          scale: _coinScaleAnimation,
                          child: Container(
                            height: 56.0,
                            constraints: const BoxConstraints(minWidth: 56.0),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: AppConstants.defaultShadowAlpha,
                                  ),
                                  blurRadius: AppConstants.defaultShadowBlur,
                                  offset: AppConstants.defaultShadowOffset,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.monetization_on,
                                  color: AppColors.goldCoin,
                                  size: 24.0,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${waterProvider.tankCoins}',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.goldCoin,
                                    letterSpacing: 0.5,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                  
                  // Spacer (less space below, since Controls are floating over it)
                  const Spacer(flex: 2),
                  
                  // Reserve space at bottom for raised controls
                  const SizedBox(height: 180),
                ],
              ),
            ),
            
            // Layer 3: Floating Controls (Positioned significantly higher from bottom)
            Positioned(
              bottom: 130,
              left: 0,
              right: 0,
              child: TankControls(
              onShowDrinkSelector: () {
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DrinkGalleryScreen(),
                  ),
                );
              },
              onShowInteractiveCupModal: (
                BuildContext context,
                WaterProvider waterProvider,
                UserProvider userProvider,
                AchievementProvider achievementProvider,
              ) async {
                final previousConsumedAmount = waterProvider.consumedAmount;
                
                final result = await showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  barrierColor: Colors.black.withValues(alpha: 0.5),
                  isScrollControlled: true,
                  builder: (context) => const InteractiveCupModal(),
                );
                
                if (result != null && result is double) {
                  final currentConsumedAmount = waterProvider.consumedAmount;
                  
                  if (previousConsumedAmount == 0.0 && currentConsumedAmount > 0.0) {
                    if (!context.mounted) return;
                    final achievementProvider =
                        Provider.of<AchievementProvider>(context, listen: false);
                    final isAlreadyUnlocked =
                        achievementProvider.isAchievementUnlocked('first_cup');
        
                    if (!isAlreadyUnlocked) {
                      final coinReward = await achievementProvider.checkFirstCup();
                      
                      if (coinReward > 0) {
                        await waterProvider.addCoins(coinReward);
                        if (!mounted) return;
                      }
                      
                      if (!mounted) return;
                      
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          final achievement = achievementProvider.achievements.firstWhere(
                            (a) => a.id == 'first_cup',
                            orElse: () => Achievement(
                              id: 'first_cup',
                              name: 'İlk Bardak',
                              description: 'Uygulamadaki ilk suyunu iç ve macerayı başlat!',
                              coinReward: 20,
                            ),
                          );
                          
                          AchievementDialog.show(
                            context,
                            achievement,
                            cardColor: AppConstants.firstCupAchievementColor,
                            badgeEmoji: '💧',
                          );
                        }
                      });
                    }
                  }
                }
              },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Status Toggle Button with Fire Icon and Progress Ring
class _StatusToggleButton extends StatelessWidget {
  final double progressPercentage;
  final VoidCallback onTap;

  const _StatusToggleButton({
    required this.progressPercentage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const buttonSize = 56.0;
    const innerSize = 46.0;
    const iconSize = 30.0;
    
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: buttonSize,
        height: buttonSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Layer 1: CircularProgressIndicator (background ring)
            SizedBox(
              width: buttonSize,
              height: buttonSize,
              child: CircularProgressIndicator(
                value: progressPercentage,
                strokeWidth: AppConstants.progressIndicatorStrokeWidth,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.softPinkButton,
                ),
              ),
            ),
            // Layer 2: White circle container with shadow
            Container(
              width: innerSize,
              height: innerSize,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: AppConstants.defaultShadowAlpha,
                    ),
                    blurRadius: AppConstants.smallShadowBlur,
                    offset: AppConstants.smallShadowOffset,
                  ),
                ],
              ),
              // Layer 3: Fire Icon (centered, matching coin icon size)
              child: Icon(
                Icons.local_fire_department,
                color: AppColors.softPinkButton,
                size: iconSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
