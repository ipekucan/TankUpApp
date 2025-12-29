import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/achievement_provider.dart';
import '../../models/achievement_model.dart';
import '../../utils/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_card.dart';

/// Achievements tab content for SuccessScreen.
class AchievementsTab extends StatelessWidget {
  const AchievementsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AchievementProvider>(
      builder: (context, achievementProvider, child) {
        final achievements = achievementProvider.achievements;

        final defaultAchievements = [
          {'id': 'first_cup', 'name': 'İlk Bardak', 'emoji': '💧', 'goal': 'İlk suyunu iç'},
          {'id': 'first_step', 'name': 'İlk Su', 'emoji': '💧', 'goal': 'İlk su içişini tamamla'},
          {'id': 'first_litre', 'name': 'İlk Litre', 'emoji': '🌊', 'goal': '1 litre su iç'},
          {'id': 'fish_champion', 'name': 'Balık Şampiyonu', 'emoji': '🐠', 'goal': 'Balık karakterini kazan'},
          {'id': 'daily_goal', 'name': 'Günlük Hedef', 'emoji': '🎯', 'goal': 'Günlük su hedefine ulaş'},
          {'id': 'streak_3', 'name': '3 Gün Seri', 'emoji': '🔥', 'goal': '3 gün üst üste hedefe ulaş'},
          {'id': 'streak_7', 'name': '7 Gün Seri', 'emoji': '⭐', 'goal': '7 gün üst üste hedefe ulaş'},
          {'id': 'water_master', 'name': 'Su Ustası', 'emoji': '👑', 'goal': 'Toplamda 10 litre su iç'},
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              ...defaultAchievements.map((defaultAchievement) {
                final achievement = achievements.firstWhere(
                  (a) => a.id == defaultAchievement['id'],
                  orElse: () => Achievement(
                    id: defaultAchievement['id'] as String,
                    name: defaultAchievement['name'] as String,
                    description: '',
                    coinReward: 0,
                  ),
                );

                final isUnlocked = achievement.isUnlocked;
                final goalText = defaultAchievement['goal'] ?? '';

                Widget achievementCard = AppCard(
                  padding: const EdgeInsets.all(AppConstants.mediumSpacing),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? AppColors.softPinkButton.withValues(alpha: 0.15)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(AppConstants.defaultSpacing),
                        ),
                        child: Center(
                          child: Text(
                            defaultAchievement['emoji'] as String,
                            style: const TextStyle(fontSize: 28),
                          ),
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
                                    achievement.name,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isUnlocked
                                          ? AppColors.textPrimary
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                                if (isUnlocked)
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                              ],
                            ),
                            SizedBox(height: AppConstants.smallSpacing),
                            Text(
                              isUnlocked
                                  ? (achievement.description.isNotEmpty
                                      ? achievement.description
                                      : 'Başarıyı kazandın!')
                                  : 'Kilidi açmak için: $goalText',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isUnlocked
                                    ? Colors.grey[600]
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      isUnlocked
                          ? const Text('✅', style: TextStyle(fontSize: 24))
                          : const Text('🔒', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                );

                if (!isUnlocked) {
                  return Opacity(
                    opacity: 0.5,
                    child: achievementCard,
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppConstants.defaultSpacing),
                  child: achievementCard,
                );
              }),

              SizedBox(height: AppConstants.largePadding),

              _FutureGoals(),
            ],
          ),
        );
      },
    );
  }
}

/// Future goals section widget.
class _FutureGoals extends StatelessWidget {
  final futureGoals = [
    {'name': 'Okyanus Kaşifi', 'emoji': '🌊', 'description': '10 gün üst üste hedefe ulaş'},
    {'name': 'Şekersiz Şövalye', 'emoji': '🛡️', 'description': '1 ay şekersiz içecek tüketme'},
    {'name': 'Hidrasyon Ustası', 'emoji': '💎', 'description': 'Toplamda 100 litre su iç'},
    {'name': 'Gece Koruyucusu', 'emoji': '🌙', 'description': '30 gün gece sadece su iç'},
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sıradaki Adımların',
            style: AppTextStyles.heading2.copyWith(
              fontSize: AppConstants.extraLargeFontSize,
            ),
          ),
          SizedBox(height: AppConstants.mediumSpacing),
          ...futureGoals.map((goal) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.defaultSpacing),
              child: Row(
                children: [
                  Text(
                    goal['emoji'] as String,
                    style: const TextStyle(fontSize: 32),
                  ),
                  SizedBox(width: AppConstants.defaultSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal['name'] as String,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          goal['description'] as String,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

