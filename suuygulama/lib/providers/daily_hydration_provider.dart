import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/services/logger_service.dart';
import '../models/drink_entry_model.dart';
import '../models/drink_model.dart';
import '../models/water_model.dart';
import '../utils/date_helpers.dart';
import 'challenge_provider.dart';
import 'history_provider.dart';

/// Manages daily hydration state and actions.
///
/// Responsibilities:
/// - Today's progress (consumedAmount / dailyGoal / progressPercentage)
/// - Adding drinks (`drink`, `drinkWater`) and applying daily rules/bonuses
/// - Daily reset logic (based on user's reset time)
/// - Coins, calories, and lastDrinkTime (tank dirtiness)
///
/// Notes:
/// - History persistence lives in [HistoryProvider]. This provider writes new entries into it.
class DailyHydrationProvider extends ChangeNotifier {
  static const String _waterDataKey = 'water_data';
  static const String _lastDrinkTimeKey = 'last_drink_time';
  static const String _lastResetDateKey = 'last_reset_date';

  static const String _earlyBirdClaimedKey = 'early_bird_claimed';
  static const String _nightOwlClaimedKey = 'night_owl_claimed';
  static const String _dailyGoalBonusClaimedKey = 'daily_goal_bonus_claimed';
  static const String _streakCountKey = 'streak_count';
  static const String _lastStreakDateKey = 'last_streak_date';
  static const String _goalCompletedTodayKey = 'goal_completed_today';

  WaterModel _waterData = WaterModel.initial();
  DateTime? _lastDrinkTime;
  DateTime? _lastResetDate;
  bool _isFirstDrink = true;
  bool _earlyBirdClaimed = false;
  bool _nightOwlClaimed = false;
  bool _dailyGoalBonusClaimed = false;
  
  /// Streak tracking
  int _streakCount = 0;
  DateTime? _lastStreakDate;
  bool _goalCompletedToday = false;

  HistoryProvider? _historyProvider;

  DailyHydrationProvider() {
    _loadDailyData();
  }

  /// Injects [HistoryProvider] (used to write drink entries).
  void updateHistoryProvider(HistoryProvider historyProvider) {
    _historyProvider = historyProvider;
  }

  double get dailyGoal => _waterData.dailyGoal;
  double get consumedAmount => _waterData.consumedAmount;
  double get progressPercentage => _waterData.progressPercentage;
  int get tankCoins => _waterData.tankCoins;
  double get dailyCalories => _waterData.dailyCalories;
  WaterModel get waterData => _waterData;
  DateTime? get lastDrinkTime => _waterData.lastDrinkTime;

  bool get hasReachedDailyLimit =>
      _waterData.consumedAmount >= AppConstants.dailyHydrationLimitMl;

  bool get hasReachedDailyGoal => _waterData.consumedAmount >= _waterData.dailyGoal;
  
  /// Current streak count (consecutive days with completed goal)
  int get streakCount => _streakCount;
  
  /// Whether the daily goal was completed today (for UI display)
  bool get goalCompletedToday => _goalCompletedToday;

  double get tankFillPercentage {
    if (_waterData.consumedAmount == 0.0) return 0.0;
    if (_waterData.dailyGoal == 0.0) return 0.0;
    return (_waterData.consumedAmount / _waterData.dailyGoal).clamp(0.0, 1.0);
  }

  Future<void> setDailyGoal(double goal) async {
    if (goal > 0) {
      _waterData = _waterData.copyWith(dailyGoal: goal);
      _updateProgress();
      await _saveDailyData();
      notifyListeners();
    }
  }

  Future<void> updateDailyGoal(double newGoal) async {
    final clampedGoal = newGoal.clamp(AppConstants.minDailyGoal, AppConstants.maxDailyGoal);
    _waterData = _waterData.copyWith(dailyGoal: clampedGoal);
    _updateProgress();
    await _saveDailyData();
    notifyListeners();
  }

  Future<bool> spendCoins(int amount) async {
    if (amount > 0 && _waterData.tankCoins >= amount) {
      _waterData = _waterData.copyWith(tankCoins: _waterData.tankCoins - amount);
      await _saveDailyData();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> addCoins(int amount) async {
    if (amount > 0) {
      _waterData = _waterData.copyWith(tankCoins: _waterData.tankCoins + amount);
      await _saveDailyData();
      notifyListeners();
    }
  }

  Future<void> resetCoins() async {
    _waterData = _waterData.copyWith(tankCoins: 0);
    await _saveDailyData();
    notifyListeners();
  }

  /// Water shortcut (legacy compatibility).
  Future<DrinkWaterResult> drinkWater() async {
    final water = DrinkData.getDrinks().firstWhere((d) => d.id == 'water');
    return drink(water, 250.0);
  }

  Future<DrinkWaterResult> drink(
    Drink drink,
    double amount, {
    BuildContext? context,
  }) async {
    if (hasReachedDailyLimit) {
      return DrinkWaterResult(
        success: false,
        message: 'Günlük limitinize ulaştınız! (5 litre)',
        coinsReward: 0,
      );
    }

    final effectiveAmount = amount * drink.hydrationFactor;
    final calories = (drink.caloriePer100ml * amount) / 100.0;

    final newConsumedAmount = _waterData.consumedAmount + effectiveAmount;
    final newDailyCalories = _waterData.dailyCalories + calories;

    if (newConsumedAmount > AppConstants.dailyHydrationLimitMl) {
      return DrinkWaterResult(
        success: false,
        message: 'Günlük limitinize ulaştınız! (5 litre)',
        coinsReward: 0,
      );
    }

    final now = DateTime.now();
    _lastDrinkTime = now;

    // Create entry
    final drinkEntry = DrinkEntry(
      drinkId: drink.id,
      amount: amount,
      effectiveAmount: effectiveAmount,
      timestamp: now,
    );

    // Defer history persistence until after any BuildContext-dependent work (challenge tracking),
    // to avoid using BuildContext across async gaps.
    final historyProvider = _historyProvider;
    if (historyProvider == null) {
      LoggerService.logError(
        'HistoryProvider is not injected into DailyHydrationProvider; drink entry will not be persisted to history.',
      );
    }

    // Coin calculations
    int totalCoinsReward = 0;
    bool isLuckyDrink = false;
    bool isEarlyBird = false;
    bool isNightOwl = false;
    bool isDailyGoalBonus = false;

    // Lucky drink (5% chance)
    final random = (now.millisecondsSinceEpoch % AppConstants.luckyDrinkModuloBase);
    if (random < AppConstants.luckyDrinkChanceThreshold) {
      totalCoinsReward += AppConstants.luckyDrinkRewardCoins;
      isLuckyDrink = true;
    }

    // Early bird bonus
    final currentHour = now.hour;
    if (!_earlyBirdClaimed &&
        currentHour < AppConstants.earlyBirdCutoffHour &&
        newConsumedAmount <= AppConstants.earlyBirdMaxConsumedMl) {
      totalCoinsReward += AppConstants.earlyBirdRewardCoins;
      isEarlyBird = true;
      _earlyBirdClaimed = true;
    }

    // Night owl bonus
    if (!_nightOwlClaimed && currentHour >= AppConstants.nightOwlStartHour) {
      totalCoinsReward += AppConstants.nightOwlRewardCoins;
      isNightOwl = true;
      _nightOwlClaimed = true;
    }

    // Daily goal bonus
    final wasGoalReachedBefore = _waterData.consumedAmount >= _waterData.dailyGoal;
    final isGoalReachedNow = newConsumedAmount >= _waterData.dailyGoal;
    if (!_dailyGoalBonusClaimed && !wasGoalReachedBefore && isGoalReachedNow) {
      totalCoinsReward += AppConstants.dailyGoalBonusCoins;
      isDailyGoalBonus = true;
      _dailyGoalBonusClaimed = true;
      
      // Update streak when goal is completed for the first time today
      await _updateStreakOnGoalCompletion();
    }

    // Challenge tracking - Check context before usage
    int challengeCoinsReward = 0;
    if (context != null &&
        context.mounted &&
        drink.id == 'water' &&
        amount >= AppConstants.challengeBigCupMinMl) {
      try {
        final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
        final challengeProvider = Provider.of<ChallengeProvider>(context, listen: false);
        if (challengeProvider.hasActiveChallenge('caffeine_hunter')) {
          challengeCoinsReward = await challengeProvider.updateProgress('caffeine_hunter', 1.0);
          if (challengeCoinsReward > 0 && scaffoldMessenger != null && context.mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Tebrikler! Kafein Avcısı mücadelesini tamamladın! 🎉 +$challengeCoinsReward Coin',
                    ),
                    backgroundColor: const Color(0xFF8B4513),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            });
          }
        }
      } catch (e, stackTrace) {
        LoggerService.logError('Failed to update challenge progress', e, stackTrace);
      }
    }

    final newTankCoins = _waterData.tankCoins + totalCoinsReward + challengeCoinsReward;

    _waterData = _waterData.copyWith(
      consumedAmount: newConsumedAmount,
      tankCoins: newTankCoins,
      lastDrinkTime: now,
      dailyCalories: newDailyCalories,
    );

    // Persist history (no BuildContext usage here)
    if (historyProvider != null) {
      await historyProvider.addDrinkEntry(drinkEntry, effectiveAmount: effectiveAmount);
    }

    _updateProgress();
    await _saveDailyData();
    notifyListeners();

    final wasFirstDrink = _isFirstDrink;
    _isFirstDrink = false;

    String message = '${drink.name} içildi!';
    final totalReward = totalCoinsReward + challengeCoinsReward;
    if (totalReward > 0) {
      message += ' +$totalReward Coin';
      if (isLuckyDrink) message += ' (Şanslı Yudum! 🍀)';
      if (isEarlyBird) message += ' (Erken Kuş! 🌅)';
      if (isNightOwl) message += ' (Gece Kuşu! 🌙)';
      if (isDailyGoalBonus) message += ' (Hedefe Ulaşıldı! 🎯)';
    }

    return DrinkWaterResult(
      success: true,
      message: message,
      coinsReward: totalCoinsReward + challengeCoinsReward,
      isFirstDrink: wasFirstDrink,
      isLuckyDrink: isLuckyDrink,
      isEarlyBird: isEarlyBird,
      isNightOwl: isNightOwl,
      isDailyGoalBonus: isDailyGoalBonus,
    );
  }

  /// Tank is dirty if last drink time was >= 24 hours ago.
  bool get isTankDirty {
    if (_waterData.lastDrinkTime == null || _lastDrinkTime == null) {
      return false;
    }
    final now = DateTime.now();
    final difference = now.difference(_waterData.lastDrinkTime!);
    return difference.inHours >= 24;
  }

  Future<void> simulateDirtyTank() async {
    final testTime = DateTime.now().subtract(const Duration(hours: 25));
    _lastDrinkTime = testTime;
    _waterData = _waterData.copyWith(lastDrinkTime: testTime);
    await _saveDailyData();
    notifyListeners();
  }

  // Aksolot mesajları listesi (15-20 mesaj)
  static final List<String> axolotlMessages = [
    'Harika görünüyorsun! 💙',
    'Su içmek cildine iyi gelecek! ✨',
    'Tankımız pırıl pırıl! 🌊',
    'Bugün harika bir gün! 💪',
    'Su içmeyi unutma! 💧',
    'Seni çok seviyorum! 🌟',
    'Birlikte büyüyoruz! ☀️',
    'Her gün daha iyi oluyoruz! 💙',
    'Su içmek çok önemli! 💪',
    'Seninle olmak harika! ✨',
    'Bugün de harika bir gün olacak! 🌊',
    'Mükemmel gidiyorsun! 🎉',
    'Su içmek sağlıklı! 💧',
    'Tankımız çok temiz! 🌟',
    'Sen harikasın! 💙',
    'Su içmek seni güçlendirir! 💪',
    'Birlikte çok güzeliz! ✨',
    'Her gün daha iyi! 🌊',
    'Su içmek zindelik verir! 💧',
    'Seni seviyorum! 💙',
  ];

  String getRandomMessage(String? userName) {
    final random = DateTime.now().millisecondsSinceEpoch % axolotlMessages.length;
    String message = axolotlMessages[random];

    if (userName != null && userName.isNotEmpty) {
      if (random % 3 == 0) {
        message = message.replaceFirst('görünüyorsun', '$userName, görünüyorsun');
        message = message.replaceFirst('Sen', '$userName, sen');
      }
    }

    return message;
  }

  Future<void> _loadDailyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final waterDataJson = prefs.getString(_waterDataKey);
      if (waterDataJson != null) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(waterDataJson);
          final loadedData = WaterModel.fromJson(decoded);

          // Keep dailyGoal locked to 5L for legacy compatibility (unchanged logic).
          final dailyGoal = loadedData.dailyGoal != AppConstants.maxDailyGoal
              ? AppConstants.maxDailyGoal
              : loadedData.dailyGoal;

          _waterData = loadedData.copyWith(
            dailyGoal: dailyGoal,
            consumedAmount: 0.0,
            progressPercentage: 0.0,
            dailyCalories: 0.0,
          );
        } catch (e, stackTrace) {
          LoggerService.logError('Failed to parse water data JSON', e, stackTrace);
          _waterData = WaterModel.initial();
        }
      } else {
        _waterData = WaterModel.initial();
      }

      if (_waterData.consumedAmount != 0.0) {
        _waterData = _waterData.copyWith(consumedAmount: 0.0, progressPercentage: 0.0);
      }

      final lastDrinkTimeString = prefs.getString(_lastDrinkTimeKey);
      if (lastDrinkTimeString != null) {
        try {
          _lastDrinkTime = DateTime.parse(lastDrinkTimeString);
          _waterData = _waterData.copyWith(lastDrinkTime: _lastDrinkTime);
        } catch (e, stackTrace) {
          LoggerService.logError('Failed to parse last drink time', e, stackTrace);
          _lastDrinkTime = null;
          _waterData = _waterData.copyWith(lastDrinkTime: null);
        }
      } else {
        _lastDrinkTime = null;
        _waterData = _waterData.copyWith(lastDrinkTime: null);
      }

      final lastResetDateString = prefs.getString(_lastResetDateKey);
      if (lastResetDateString != null) {
        try {
          _lastResetDate = DateTime.parse(lastResetDateString);
        } catch (e, stackTrace) {
          LoggerService.logError('Failed to parse last reset date', e, stackTrace);
          _lastResetDate = null;
        }
      } else {
        _lastResetDate = null;
      }

      _earlyBirdClaimed = prefs.getBool(_earlyBirdClaimedKey) ?? false;
      _nightOwlClaimed = prefs.getBool(_nightOwlClaimedKey) ?? false;
      _dailyGoalBonusClaimed = prefs.getBool(_dailyGoalBonusClaimedKey) ?? false;

      // Load streak data
      await _loadStreakData();

      await _checkAndResetDay();

      // Extra safety: ensure we don't revive stale values
      if (_waterData.consumedAmount != 0.0 ||
          _waterData.progressPercentage != 0.0 ||
          _waterData.dailyCalories != 0.0) {
        _waterData = _waterData.copyWith(
          consumedAmount: 0.0,
          progressPercentage: 0.0,
          dailyCalories: 0.0,
        );
        await prefs.setString(_waterDataKey, jsonEncode(_waterData.toJson()));
      }

      _updateProgress();
      notifyListeners();
    } catch (e, stackTrace) {
      LoggerService.logError('Failed to load daily hydration data', e, stackTrace);
      _waterData = WaterModel.initial();
      _lastDrinkTime = null;
      _lastResetDate = null;
      notifyListeners();
    }
  }

  Future<void> _saveDailyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_waterDataKey, jsonEncode(_waterData.toJson()));

      if (_lastDrinkTime != null) {
        await prefs.setString(_lastDrinkTimeKey, _lastDrinkTime!.toIso8601String());
      }

      if (_lastResetDate != null) {
        await prefs.setString(_lastResetDateKey, _lastResetDate!.toIso8601String());
      }

      await prefs.setBool(_earlyBirdClaimedKey, _earlyBirdClaimed);
      await prefs.setBool(_nightOwlClaimedKey, _nightOwlClaimed);
      await prefs.setBool(_dailyGoalBonusClaimedKey, _dailyGoalBonusClaimed);
    } catch (e, stackTrace) {
      LoggerService.logError('Failed to save daily hydration data', e, stackTrace);
    }
  }

  Future<void> _checkAndResetDay() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    final resetHour = prefs.getInt('reset_time_hour') ?? 0;
    final resetMinute = prefs.getInt('reset_time_minute') ?? 0;

    final today = DateHelpers.normalizeDate(now);

    if (_lastResetDate == null) {
      _lastResetDate = today;
      await _saveDailyData();
      return;
    }

    final lastReset = DateHelpers.normalizeDate(_lastResetDate!);

    final todayResetTime = DateTime(today.year, today.month, today.day, resetHour, resetMinute);

    bool shouldReset = false;
    if (today.isAfter(lastReset)) {
      shouldReset = true;
    } else if (today.isAtSameMomentAs(lastReset) && now.isAfter(todayResetTime)) {
      final lastResetTime = DateTime(
        lastReset.year,
        lastReset.month,
        lastReset.day,
        resetHour,
        resetMinute,
      );
      if (now.isAfter(lastResetTime)) {
        shouldReset = true;
      }
    }

    if (shouldReset) {
      _waterData = _waterData.copyWith(
        consumedAmount: 0.0,
        progressPercentage: 0.0,
        dailyCalories: 0.0,
        dailyGoal: AppConstants.maxDailyGoal,
        lastDrinkTime: null,
        tankCoins: _waterData.tankCoins + AppConstants.dailyResetCoinReward,
      );

      _lastResetDate = today;
      _lastDrinkTime = null;
      _isFirstDrink = true;

      _earlyBirdClaimed = false;
      _nightOwlClaimed = false;
      _dailyGoalBonusClaimed = false;
      await prefs.setBool(_earlyBirdClaimedKey, false);
      await prefs.setBool(_nightOwlClaimedKey, false);
      await prefs.setBool(_dailyGoalBonusClaimedKey, false);

      // Check and update streak on day reset
      await _checkStreakOnDayReset();

      await _saveDailyData();
      notifyListeners();
    }
  }

  void _updateProgress() {
    final percentage =
        (_waterData.consumedAmount / _waterData.dailyGoal * 100).clamp(0.0, 100.0);
    _waterData = _waterData.copyWith(progressPercentage: percentage);
  }

  /// Updates streak when daily goal is completed
  Future<void> _updateStreakOnGoalCompletion() async {
    final today = DateHelpers.normalizeDate(DateTime.now());
    
    // Already completed today - don't increment again
    if (_goalCompletedToday) return;
    
    _goalCompletedToday = true;
    
    if (_lastStreakDate == null) {
      // First ever completion
      _streakCount = 1;
      _lastStreakDate = today;
    } else {
      final lastStreak = DateHelpers.normalizeDate(_lastStreakDate!);
      final daysDifference = today.difference(lastStreak).inDays;
      
      if (daysDifference == 0) {
        // Same day - already handled by _goalCompletedToday check
        return;
      } else if (daysDifference == 1) {
        // Consecutive day - increment streak
        _streakCount++;
        _lastStreakDate = today;
      } else {
        // Streak broken - reset to 1
        _streakCount = 1;
        _lastStreakDate = today;
      }
    }
    
    await _saveStreakData();
    notifyListeners();
  }
  
  /// Loads streak data from SharedPreferences
  Future<void> _loadStreakData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _streakCount = prefs.getInt(_streakCountKey) ?? 0;
      _goalCompletedToday = prefs.getBool(_goalCompletedTodayKey) ?? false;
      
      final lastStreakDateString = prefs.getString(_lastStreakDateKey);
      if (lastStreakDateString != null) {
        try {
          _lastStreakDate = DateTime.parse(lastStreakDateString);
        } catch (e, stackTrace) {
          LoggerService.logError('Failed to parse last streak date', e, stackTrace);
          _lastStreakDate = null;
        }
      }
    } catch (e, stackTrace) {
      LoggerService.logError('Failed to load streak data', e, stackTrace);
    }
  }
  
  /// Saves streak data to SharedPreferences
  Future<void> _saveStreakData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_streakCountKey, _streakCount);
      await prefs.setBool(_goalCompletedTodayKey, _goalCompletedToday);
      
      if (_lastStreakDate != null) {
        await prefs.setString(_lastStreakDateKey, _lastStreakDate!.toIso8601String());
      }
    } catch (e, stackTrace) {
      LoggerService.logError('Failed to save streak data', e, stackTrace);
    }
  }
  
  /// Checks and resets streak on new day (called during day reset)
  Future<void> _checkStreakOnDayReset() async {
    final today = DateHelpers.normalizeDate(DateTime.now());
    
    if (_lastStreakDate != null) {
      final lastStreak = DateHelpers.normalizeDate(_lastStreakDate!);
      final daysDifference = today.difference(lastStreak).inDays;
      
      // If more than 1 day has passed without completing goal, reset streak
      if (daysDifference > 1) {
        _streakCount = 0;
        _lastStreakDate = null;
      }
    }
    
    // Reset daily completion flag for new day
    _goalCompletedToday = false;
    await _saveStreakData();
  }
}

/// Drink result model (kept compatible with previous WaterProvider API).
class DrinkWaterResult {
  final bool success;
  final String message;
  final int coinsReward;
  final bool isFirstDrink;
  final bool isLuckyDrink;
  final bool isEarlyBird;
  final bool isNightOwl;
  final bool isDailyGoalBonus;

  DrinkWaterResult({
    required this.success,
    required this.message,
    this.coinsReward = 0,
    this.isFirstDrink = false,
    this.isLuckyDrink = false,
    this.isEarlyBird = false,
    this.isNightOwl = false,
    this.isDailyGoalBonus = false,
  });
}

