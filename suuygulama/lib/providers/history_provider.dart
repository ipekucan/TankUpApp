import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/services/logger_service.dart';
import '../models/drink_entry_model.dart';
import '../utils/date_helpers.dart';

/// Manages historical hydration data (per-day aggregates and detailed entries).
///
/// Responsibilities:
/// - Persist and load drink history from SharedPreferences
/// - Provide date-range query utilities for history screens and charts
/// - Maintain a rolling retention window (e.g., last 30 days)
class HistoryProvider extends ChangeNotifier {
  static const String _drinkHistoryKey = 'drink_history'; // legacy (YYYY-MM-DD -> ml)
  static const String _detailedDrinkHistoryKey =
      'detailed_drink_history'; // dateKey -> list<DrinkEntry>

  Map<String, double> _drinkHistory = {};
  final Map<String, List<DrinkEntry>> _detailedDrinkHistory = {};
  int _historyRevision = 0;

  /// Last 30 days drink history (dateKey -> ml). (Legacy compatibility)
  Map<String, double> get drinkHistory => Map.unmodifiable(_drinkHistory);

  /// Detailed history (dateKey -> list of entries).
  Map<String, List<DrinkEntry>> get detailedDrinkHistory =>
      Map.unmodifiable(_detailedDrinkHistory);

  /// A monotonically increasing revision counter that changes whenever history data changes.
  ///
  /// Use this for lightweight UI invalidation (e.g., `Selector`) without exposing the whole maps.
  int get historyRevision => _historyRevision;

  HistoryProvider() {
    _loadHistoryData();
  }

  /// Get entries for a single date key (YYYY-MM-DD).
  List<DrinkEntry> getDrinkEntriesForDate(String dateKey) {
    return List.unmodifiable(_detailedDrinkHistory[dateKey] ?? []);
  }

  /// Get entries for an inclusive date range.
  List<DrinkEntry> getDrinkEntriesForDateRange(DateTime startDate, DateTime endDate) {
    // NOTE: This method is intentionally pure/read-only:
    // - Must NOT call notifyListeners()
    // - Must stay fast to avoid UI jank on chart/history screens

    final start = DateHelpers.normalizeDate(startDate);
    final end = DateHelpers.normalizeDate(endDate);

    if (end.isBefore(start)) {
      LoggerService.logError(
        'HistoryProvider.getDrinkEntriesForDateRange called with end < start',
        'start=${DateHelpers.toDateKey(start)} end=${DateHelpers.toDateKey(end)}',
      );
      return const <DrinkEntry>[];
    }

    // Safe bounded iteration (prevents accidental infinite loops/freezes)
    final totalDays = end.difference(start).inDays;
    final maxDays = totalDays > 366 ? 366 : totalDays;
    if (totalDays > 366) {
      LoggerService.logError(
        'HistoryProvider.getDrinkEntriesForDateRange exceeded safety window; truncating iteration',
        'start=${DateHelpers.toDateKey(start)} end=${DateHelpers.toDateKey(end)} totalDays=$totalDays',
      );
    }

    final entries = <DrinkEntry>[];
    for (int i = 0; i <= maxDays; i++) {
      final current = start.add(Duration(days: i));
      final dateKey = DateHelpers.toDateKey(current);
      final dayEntries = _detailedDrinkHistory[dateKey];
      if (dayEntries != null && dayEntries.isNotEmpty) {
        entries.addAll(dayEntries);
      }
    }

    return entries;
  }

  /// Filter entries by drinkId, optionally by date range.
  List<DrinkEntry> getDrinkEntriesByDrinkId(
    String drinkId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (startDate != null && endDate != null) {
      return getDrinkEntriesForDateRange(startDate, endDate)
          .where((entry) => entry.drinkId == drinkId)
          .toList();
    }
    return _detailedDrinkHistory.values
        .expand((entries) => entries)
        .where((entry) => entry.drinkId == drinkId)
        .toList();
  }

  /// Adds a new drink entry to history and persists it.
  ///
  /// [effectiveAmount] is used for the legacy daily aggregate map.
  Future<void> addDrinkEntry(DrinkEntry entry, {required double effectiveAmount}) async {
    final dateKey = DateHelpers.toDateKey(entry.timestamp);

    // legacy aggregate history (ml)
    _drinkHistory[dateKey] = (_drinkHistory[dateKey] ?? 0.0) + effectiveAmount;

    // detailed history
    final list = _detailedDrinkHistory.putIfAbsent(dateKey, () => <DrinkEntry>[]);
    list.add(entry);

    _cleanOldHistory();
    _cleanOldDetailedHistory();

    await _saveHistoryData();
    _historyRevision++;
    notifyListeners();
  }

  Future<void> _loadHistoryData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // legacy drinkHistory
      final drinkHistoryJson = prefs.getString(_drinkHistoryKey);
      if (drinkHistoryJson != null) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(drinkHistoryJson);
          _drinkHistory = decoded.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          );
          _cleanOldHistory();
        } catch (e, stackTrace) {
          LoggerService.logError('Failed to parse drink history JSON', e, stackTrace);
          _drinkHistory = {};
        }
      } else {
        _drinkHistory = {};
      }

      // detailed history
      final detailedHistoryJson = prefs.getString(_detailedDrinkHistoryKey);
      if (detailedHistoryJson != null) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(detailedHistoryJson);
          _detailedDrinkHistory.clear();
          _detailedDrinkHistory.addAll(
            decoded.map(
              (key, value) => MapEntry(
                key,
                (value as List)
                    .map((e) => DrinkEntry.fromJson(e as Map<String, dynamic>))
                    .toList(),
              ),
            ),
          );
          _cleanOldDetailedHistory();
        } catch (e, stackTrace) {
          LoggerService.logError(
            'Failed to parse detailed drink history JSON',
            e,
            stackTrace,
          );
          _detailedDrinkHistory.clear();
        }
      } else {
        _detailedDrinkHistory.clear();
      }

      _historyRevision++;
      notifyListeners();
    } catch (e, stackTrace) {
      LoggerService.logError('Failed to load history data', e, stackTrace);
      _drinkHistory = {};
      _detailedDrinkHistory.clear();
      _historyRevision++;
      notifyListeners();
    }
  }

  Future<void> _saveHistoryData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_drinkHistoryKey, jsonEncode(_drinkHistory));

      final detailedHistoryJson = jsonEncode(
        _detailedDrinkHistory.map(
          (key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()),
        ),
      );
      await prefs.setString(_detailedDrinkHistoryKey, detailedHistoryJson);
    } catch (e, stackTrace) {
      LoggerService.logError('Failed to save history data', e, stackTrace);
    }
  }

  void _cleanOldDetailedHistory() {
    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: AppConstants.historyRetentionDays));
    final cutoffKey = DateHelpers.toDateKey(cutoffDate);

    _detailedDrinkHistory.removeWhere((key, value) => key.compareTo(cutoffKey) < 0);
  }

  void _cleanOldHistory() {
    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: AppConstants.historyRetentionDays));
    final cutoffKey = DateHelpers.toDateKey(cutoffDate);

    _drinkHistory.removeWhere((key, value) => key.compareTo(cutoffKey) < 0);
  }

  /// Calculate current hydration streak (consecutive days with water consumption).
  ///
  /// Logic:
  /// - Iterate backwards from today (or yesterday if no water drunk today yet)
  /// - Count consecutive days where consumption > 0
  /// - Stop at first day with 0 consumption
  /// - Return streak count (0 if no streak)
  int calculateCurrentStreak() {
    if (_drinkHistory.isEmpty) {
      return 0;
    }

    final now = DateTime.now();
    final today = DateHelpers.normalizeDate(now);
    final todayKey = DateHelpers.toDateKey(today);

    // Check if water was drunk today
    final todayConsumption = _drinkHistory[todayKey] ?? 0.0;
    
    // Start from today if consumed, otherwise from yesterday
    DateTime currentDate = todayConsumption > 0 ? today : today.subtract(const Duration(days: 1));
    
    int streak = 0;
    const maxIterations = 365; // Safety limit

    for (int i = 0; i < maxIterations; i++) {
      final dateKey = DateHelpers.toDateKey(currentDate);
      final consumption = _drinkHistory[dateKey] ?? 0.0;

      if (consumption > 0) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        // First day with no consumption - break streak
        break;
      }
    }

    return streak;
  }

  /// Calculate live streak based on current consumption and goal.
  ///
  /// This is the REAL-TIME streak that considers:
  /// - Historical streak (consecutive days from previous days)
  /// - Today's progress: +1 if currentConsumption >= dailyGoal, otherwise +0
  ///
  /// Key Rules:
  /// 1. Binary increment: Even if user drinks 200% of goal, streak only adds +1 for today
  /// 2. Dynamic goal: If goal changes mid-day, progress recalculates immediately
  /// 3. No double counting: Today's entry in history is ignored to prevent duplication
  ///
  /// Returns: Total streak count (historical + today's potential)
  int calculateLiveStreak(double currentConsumption, double dailyGoal) {
    if (dailyGoal <= 0) {
      return 0; // Invalid goal
    }

    final now = DateTime.now();
    final today = DateHelpers.normalizeDate(now);

    // Calculate historical streak (excluding today)
    int historicalStreak = 0;
    
    if (_drinkHistory.isNotEmpty) {
      // Start from yesterday to avoid counting today twice
      DateTime currentDate = today.subtract(const Duration(days: 1));
      const maxIterations = 365; // Safety limit

      for (int i = 0; i < maxIterations; i++) {
        final dateKey = DateHelpers.toDateKey(currentDate);
        final consumption = _drinkHistory[dateKey] ?? 0.0;

        if (consumption > 0) {
          historicalStreak++;
          currentDate = currentDate.subtract(const Duration(days: 1));
        } else {
          // First day with no consumption - break streak
          break;
        }
      }
    }

    // Check if today's goal is met (binary: either +1 or +0)
    final isTodayGoalMet = currentConsumption >= dailyGoal;
    final todayBonus = isTodayGoalMet ? 1 : 0;

    // Return historical + today's bonus
    return historicalStreak + todayBonus;
  }
}

