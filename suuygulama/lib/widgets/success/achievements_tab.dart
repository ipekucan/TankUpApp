import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/achievement_provider.dart';
import '../../models/achievement_model.dart';

/// Minimalist Achievements Tab - Apple Fitness Awards style
/// Clean white background with floating trophy icons
class AchievementsTab extends StatelessWidget {
  const AchievementsTab({super.key});

  // Achievement data with emoji mapping
  static const Map<String, Map<String, String>> _achievementData = {
    'first_cup': {'emoji': '💧', 'goal': 'İlk suyunu iç'},
    'first_step': {'emoji': '💧', 'goal': 'İlk su içişini tamamla'},
    'first_litre': {'emoji': '🌊', 'goal': '1 litre su iç'},
    'daily_goal': {'emoji': '🎯', 'goal': 'Günlük su hedefine ulaş'},
    'water_master': {'emoji': '👑', 'goal': 'Toplamda 10 litre su iç'},
    'streak_3': {'emoji': '🔥', 'goal': '3 gün üst üste hedefe ulaş'},
    'streak_7': {'emoji': '⭐', 'goal': '7 gün üst üste hedefe ulaş'},
    'fish_champion': {'emoji': '🐠', 'goal': 'Balık karakterini kazan'},
  };

  /// Gets emoji for achievement
  String _getEmoji(String achievementId) {
    return _achievementData[achievementId]?['emoji'] ?? '🏆';
  }

  /// Gets goal text for achievement
  String _getGoal(String achievementId) {
    return _achievementData[achievementId]?['goal'] ?? '';
  }

  /// Gets icon color for glow effect based on achievement type
  Color _getIconColor(String achievementId) {
    // Return different colors based on achievement category
    if (achievementId.contains('water') || achievementId.contains('cup') || achievementId.contains('litre')) {
      return const Color(0xFF00BCD4); // Aqua blue for water achievements
    } else if (achievementId.contains('streak') || achievementId.contains('goal')) {
      return const Color(0xFFFF6B6B); // Coral for streaks/goals
    } else if (achievementId.contains('master') || achievementId.contains('champion')) {
      return const Color(0xFFFFD700); // Gold for master achievements
    }
    return const Color(0xFF2B5876); // Default blue
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AchievementProvider>(
      builder: (context, achievementProvider, child) {
        final allAchievements = achievementProvider.achievements;

        return Container(
          color: Colors.white,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: allAchievements.length,
            itemBuilder: (context, index) {
              final achievement = allAchievements[index];
              return _MinimalistTrophyItem(
                achievement: achievement,
                emoji: _getEmoji(achievement.id),
                goal: _getGoal(achievement.id),
                iconColor: _getIconColor(achievement.id),
                onTap: () => _showAchievementDetail(context, achievement),
              );
            },
          ),
        );
      },
    );
  }

  /// Shows achievement detail in a bottom sheet
  void _showAchievementDetail(BuildContext context, Achievement achievement) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              _getEmoji(achievement.id),
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              achievement.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              achievement.isUnlocked
                  ? (achievement.description.isNotEmpty
                      ? achievement.description
                      : 'Başarıyı kazandın!')
                  : 'Kilidi açmak için: ${_getGoal(achievement.id)}',
              style: TextStyle(
                fontSize: 16,
                color: achievement.isUnlocked ? Colors.grey[600] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            if (achievement.isUnlocked && achievement.coinReward > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${achievement.coinReward} Coin',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Minimalist Trophy Item - Compact card design
class _MinimalistTrophyItem extends StatelessWidget {
  final Achievement achievement;
  final String emoji;
  final String goal;
  final Color iconColor;
  final VoidCallback onTap;

  const _MinimalistTrophyItem({
    required this.achievement,
    required this.emoji,
    required this.goal,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // The Icon (Hero) - With glow effect
            Stack(
              alignment: Alignment.center,
              children: [
                // Glow effect (only for unlocked)
                if (isUnlocked)
                  Container(
                    width: 48.0,
                    height: 48.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                
                // Main emoji/icon
                Text(
                  emoji,
                  style: TextStyle(
                    fontSize: 48.0,
                    color: isUnlocked ? null : Colors.grey.withOpacity(0.2),
                  ),
                ),
                
                // Lock icon overlay (for locked achievements)
                if (!isUnlocked)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock,
                        size: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Spacing
            const SizedBox(height: 8),
            
            // Title
            Text(
              achievement.name,
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? Colors.black : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Description
            const SizedBox(height: 4),
            Text(
              achievement.description.isNotEmpty
                  ? achievement.description
                  : goal,
              style: const TextStyle(
                fontSize: 10.0,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
