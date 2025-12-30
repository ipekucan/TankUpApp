import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/water_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../widgets/challenge_card.dart';
import '../../utils/challenge_logic_helper.dart';
import '../../core/constants/app_constants.dart';
import '../../theme/app_text_styles.dart';

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
              // Scrollable içerik
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: AppConstants.challengePanelContentPadding,
                  child: Builder(
                    builder: (context) {
                      final waterProvider = Provider.of<WaterProvider>(context, listen: false);
                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                      final achievementProvider =
                          Provider.of<AchievementProvider>(context, listen: false);
                      final challengeProvider =
                          Provider.of<ChallengeProvider>(context, listen: false);
                      return _buildDailyChallengesContent(
                        waterProvider,
                        userProvider,
                        achievementProvider,
                        challengeProvider,
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

  Widget _buildDailyChallengesContent(
    WaterProvider waterProvider,
    UserProvider userProvider,
    AchievementProvider achievementProvider,
    ChallengeProvider challengeProvider,
  ) {
    // CRITICAL: "Calculate First, Separate Later" approach
    // This prevents challenges from disappearing into a "limbo" state
    
    // 1. Get all challenges from provider (both active and completed)
    final providerChallenges = challengeProvider.activeChallenges;
    
    // 2. Calculate state for ALL challenges FIRST
    // This ensures we have the final, calculated state before filtering
    final allCalculatedChallenges = providerChallenges.map((challenge) {
      // Get base challenge data from ChallengeData
      final baseChallenge = ChallengeData.getChallenges()
          .firstWhere((c) => c.id == challenge.id, orElse: () => challenge);
      
      // Calculate the final state (progress, isCompleted, etc.)
      return ChallengeLogicHelper.calculateChallengeState(
        baseChallenge,
        waterProvider,
        userProvider,
        challengeProvider,
      );
    }).toList();
    
    // 3. NOW separate into active and completed based on CALCULATED state
    // This ensures every challenge lands in exactly one list
    final activeChallenges = allCalculatedChallenges
        .where((challenge) => !challenge.isCompleted)
        .toList();
    
    final completedChallenges = allCalculatedChallenges
        .where((challenge) => challenge.isCompleted == true)
        .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: AppConstants.challengeTitleTopPadding,
              bottom: AppConstants.challengeTitleBottomPadding,
            ),
            child: Text(
              'Mücadele Kartları',
              style: AppTextStyles.heading3.copyWith(
                fontSize: AppConstants.challengeTitleFontSize,
                color: const Color(0xFF4A5568),
              ),
            ),
          ),

          // Aktif Görevler Başlığı (Varsa)
          if (activeChallenges.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.only(
                bottom: AppConstants.challengeSectionTitleBottomPadding,
              ),
              child: Text(
                'Aktif Görevler',
                style: AppTextStyles.heading3.copyWith(
                  fontSize: AppConstants.challengeSectionTitleFontSize,
                  color: const Color(0xFF4A5568),
                ),
              ),
            ),
            // Aktif Liste: Tamamlanmamışları buraya diz
            ...activeChallenges.map((challenge) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppConstants.challengeCardBottomPadding,
                  ),
                  child: ChallengeCard(
                    challenge: challenge,
                  ),
                )),
          ],

          // Ayırıcı (Eğer hem aktif hem tamamlanan varsa)
          if (activeChallenges.isNotEmpty && completedChallenges.isNotEmpty) ...[
            SizedBox(height: AppConstants.challengeSectionDividerHeight),
            const Divider(color: Colors.grey),
            SizedBox(height: AppConstants.challengeSectionDividerHeight),
          ],

          // Tamamlananlar Başlığı
          if (completedChallenges.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.only(
                bottom: AppConstants.challengeSectionTitleBottomPadding,
              ),
              child: Text(
                'Tamamlananlar',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: AppConstants.challengeCompletedSectionTitleFontSize,
                  color: Colors.grey,
                ),
              ),
            ),
            // Tamamlanan Liste: Tamamlanmışları buraya diz (Opacity ile)
            ...completedChallenges.map((challenge) => Opacity(
                  opacity: AppConstants.challengeCompletedOpacity,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppConstants.challengeCardBottomPadding,
                    ),
                    child: ChallengeCard(
                      challenge: challenge,
                    ),
                  ),
                )),
          ],

          SizedBox(height: AppConstants.extraLargeSpacing),
        ],
      ),
    );
  }
}

