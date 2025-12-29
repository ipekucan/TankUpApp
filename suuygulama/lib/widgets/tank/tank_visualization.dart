import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';
import '../../widgets/glass_fish_bowl.dart';
import '../../core/constants/app_constants.dart';

/// Bubble data model for tank visualization
class TankBubble {
  final double startX; // 0.0 - 1.0 arası (tank genişliğine göre)
  final double size; // Kabarcık boyutu
  final double speed; // Yükselme hızı
  final double delay; // Başlangıç gecikmesi

  TankBubble({
    required this.startX,
    required this.size,
    required this.speed,
    required this.delay,
  });
}

/// Widget that displays the tank visualization with water, waves, and bubbles.
class TankVisualization extends StatelessWidget {
  final double fillPercentage;
  final Animation<double> fillAnimation;
  final AnimationController bubbleController;
  final AnimationController waveController;
  final List<TankBubble> bubbles;

  const TankVisualization({
    super.key,
    required this.fillPercentage,
    required this.fillAnimation,
    required this.bubbleController,
    required this.waveController,
    required this.bubbles,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassFishBowl(
        size: AppConstants.tankSize,
        child: RepaintBoundary(
          child: SizedBox(
            width: AppConstants.tankSize,
            height: AppConstants.tankSize,
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.antiAlias,
              children: [
                // Arka plan (şeffaf - su görünür olmalı)
                Container(
                  width: AppConstants.tankSize,
                  height: AppConstants.tankSize,
                  color: Colors.transparent,
                ),
                // Su doluluk animasyonu
                AnimatedBuilder(
                  animation: Listenable.merge([
                    fillAnimation,
                    bubbleController,
                    waveController,
                  ]),
                  builder: (context, child) {
                    final currentFill = fillPercentage.clamp(0.0, 1.0);
                    final waterHeight = AppConstants.tankSize * currentFill;
                    final waterTop = AppConstants.tankSize - waterHeight;

                    return SizedBox(
                      width: AppConstants.tankSize,
                      height: AppConstants.tankSize,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        clipBehavior: Clip.antiAlias,
                        children: [
                          // Ana su katmanı
                          if (waterHeight > 0)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: waterHeight,
                              child: Container(
                                color: AppConstants.waterColorPrimary,
                              ),
                            ),

                          // Wave efekti
                          if (currentFill > AppConstants.minFillForWave &&
                              waterHeight > AppConstants.minWaterHeightForWave)
                            Positioned(
                              bottom: waterHeight - (AppConstants.waveHeight / 2),
                              left: 0,
                              right: 0,
                              height: AppConstants.waveHeight,
                              child: ClipRect(
                                child: ClipOval(
                                  child: WaveWidget(
                                    config: CustomConfig(
                                      gradients: [
                                        [
                                          AppConstants.waterColorPrimary
                                              .withValues(alpha: AppConstants.waveAlpha1),
                                          AppConstants.waterColorSecondary
                                              .withValues(alpha: AppConstants.waveAlpha2),
                                        ],
                                        [
                                          AppConstants.waterColorPrimary
                                              .withValues(alpha: AppConstants.waveAlpha3),
                                          AppConstants.waterColorSecondary
                                              .withValues(alpha: AppConstants.waveAlpha4),
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
                                    waveAmplitude: AppConstants.waveAmplitude,
                                    waveFrequency: AppConstants.waveFrequency,
                                    backgroundColor: Colors.transparent,
                                    size: Size(
                                      AppConstants.tankSize,
                                      AppConstants.waveHeight,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Yükselen kabarcıklar
                          if (waterHeight > 0)
                            ...bubbles.map((bubble) {
                              final bubbleProgress = ((bubbleController.value * 2 +
                                          bubble.delay) %
                                      2) /
                                  2;
                              final bubbleY = AppConstants.tankSize -
                                  (bubbleProgress *
                                      waterHeight *
                                      AppConstants.bubbleProgressMultiplier);

                              if (bubbleY > waterTop &&
                                  bubbleY < AppConstants.tankSize &&
                                  waterHeight > AppConstants.minWaterHeightForBubbles) {
                                final bubbleX = bubble.startX * AppConstants.tankSize;
                                return Positioned(
                                  left: bubbleX - bubble.size / 2,
                                  bottom: AppConstants.tankSize - bubbleY - bubble.size / 2,
                                  child: Opacity(
                                    opacity: math.max(
                                      0,
                                      1 - bubbleProgress * AppConstants.bubbleOpacityFadeMultiplier,
                                    ),
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
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

