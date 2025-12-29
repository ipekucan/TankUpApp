import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/water_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../widgets/challenge_card.dart';
import '../../utils/unit_converter.dart';
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
                      return _buildDailyChallengesContent(
                        waterProvider,
                        userProvider,
                        achievementProvider,
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
  ) {
    // 1. Tüm mücadeleleri al ve durumlarını hesapla
    final allChallenges = ChallengeData.getChallenges()
        .where((challenge) => challenge.id != 'first_cup')
        .map((challenge) {
      Challenge updatedChallenge = challenge;

      if (challenge.id == 'deep_dive') {
        // Derin Dalış: 3 gün üst üste %100 su hedefi
        final isCompleted = userProvider.consecutiveDays >= 3 &&
            waterProvider.hasReachedDailyGoal;
        updatedChallenge = Challenge(
          id: challenge.id,
          name: challenge.name,
          description: challenge.description,
          coinReward: challenge.coinReward,
          cardColor: challenge.cardColor,
          icon: challenge.icon,
          whyStart: challenge.whyStart,
          healthBenefit: challenge.healthBenefit,
          badgeEmoji: challenge.badgeEmoji,
          isCompleted: isCompleted,
          progress: (userProvider.consecutiveDays / 3).clamp(0.0, 1.0),
          progressText: '${userProvider.consecutiveDays}/3 gün',
        );
      } else if (challenge.id == 'coral_guardian') {
        // Mercan Koruyucu: Akşam 8'den sonra sadece su (basitleştirilmiş - bugün su hedefi)
        final isCompleted = waterProvider.hasReachedDailyGoal;
        updatedChallenge = Challenge(
          id: challenge.id,
          name: challenge.name,
          description: challenge.description,
          coinReward: challenge.coinReward,
          cardColor: challenge.cardColor,
          icon: challenge.icon,
          whyStart: challenge.whyStart,
          healthBenefit: challenge.healthBenefit,
          badgeEmoji: challenge.badgeEmoji,
          isCompleted: isCompleted,
          progress: (waterProvider.consumedAmount / waterProvider.dailyGoal).clamp(0.0, 1.0),
          progressText:
              '${UnitConverter.formatVolume(waterProvider.consumedAmount, userProvider.isMetric)}/${UnitConverter.formatVolume(waterProvider.dailyGoal, userProvider.isMetric)}',
        );
      }

      return updatedChallenge;
    }).toList();

    // 2. Aktif ve tamamlanan mücadeleleri ayrı ayrı filtrele
    final activeChallenges = allChallenges.where((c) => !c.isCompleted).toList();
    final completedChallenges = allChallenges.where((c) => c.isCompleted).toList();

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

