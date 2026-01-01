import '../models/achievement_model.dart';
import '../providers/water_provider.dart';
import '../providers/user_provider.dart';

/// Centralized achievement data and progress calculation helper.
/// Consolidates all achievement metadata (ID, Name, Description, Target, Icon, Category)
/// and calculates progress before UI rendering.
class AchievementDataHelper {
  AchievementDataHelper._(); // Private constructor

  /// Achievement categories
  static const String categoryHydration = 'Hidrasyon';
  static const String categoryStreak = 'Seri';
  static const String categoryCollector = 'Koleksiyoncu';

  /// Achievement metadata structure
  static const Map<String, AchievementMetadata> _achievementMetadata = {
    'first_cup': AchievementMetadata(
      id: 'first_cup',
      name: 'İlk Bardak',
      description: 'Uygulamadaki ilk suyunu iç ve macerayı başlat!',
      emoji: '💧',
      category: categoryHydration,
      targetType: AchievementTargetType.firstDrink,
    ),
    'first_step': AchievementMetadata(
      id: 'first_step',
      name: 'İlk Adım',
      description: 'İlk su içişini tamamla',
      emoji: '🚀',
      category: categoryHydration,
      targetType: AchievementTargetType.firstDrink,
    ),
    'daily_goal': AchievementMetadata(
      id: 'daily_goal',
      name: 'Günlük Hedef',
      description: 'Günlük su hedefine ulaş',
      emoji: '🎯',
      category: categoryHydration,
      targetType: AchievementTargetType.dailyGoal,
    ),
    'first_litre': AchievementMetadata(
      id: 'first_litre',
      name: 'İlk Litre',
      description: '1 litre su iç',
      emoji: '🌊',
      category: categoryHydration,
      targetType: AchievementTargetType.totalWater,
      targetValue: 1000.0, // 1 litre in ml
    ),
    'water_master': AchievementMetadata(
      id: 'water_master',
      name: 'Su Ustası',
      description: 'Toplamda 10 litre su iç',
      emoji: '👑',
      category: categoryHydration,
      targetType: AchievementTargetType.totalWater,
      targetValue: 10000.0, // 10 litre in ml
    ),
    'streak_3': AchievementMetadata(
      id: 'streak_3',
      name: 'Seri Başlangıcı',
      description: '3 gün üst üste hedefe ulaş',
      emoji: '🔥',
      category: categoryStreak,
      targetType: AchievementTargetType.streak,
      targetValue: 3.0,
    ),
    'streak_7': AchievementMetadata(
      id: 'streak_7',
      name: 'Haftalık Şampiyon',
      description: '7 gün üst üste hedefe ulaş',
      emoji: '⭐',
      category: categoryStreak,
      targetType: AchievementTargetType.streak,
      targetValue: 7.0,
    ),
    'streak_30': AchievementMetadata(
      id: 'streak_30',
      name: 'Aylık Efsane',
      description: '30 gün üst üste hedefe ulaş',
      emoji: '🏆',
      category: categoryStreak,
      targetType: AchievementTargetType.streak,
      targetValue: 30.0,
    ),
  };

  /// Get all achievement metadata
  static List<AchievementMetadata> getAllMetadata() {
    return _achievementMetadata.values.toList();
  }

  /// Get metadata for a specific achievement ID
  static AchievementMetadata? getMetadata(String achievementId) {
    return _achievementMetadata[achievementId];
  }

  /// Get achievements by category
  static List<AchievementMetadata> getByCategory(String category) {
    return _achievementMetadata.values
        .where((meta) => meta.category == category)
        .toList();
  }

  /// Calculate progress for an achievement
  static AchievementProgress calculateProgress(
    Achievement achievement,
    WaterProvider? waterProvider,
    UserProvider? userProvider,
  ) {
    final metadata = getMetadata(achievement.id);
    if (metadata == null) {
      return AchievementProgress(
        current: 0.0,
        target: 1.0,
        percentage: 0.0,
        isCompleted: achievement.isUnlocked,
      );
    }

    double current = 0.0;
    double target = metadata.targetValue ?? 1.0;
    bool isCompleted = achievement.isUnlocked;

    switch (metadata.targetType) {
      case AchievementTargetType.firstDrink:
        // First drink achievements are binary (0 or 1)
        current = achievement.isUnlocked ? 1.0 : 0.0;
        target = 1.0;
        break;

      case AchievementTargetType.dailyGoal:
        if (waterProvider != null) {
          current = waterProvider.consumedAmount;
          target = waterProvider.dailyGoal;
          isCompleted = waterProvider.hasReachedDailyGoal || achievement.isUnlocked;
        }
        break;

      case AchievementTargetType.totalWater:
        if (userProvider != null) {
          current = userProvider.userData.totalWaterConsumed;
          target = metadata.targetValue ?? 10000.0;
          isCompleted = current >= target || achievement.isUnlocked;
        }
        break;

      case AchievementTargetType.streak:
        if (userProvider != null) {
          current = userProvider.consecutiveDays.toDouble();
          target = metadata.targetValue ?? 7.0;
          isCompleted = current >= target || achievement.isUnlocked;
        }
        break;
    }

    final percentage = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return AchievementProgress(
      current: current,
      target: target,
      percentage: percentage,
      isCompleted: isCompleted,
    );
  }

  /// Get the next immediate goal (first locked achievement)
  static AchievementMetadata? getNextMilestone(
    List<Achievement> achievements,
  ) {
    for (final achievement in achievements) {
      if (!achievement.isUnlocked) {
        return getMetadata(achievement.id);
      }
    }
    return null;
  }

  /// Get all categories
  static List<String> getCategories() {
    return [
      categoryHydration,
      categoryStreak,
      categoryCollector,
    ];
  }
}

/// Achievement metadata structure
class AchievementMetadata {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final String category;
  final AchievementTargetType targetType;
  final double? targetValue;

  const AchievementMetadata({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.category,
    required this.targetType,
    this.targetValue,
  });
}

/// Achievement target types
enum AchievementTargetType {
  firstDrink,
  dailyGoal,
  totalWater,
  streak,
}

/// Achievement progress data
class AchievementProgress {
  final double current;
  final double target;
  final double percentage;
  final bool isCompleted;

  AchievementProgress({
    required this.current,
    required this.target,
    required this.percentage,
    required this.isCompleted,
  });
}
