/// Utility class for date-related helper functions.
/// Centralizes date formatting and manipulation logic to eliminate code duplication.
class DateHelpers {
  /// Converts a DateTime to a date key string in the format 'YYYY-MM-DD'.
  /// 
  /// This format is used as a key for storing daily drink entries.
  /// 
  /// Example: DateTime(2024, 1, 15) -> '2024-01-15'
  static String toDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Returns the Turkish weekday name for a given weekday number.
  /// 
  /// [weekday] should be a value from DateTime (1 = Monday, 7 = Sunday).
  /// 
  /// Example: DateTime.monday (1) -> 'Pazartesi'
  static String getWeekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Pazartesi';
      case DateTime.tuesday:
        return 'Salı';
      case DateTime.wednesday:
        return 'Çarşamba';
      case DateTime.thursday:
        return 'Perşembe';
      case DateTime.friday:
        return 'Cuma';
      case DateTime.saturday:
        return 'Cumartesi';
      case DateTime.sunday:
        return 'Pazar';
      default:
        return '';
    }
  }
}

