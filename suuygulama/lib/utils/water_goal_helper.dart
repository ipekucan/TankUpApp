/// Helper class for water goal calculations.
/// Provides reusable methods for calculating water goal progress and percentages.
class WaterGoalHelper {
  WaterGoalHelper._(); // Private constructor to prevent instantiation

  /// Calculates the percentage of water consumed relative to the daily goal.
  /// 
  /// Formula: (currentIntake / dailyGoal) * 100
  /// 
  /// Handles edge cases:
  /// - Returns 0.0 if dailyGoal is 0 or negative
  /// - Clamps result between 0.0 and 100.0
  /// 
  /// Returns the percentage as a double (0.0 to 100.0).
  static double calculateGoalPercentage({
    required double currentIntake,
    required double dailyGoal,
  }) {
    if (dailyGoal <= 0) {
      return 0.0;
    }
    
    final percentage = (currentIntake / dailyGoal) * 100.0;
    return percentage.clamp(0.0, 100.0);
  }

  /// Formats the goal percentage as a string with optional decimal places.
  /// 
  /// [decimalPlaces] defaults to 0 (integer percentage).
  /// Set to 1 for one decimal place (e.g., "75.5%").
  /// 
  /// Returns a formatted string (e.g., "75%" or "75.5%").
  static String formatGoalPercentage({
    required double currentIntake,
    required double dailyGoal,
    int decimalPlaces = 0,
  }) {
    final percentage = calculateGoalPercentage(
      currentIntake: currentIntake,
      dailyGoal: dailyGoal,
    );
    
    if (decimalPlaces == 0) {
      return '${percentage.toInt()}%';
    } else {
      return '${percentage.toStringAsFixed(decimalPlaces)}%';
    }
  }

  /// Gets the progress value (0.0 to 1.0) for use with CircularProgressIndicator.
  /// 
  /// Returns a double between 0.0 and 1.0.
  static double getProgressValue({
    required double currentIntake,
    required double dailyGoal,
  }) {
    if (dailyGoal <= 0) {
      return 0.0;
    }
    
    final progress = currentIntake / dailyGoal;
    return progress.clamp(0.0, 1.0);
  }
}

