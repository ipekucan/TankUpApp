import '../widgets/challenge_card.dart';
import '../providers/daily_hydration_provider.dart';
import '../providers/user_provider.dart';
import '../providers/challenge_provider.dart';
import '../utils/unit_converter.dart';

/// Centralized helper for calculating dynamic challenge states.
/// This ensures all screens (TankScreen, ChallengePanel, ChallengesTab) 
/// show consistent, real-time progress calculations.
class ChallengeLogicHelper {
  /// Calculates the live state of a challenge based on current water consumption
  /// and user data. Returns an updated Challenge with current progress, 
  /// completion status, and formatted progress text.
  /// 
  /// **IMPORTANT:** Only calculates progress for challenges that are actually
  /// active (started) in ChallengeProvider. Unstarted challenges return with
  /// progress = 0.0 and isCompleted = false.
  static Challenge calculateChallengeState(
    Challenge challenge,
    DailyHydrationProvider dailyHydrationProvider,
    UserProvider userProvider,
    ChallengeProvider challengeProvider,
  ) {
    // CRITICAL: Check if challenge is actually started (active or completed) in provider
    // Get the challenge from provider to check its actual state
    final providerChallenge = challengeProvider.getChallenge(challenge.id);
    
    // If challenge is not in provider (not started), return with zero progress
    if (providerChallenge == null) {
      // Return challenge with default/empty state (no progress)
      return Challenge(
        id: challenge.id,
        name: challenge.name,
        description: challenge.description,
        coinReward: challenge.coinReward,
        cardColor: challenge.cardColor,
        icon: challenge.icon,
        whyStart: challenge.whyStart,
        healthBenefit: challenge.healthBenefit,
        badgeEmoji: challenge.badgeEmoji,
        isCompleted: false,
        progress: 0.0,
        progressText: '',
        targetValue: challenge.targetValue,
      );
    }
    
    // CRITICAL: If challenge is already completed in provider, PRESERVE that state
    // Do NOT recalculate completion status - once completed, it stays completed
    if (providerChallenge.isCompleted == true) {
      // Return the challenge with completed state preserved
      // Use provider's data but merge with base challenge metadata
      return Challenge(
        id: challenge.id,
        name: challenge.name,
        description: challenge.description,
        coinReward: challenge.coinReward,
        cardColor: challenge.cardColor,
        icon: challenge.icon,
        whyStart: challenge.whyStart,
        healthBenefit: challenge.healthBenefit,
        badgeEmoji: challenge.badgeEmoji,
        isCompleted: true, // FORCE true - never override completed state
        progress: 1.0, // Completed challenges always show 100%
        progressText: 'Tamamlandı! 🎉',
        targetValue: challenge.targetValue,
      );
    }
    
    // Challenge is active but not completed - calculate live progress
    Challenge updatedChallenge = challenge;

    // At this point, challenge is active but NOT completed
    // Calculate live progress based on current water/user data
    if (challenge.id == 'deep_dive') {
      // Derin Dalış: 3 gün üst üste %100 su hedefi
      final isCompleted =
          userProvider.consecutiveDays >= 3 && dailyHydrationProvider.hasReachedDailyGoal;
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
        progress: isCompleted ? 1.0 : (userProvider.consecutiveDays / 3).clamp(0.0, 1.0),
        progressText: isCompleted ? 'Tamamlandı! 🎉' : '${userProvider.consecutiveDays}/3 gün',
      );
    } else if (challenge.id == 'coral_guardian') {
      // Mercan Koruyucu: Akşam 8'den sonra sadece su (basitleştirilmiş - bugün su hedefi)
      final isCompleted = dailyHydrationProvider.hasReachedDailyGoal;
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
        progress: isCompleted
            ? 1.0
            : (dailyHydrationProvider.consumedAmount / dailyHydrationProvider.dailyGoal)
                .clamp(0.0, 1.0),
        progressText: isCompleted 
            ? 'Tamamlandı! 🎉'
            : '${UnitConverter.formatVolume(dailyHydrationProvider.consumedAmount, userProvider.isMetric)}/${UnitConverter.formatVolume(dailyHydrationProvider.dailyGoal, userProvider.isMetric)}',
      );
    } else if (challenge.id == 'caffeine_hunter') {
      // Kafein Avcısı: Bugün 2 kahve yerine 2 büyük bardak su
      // 1 büyük bardak = 250ml (standart büyük bardak boyutu)
      const double largeCupSizeMl = 250.0;
      final double targetMl = challenge.targetValue * largeCupSizeMl; // 2.0 * 250 = 500ml
      final double currentProgress = dailyHydrationProvider.consumedAmount;
      final isCompleted = currentProgress >= targetMl;
      final progress = isCompleted ? 1.0 : (currentProgress / targetMl).clamp(0.0, 1.0);
      
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
        progress: progress,
        progressText: isCompleted
            ? 'Tamamlandı! 🎉'
            : '${UnitConverter.formatVolume(currentProgress, userProvider.isMetric)}/${UnitConverter.formatVolume(targetMl, userProvider.isMetric)}',
      );
    } else if (challenge.id == 'blue_crystal') {
      // Mavi Kristal: 1 hafta şekerli içecek yok
      // Bu mücadele için özel mantık: 7 gün boyunca sadece su içilmeli
      // Basitleştirilmiş: Günlük hedefe ulaşıldıysa ve sadece su içildiyse ilerleme sayılır
      // Şimdilik: Günlük hedefe ulaşıldıysa 1/7 gün olarak sayılır (basitleştirilmiş)
      final daysCompleted = userProvider.consecutiveDays.clamp(0, 7);
      final isCompleted = daysCompleted >= 7 && dailyHydrationProvider.hasReachedDailyGoal;
      final progress = isCompleted ? 1.0 : (daysCompleted / 7).clamp(0.0, 1.0);
      
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
        progress: progress,
        progressText: isCompleted ? 'Tamamlandı! 🎉' : '$daysCompleted/7 gün',
      );
    } else if (challenge.targetValue > 0.0) {
      // Generic water-based challenge: Calculate progress based on consumedAmount vs target
      // This handles any challenge that tracks water consumption (e.g., "Drink X ml")
      final double targetMl = challenge.targetValue;
      final double currentProgress = dailyHydrationProvider.consumedAmount;
      final isCompleted = currentProgress >= targetMl;
      final progress = isCompleted 
          ? 1.0
          : (targetMl > 0.0 ? (currentProgress / targetMl).clamp(0.0, 1.0) : 0.0);
      
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
        progress: progress,
        progressText: isCompleted
            ? 'Tamamlandı! 🎉'
            : '${UnitConverter.formatVolume(currentProgress, userProvider.isMetric)}/${UnitConverter.formatVolume(targetMl, userProvider.isMetric)}',
      );
    }
    // If no specific logic applies, return the challenge as-is
    // (some challenges might not need dynamic calculation)

    return updatedChallenge;
  }

  /// Gets all challenges with their calculated states.
  /// Filters out 'first_cup' challenge and applies live calculations.
  /// Only calculates progress for challenges that are actually active.
  static List<Challenge> getUpdatedChallenges(
    DailyHydrationProvider dailyHydrationProvider,
    UserProvider userProvider,
    ChallengeProvider challengeProvider,
  ) {
    return ChallengeData.getChallenges()
        .where((challenge) => challenge.id != 'first_cup')
        .map((challenge) => calculateChallengeState(
              challenge,
              dailyHydrationProvider,
              userProvider,
              challengeProvider,
            ))
        .toList();
  }
  
  /// Gets only active challenges with their calculated states.
  /// This is used for screens that should only display active challenges.
  static List<Challenge> getActiveChallengesWithProgress(
    DailyHydrationProvider dailyHydrationProvider,
    UserProvider userProvider,
    ChallengeProvider challengeProvider,
  ) {
    // Get active challenges from provider
    final activeChallenges = challengeProvider.activeIncompleteChallenges;
    
    // Calculate progress for each active challenge
    return activeChallenges.map((challenge) {
      // Get the base challenge data
      final baseChallenge = ChallengeData.getChallenges()
          .firstWhere((c) => c.id == challenge.id, orElse: () => challenge);
      
      // Calculate live state (will always pass the active check since it's from activeIncompleteChallenges)
      return calculateChallengeState(
        baseChallenge,
        dailyHydrationProvider,
        userProvider,
        challengeProvider,
      );
    }).toList();
  }
}

