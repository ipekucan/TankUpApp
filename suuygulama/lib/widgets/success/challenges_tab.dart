import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/water_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/challenge_card.dart';
import '../../widgets/empty_challenge_card.dart';
import '../../utils/challenge_logic_helper.dart';
import '../../core/constants/app_constants.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_card.dart';

/// Challenges tab content for SuccessScreen.
class ChallengesTab extends StatelessWidget {
  const ChallengesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ChallengeProvider, WaterProvider, UserProvider>(
      builder: (context, challengeProvider, waterProvider, userProvider, child) {
        // Get only active challenges with calculated progress from centralized helper
        // This ensures we only show challenges that are actually started
        final activeChallenges = ChallengeLogicHelper.getActiveChallengesWithProgress(
          waterProvider,
          userProvider,
          challengeProvider,
        );
        final now = DateTime.now();
        final isBefore3PM = now.hour < 15;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BÖLÜM 1: GÜNLÜK GÖREV KARTI (Daily Quest Header)
              AppCard(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFB3E5FC),
                        Color(0xFF29B6F6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.card_giftcard,
                          color: Color(0xFFE91E63),
                          size: 32,
                        ),
                        const SizedBox(width: AppConstants.mediumSpacing),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Günün Görevi',
                                style: AppTextStyles.heading3.copyWith(
                                  color: const Color(0xFF01579B),
                                  fontSize: AppConstants.largeFontSize,
                                ),
                              ),
                              const SizedBox(height: AppConstants.smallSpacing),
                              Text(
                                isBefore3PM
                                    ? '15:00\'dan önce 1.5 Litre su iç!'
                                    : 'Bugün 1.5 Litre su iç!',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: const Color(0xFF01579B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.monetization_on,
                              color: Colors.amber,
                              size: 28,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '+50 Coin',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: const Color(0xFF01579B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: AppConstants.largePadding),

              // BÖLÜM 2: AKTİF MÜCADELE (My Active Challenge)
              if (activeChallenges.isNotEmpty) ...[
                Text(
                  'Devam Eden Mücadelen',
                  style: AppTextStyles.heading3.copyWith(
                    fontSize: AppConstants.extraLargeFontSize,
                  ),
                ),
                SizedBox(height: AppConstants.defaultSpacing),
                _ActiveChallengeStatusCard(challenge: activeChallenges.first),
                SizedBox(height: AppConstants.mediumSpacing),
                EmptyChallengeSlot(
                  onTap: () {
                    _showDiscoverChallengesModal(context, challengeProvider);
                  },
                ),
                SizedBox(height: AppConstants.largePadding),
              ] else ...[
                Text(
                  'Devam Eden Mücadelen',
                  style: AppTextStyles.heading3.copyWith(
                    fontSize: AppConstants.extraLargeFontSize,
                  ),
                ),
                SizedBox(height: AppConstants.defaultSpacing),
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.largePadding),
                    child: Center(
                      child: Text(
                        'Henüz aktif mücadele yok',
                        style: AppTextStyles.bodyGrey.copyWith(
                          fontSize: AppConstants.mediumSpacing,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppConstants.largePadding),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showDiscoverChallengesModal(
    BuildContext context,
    ChallengeProvider challengeProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer3<ChallengeProvider, WaterProvider, UserProvider>(
        builder: (context, currentChallengeProvider, waterProvider, userProvider, child) {
          // Get all challenges (excluding first_cup)
          final allChallenges = ChallengeData.getChallenges()
              .where((challenge) => challenge.id != 'first_cup')
              .toList();
          
          // Get active challenge IDs (both active and completed)
          final activeChallengeIds = currentChallengeProvider.activeChallenges
              .map((c) => c.id)
              .toSet();
          
          // Calculate states for all challenges
          final allChallengesWithState = allChallenges.map((challenge) {
            return ChallengeLogicHelper.calculateChallengeState(
              challenge,
              waterProvider,
              userProvider,
              currentChallengeProvider,
            );
          }).toList();
          
          // Separate into available (not started) and started (active or completed)
          final availableChallenges = allChallengesWithState
              .where((challenge) => !activeChallengeIds.contains(challenge.id))
              .toList();
          
          final startedChallenges = allChallengesWithState
              .where((challenge) => activeChallengeIds.contains(challenge.id))
              .toList();
          
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppConstants.largeBorderRadius),
                topRight: Radius.circular(AppConstants.largeBorderRadius),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Yeni Mücadeleler Keşfet',
                        style: AppTextStyles.heading2,
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.defaultPadding,
                    ),
                    child: Column(
                      children: [
                        // Başlatılmamış mücadeleler (Yeni başlatılabilir)
                        ...availableChallenges.map((challenge) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppConstants.challengeCardBottomPadding,
                              ),
                              child: ChallengeCard(
                                challenge: challenge,
                                onTap: () async {
                                  await currentChallengeProvider.startChallenge(challenge.id);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                            )),
                        // Başlatılmış mücadeleler (Aktif veya Tamamlanmış)
                        ...startedChallenges.map((challenge) => Opacity(
                              opacity: challenge.isCompleted
                                  ? AppConstants.challengeCompletedOpacity
                                  : 1.0,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppConstants.challengeCardBottomPadding,
                                ),
                                child: ChallengeCard(
                                  challenge: challenge,
                                  onTap: challenge.isCompleted
                                      ? null
                                      : () {
                                          // Active challenge - could show details or do nothing
                                        },
                                ),
                              ),
                            )),
                        SizedBox(height: AppConstants.extraLargeSpacing),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Active challenge status card widget.
class _ActiveChallengeStatusCard extends StatelessWidget {
  final Challenge challenge;

  const _ActiveChallengeStatusCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final progressPercentage = (challenge.progress * 100).toInt();
    final progressText = challenge.progressText.isNotEmpty
        ? challenge.progressText
        : '${challenge.currentProgress.toStringAsFixed(1)} / ${challenge.targetValue.toStringAsFixed(1)}';

    return AppCard(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.teal.withValues(alpha: 0.15),
              Colors.cyan.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          border: Border.all(
            color: Colors.teal.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppConstants.defaultSpacing),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppConstants.defaultSpacing),
                    ),
                    child: Icon(
                      challenge.icon,
                      color: Colors.teal[700],
                      size: 32,
                    ),
                  ),
                  SizedBox(width: AppConstants.mediumSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                challenge.name,
                                style: AppTextStyles.heading3,
                              ),
                            ),
                            SizedBox(width: AppConstants.mediumSpacing),
                            InkWell(
                              onTap: () => _showChallengeInfoDialog(context, challenge),
                              borderRadius: BorderRadius.circular(AppConstants.defaultSpacing),
                              child: Icon(
                                Icons.info_outline,
                                size: 22,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppConstants.smallSpacing),
                        Text(
                          progressText,
                          style: AppTextStyles.bodyGrey,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppConstants.mediumSpacing),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.mediumSpacing),
                child: LinearProgressIndicator(
                  value: challenge.progress.clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: Colors.teal.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal[700]!),
                ),
              ),
              SizedBox(height: AppConstants.mediumSpacing),
              Text(
                '$progressPercentage%',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChallengeInfoDialog(BuildContext context, Challenge challenge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        title: Text(
          challenge.name,
          style: AppTextStyles.heading2,
        ),
        content: Text(
          challenge.description,
          style: AppTextStyles.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.teal[700],
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.largePadding,
                vertical: AppConstants.defaultSpacing,
              ),
            ),
            child: Text(
              'Tamam',
              style: AppTextStyles.buttonText,
            ),
          ),
        ],
      ),
    );
  }
}

