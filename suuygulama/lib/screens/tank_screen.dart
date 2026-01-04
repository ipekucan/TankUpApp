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
import '../widgets/drink_selection_modal.dart';
import '../widgets/tank/challenge_button.dart';
import '../widgets/tank/coin_button.dart';
import '../widgets/tank/streak_button.dart';
import '../features/challenge/screens/challenge_screen.dart';
import 'history_screen.dart';


class TankScreen extends StatefulWidget {
  const TankScreen({super.key});

  @override
  State<TankScreen> createState() => _TankScreenState();
}

class _TankScreenState extends State<TankScreen> with TickerProviderStateMixin {
  late AnimationController _coinAnimationController;
  late AnimationController _waveController;
  late AnimationController _fillController;
  late Animation<double> _fillAnimation;
  late AnimationController _bubbleController;
  double _animatedFillPercentage = 0.0;
  final List<TankBubble> _bubbles = [];
  
  @override
  void initState() {
    super.initState();
    
    // Coin animasyonu (removed - no longer using scale animation)
    _coinAnimationController = AnimationController(
      duration: AppConstants.defaultAnimationDuration,
      vsync: this,
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
              // Lighter background colors - increased brightness by 10-15%
              Color(0xFFE8F7F3), // Lighter soft mint/aqua top
              Color(0xFFF8F5F0), // Lighter cream middle
              Color(0xFFFEFAF6), // Lighter warm cream bottom
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
        
        return Stack(
          children: [
            // Layer 2: Main Content Column
            SafeArea(
              child: Column(
                children: [
                  // Header Row - Clean design with 3 equal buttons
                Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 16.0,
                      ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        // Left: Streak Button (54x54)
                        StreakButton(
                          streakCount: userProvider.consecutiveDays,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HistoryScreen(
                                  hideAppBar: false,
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const Spacer(),
                    
                        // Right: Coin + Challenge Button Column
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Coin Button (54x54)
                            CoinButton(
                              coinAmount: dailyHydrationProvider.tankCoins,
                            ),

                            const SizedBox(height: 12), // Space between buttons

                            // Challenge Button (54x54)
                            ChallengeButton(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ChallengeScreen(),
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
          
          // Floating Add Water Button - Bottom Center
          Positioned(
            left: 0,
            right: 0,
            bottom: 100, // Above nav bar
            child: Center(
              child: _FloatingAddWaterButton(
                onTap: _showWaterModal,
              ),
            ),
          ),
          ],
        );
      },
    );
  }
  
  void _showWaterModal() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      isScrollControlled: true,
      builder: (context) => const DrinkSelectionModal(),
    );
  }
}
/// Floating Add Water Button - Large circular button at bottom center
class _FloatingAddWaterButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FloatingAddWaterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF81B9C9), // Updated to requested color
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF81B9C9).withValues(alpha: 0.4),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.water_drop_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}

