import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/achievement_provider.dart';
import '../../../models/achievement_model.dart';
import '../../../utils/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Minimalist Trophy Room - Achievements Screen
/// Clean, Apple Fitness Awards style design
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  // Emoji mapping for achievements
  static const Map<String, String> _achievementEmojis = {
    'first_cup': '💧',
    'first_step': '💧',
    'daily_goal': '🎯',
    'streak_3': '🔥',
    'water_master': '👑',
    'streak_7': '⭐',
    'first_litre': '🌊',
    'fish_champion': '🐠',
  };

  String _getEmoji(String achievementId) {
    return _achievementEmojis[achievementId] ?? '🏆';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Başarılarım',
          style: AppTextStyles.appBarTitle.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Consumer<AchievementProvider>(
        builder: (context, achievementProvider, child) {
          final achievements = achievementProvider.achievements;
          
          // Use achievements from provider
          final displayAchievements = achievements;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final achievement = displayAchievements[index];
                      return _TrophyItem(
                        achievement: achievement,
                        emoji: _getEmoji(achievement.id),
                      );
                    },
                    childCount: displayAchievements.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

}

/// Minimalist Trophy Item Widget
class _TrophyItem extends StatelessWidget {
  final Achievement achievement;
  final String emoji;

  const _TrophyItem({
    required this.achievement,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large Icon (80px) with conditional styling
          Stack(
            alignment: Alignment.center,
            children: [
              // Main emoji/icon
              Opacity(
                opacity: isUnlocked ? 1.0 : 0.4,
                child: Text(
                  emoji,
                  style: TextStyle(
                    fontSize: 80,
                    color: isUnlocked ? null : Colors.grey[400],
                  ),
                ),
              ),
              // Lock overlay for locked achievements
              if (!isUnlocked)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.lock,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              // Glow effect for unlocked achievements
              if (isUnlocked)
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getGlowColor(achievement.id).withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Title (Bold, Black)
          Text(
            achievement.name,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          // Description (Small, Grey)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              achievement.description,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey[600],
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getGlowColor(String achievementId) {
    // Different glow colors based on achievement type
    switch (achievementId) {
      case 'streak_7':
      case 'water_master':
        return AppColors.goldCoin; // Gold for high-tier
      case 'streak_3':
        return AppColors.accentCoral; // Red/Orange for streaks
      case 'daily_goal':
        return AppColors.primaryBlue; // Blue for goals
      default:
        return AppColors.secondaryAqua; // Aqua for basic
    }
  }
}
