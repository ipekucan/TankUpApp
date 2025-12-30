import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/water_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../utils/challenge_logic_helper.dart';
import '../../core/constants/app_constants.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/challenge_card.dart';
import '../../features/challenges/challenge_map_widget.dart';
import '../../features/challenges/challenge_control_panel.dart';

/// Widget that displays the draggable challenge panel with challenge cards.
class ChallengePanel extends StatelessWidget {
  final DraggableScrollableController controller;

  const ChallengePanel({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: AppConstants.challengeSheetInitialSize,
      minChildSize: AppConstants.challengeSheetMinSize,
      maxChildSize: AppConstants.challengeSheetMaxSize,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.mediumBorderRadius),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: AppConstants.defaultShadowAlpha),
                blurRadius: AppConstants.largeShadowBlur,
                offset: AppConstants.largeShadowOffset,
              ),
            ],
          ),
          child: Column(
            children: [
              // Tutma çizgisi
              Container(
                margin: EdgeInsets.only(
                  top: AppConstants.challengePanelHandleTopMargin,
                  bottom: AppConstants.challengePanelHandleBottomMargin,
                ),
                width: AppConstants.challengePanelHandleWidth,
                height: AppConstants.challengePanelHandleHeight,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(
                    AppConstants.challengePanelHandleBorderRadius,
                  ),
                ),
              ),
              // Gamified Map Content with Control Panel
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: AppConstants.challengePanelContentPadding,
                  child: Builder(
                    builder: (context) {
                      return Consumer4<WaterProvider, UserProvider, AchievementProvider,
                          ChallengeProvider>(
                        builder: (context, waterProvider, userProvider, achievementProvider,
                            challengeProvider, child) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildGamifiedMapContent(
                                waterProvider,
                                userProvider,
                                achievementProvider,
                                challengeProvider,
                              ),
                              
                              // Control Panel (Inside scrollable area)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppConstants.largeSpacing,
                                  bottom: AppConstants.defaultPadding,
                                ),
                                child: ChallengeControlPanel(
                                  isActive: challengeProvider.activeIncompleteChallenges.isEmpty,
                                  onStartPressed: () {
                                    // Challenge start logic will be implemented later
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build the gamified map content with S-shaped path and nodes.
  Widget _buildGamifiedMapContent(
    WaterProvider waterProvider,
    UserProvider userProvider,
    AchievementProvider achievementProvider,
    ChallengeProvider challengeProvider,
  ) {
    // Get daily challenges (only daily tasks for the map)
    final providerChallenges = challengeProvider.activeChallenges;
    
    // Calculate completed days (challenges that are completed)
    final completedChallenges = providerChallenges
        .map((challenge) {
          final baseChallenge = ChallengeData.getChallenges()
              .firstWhere((c) => c.id == challenge.id, orElse: () => challenge);
          return ChallengeLogicHelper.calculateChallengeState(
            baseChallenge,
            waterProvider,
            userProvider,
            challengeProvider,
          );
        })
        .where((challenge) => challenge.isCompleted)
        .toList();
    
    // For now, we'll show a 7-day map (can be extended)
    const totalDays = 7;
    final completedDays = completedChallenges.length.clamp(0, totalDays);
    
    // Prepare daily challenge data (simplified for now)
    final dailyChallenges = List.generate(totalDays, (index) {
      return {
        'day': index + 1,
        'completed': index < completedDays,
      };
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: AppConstants.challengeTitleTopPadding,
            bottom: AppConstants.challengeTitleBottomPadding,
          ),
          child: Text(
            'Günlük Mücadele Yolu',
            style: AppTextStyles.heading3.copyWith(
              fontSize: AppConstants.challengeTitleFontSize,
              color: const Color(0xFF4A5568),
            ),
          ),
        ),
        
        // Gamified Map
        LayoutBuilder(
          builder: (context, constraints) {
            // Use available width, calculate height based on number of days
            final mapHeight = (totalDays * 60.0).clamp(300.0, 450.0);
            return SizedBox(
              height: mapHeight,
              child: ChallengeMapWidget(
                totalDays: totalDays,
                completedDays: completedDays,
                dailyChallenges: dailyChallenges,
              ),
            );
          },
        ),
      ],
    );
  }
}

