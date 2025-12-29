import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../utils/app_colors.dart';
import '../providers/water_provider.dart';
import '../providers/aquarium_provider.dart';
import '../providers/user_provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/challenge_provider.dart';
import '../models/achievement_model.dart';
import '../widgets/interactive_cup_modal.dart';
import '../utils/unit_converter.dart';
import '../core/constants/app_constants.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tank/tank_visualization.dart';
import '../widgets/tank/tank_controls.dart';
import '../widgets/tank/challenge_panel.dart';
import '../widgets/tank/achievement_dialog.dart';
import '../widgets/challenge_card.dart';
import 'success_screen.dart';
import 'drink_gallery_screen.dart';

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
  late DraggableScrollableController _challengeSheetController;
  double _animatedFillPercentage = 0.0;
  final List<TankBubble> _bubbles = [];

  @override
  void initState() {
    super.initState();
    _challengeSheetController = DraggableScrollableController();
    
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
    _challengeSheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: _buildTankView(),
        ),
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
        final progressPercentage = dailyGoal > 0
            ? (currentIntake / dailyGoal * 100)
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
            // Ana içerik - ScrollView
            SingleChildScrollView(
              child: Column(
                children: [
                  // Üst Bar: Sol - Günlük Seri Butonu, Sağ - Coin Butonu
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.defaultHorizontalPadding,
                      vertical: AppConstants.defaultVerticalPadding,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Sol: Günlük Seri/Challenge Butonu
                        _StatusToggleButton(
                          challengeProvider:
                              Provider.of<ChallengeProvider>(context, listen: false),
                          userProvider: userProvider,
                          progressPercentage: progressPercentage,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SuccessScreen(),
                              ),
                            );

                            if (!mounted) return;

                            if (result == 'open_challenges_panel') {
                              _challengeSheetController.animateTo(
                                AppConstants.challengeSheetOpenSize,
                                duration: AppConstants.defaultAnimationDuration,
                                curve: Curves.easeOut,
                              );
                            }
                          },
                        ),

                        // Sağ: Dairesel Coin Butonu
                        ScaleTransition(
                          scale: _coinScaleAnimation,
                          child: Container(
                            width: AppConstants.coinButtonSize,
                            height: AppConstants.coinButtonSize,
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.monetization_on,
                                  color: AppColors.goldCoin,
                                  size: AppConstants.coinButtonIconSize,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${waterProvider.tankCoins}',
                                  style: TextStyle(
                                    fontSize: AppConstants.coinButtonTextSize,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.goldCoin,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppConstants.extraLargeSpacing),

                  // Tank Görselleştirme
                  TankVisualization(
                    fillPercentage: _animatedFillPercentage,
                    fillAnimation: _fillAnimation,
                    bubbleController: _bubbleController,
                    waveController: _waveController,
                    bubbles: _bubbles,
                  ),

                  // Tank Altı: Günlük Hedef
                  Padding(
                    padding: EdgeInsets.only(top: AppConstants.largePadding),
                    child: Center(
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
                  ),
                ],
              ),
            ),

            // Buton Paneli
            TankControls(
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

            // Mücadele Paneli
            ChallengePanel(
              controller: _challengeSheetController,
            ),
          ],
        );
      },
    );
  }
}

// Akıllı ve Hareketli Durum Butonu
class _StatusToggleButton extends StatefulWidget {
  final ChallengeProvider challengeProvider;
  final UserProvider userProvider;
  final double progressPercentage;
  final VoidCallback onTap;

  const _StatusToggleButton({
    required this.challengeProvider,
    required this.userProvider,
    required this.progressPercentage,
    required this.onTap,
  });

  @override
  State<_StatusToggleButton> createState() => _StatusToggleButtonState();
}

class _StatusToggleButtonState extends State<_StatusToggleButton> {
  Timer? _toggleTimer;
  bool _showChallenge = false;
  Challenge? _firstActiveChallenge;

  @override
  void initState() {
    super.initState();
    _checkActiveChallenge();

    if (_firstActiveChallenge != null) {
      _toggleTimer = Timer.periodic(AppConstants.statusToggleDuration, (timer) {
        if (mounted) {
          setState(() {
            _showChallenge = !_showChallenge;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _toggleTimer?.cancel();
    super.dispose();
  }

  void _checkActiveChallenge() {
    final activeChallenges = widget.challengeProvider.activeIncompleteChallenges;
    final hasActiveChallenge = activeChallenges.isNotEmpty;

    if (hasActiveChallenge) {
      _firstActiveChallenge = activeChallenges.first;
      if (_toggleTimer == null || !_toggleTimer!.isActive) {
        _toggleTimer?.cancel();
        _toggleTimer = Timer.periodic(AppConstants.statusToggleDuration, (timer) {
          if (mounted) {
            setState(() {
              _showChallenge = !_showChallenge;
            });
          }
        });
      }
    } else {
      _firstActiveChallenge = null;
      _toggleTimer?.cancel();
      _toggleTimer = null;
      if (mounted && _showChallenge) {
        setState(() {
          _showChallenge = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _checkActiveChallenge();
    final hasActiveChallenge = _firstActiveChallenge != null;

    if (!hasActiveChallenge) {
      return GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: AppConstants.statusButtonSize,
          height: AppConstants.statusButtonSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: AppConstants.statusButtonSize,
                height: AppConstants.statusButtonSize,
                child: CircularProgressIndicator(
                  value: widget.progressPercentage / 100,
                  strokeWidth: AppConstants.progressIndicatorStrokeWidth,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.softPinkButton,
                  ),
                ),
              ),
              Container(
                width: AppConstants.statusButtonInnerSize,
                height: AppConstants.statusButtonInnerSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: AppConstants.defaultShadowAlpha),
                      blurRadius: AppConstants.smallShadowBlur,
                      offset: AppConstants.smallShadowOffset,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: AppColors.softPinkButton,
                      size: AppConstants.statusButtonIconSize,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.userProvider.consecutiveDays}',
                      style: TextStyle(
                        fontSize: AppConstants.statusButtonTextSize,
                        fontWeight: FontWeight.w700,
                        color: AppColors.softPinkButton,
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

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: AppConstants.statusButtonSize,
        height: AppConstants.statusButtonSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: AppConstants.statusButtonSize,
              height: AppConstants.statusButtonSize,
              child: CircularProgressIndicator(
                value: _showChallenge && _firstActiveChallenge != null
                    ? _firstActiveChallenge!.progress.clamp(0.0, 1.0)
                    : widget.progressPercentage / 100,
                strokeWidth: AppConstants.progressIndicatorStrokeWidth,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _showChallenge ? Colors.orange : AppColors.softPinkButton,
                ),
              ),
            ),
            Container(
              width: AppConstants.statusButtonInnerSize,
              height: AppConstants.statusButtonInnerSize,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: AppConstants.defaultShadowAlpha),
                    blurRadius: AppConstants.smallShadowBlur,
                    offset: AppConstants.smallShadowOffset,
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: AppConstants.animatedSwitcherDuration,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: _showChallenge
                    ? Column(
                        key: const ValueKey('challenge'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emoji_events,
                            color: Colors.orange,
                            size: AppConstants.statusButtonIconSize,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(_firstActiveChallenge!.progress * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: AppConstants.statusButtonTextSize,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        key: const ValueKey('streak'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: AppColors.softPinkButton,
                            size: AppConstants.statusButtonIconSize,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.userProvider.consecutiveDays}',
                            style: TextStyle(
                              fontSize: AppConstants.statusButtonTextSize,
                              fontWeight: FontWeight.w700,
                              color: AppColors.softPinkButton,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
