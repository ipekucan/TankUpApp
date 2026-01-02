/// Utility class for date-related helper functions.
/// Centralizes date formatting and manipulation logic to eliminate code duplication.
class DateHelpers {
  /// Turkish month names (full names).
  static const List<String> monthNames = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  /// Turkish weekday names (full names).
  static const List<String> weekdayNames = [
    'Pazartesi', // Monday (1)
    'Salı', // Tuesday (2)
    'Çarşamba', // Wednesday (3)
    'Perşembe', // Thursday (4)
    'Cuma', // Friday (5)
    'Cumartesi', // Saturday (6)
    'Pazar', // Sunday (7)
  ];

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
    if (weekday >= 1 && weekday <= 7) {
      return weekdayNames[weekday - 1];
    }
    return '';
  }

  /// Returns the Turkish month name for a given month number.
  /// 
  /// [month] should be a value from 1-12 (January = 1, December = 12).
  /// 
  /// Example: 1 -> 'Ocak'
  static String getMonthName(int month) {
    if (month >= 1 && month <= 12) {
      return monthNames[month - 1];
    }
    return '';
  }

  /// Formats a DateTime to Turkish date string in the format "DD MonthName WeekdayName".
  /// 
  /// Example: DateTime(2024, 1, 2, DateTime.monday) -> "2 Ocak Pazartesi"
  /// 
  /// If [date] is not provided, uses DateTime.now().
  static String getFormattedTurkishDate([DateTime? date]) {
    final targetDate = date ?? DateTime.now();
    final day = targetDate.day;
    final month = getMonthName(targetDate.month);
    final weekday = getWeekdayName(targetDate.weekday);
    return '$day $month $weekday';
  }

  /// Normalizes a DateTime to midnight (00:00:00) by keeping only year, month, and day.
  /// 
  /// This is a common pattern used throughout the codebase to compare dates
  /// without time components.
  /// 
  /// Example: DateTime(2024, 1, 15, 14, 30, 45) -> DateTime(2024, 1, 15, 0, 0, 0)
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

