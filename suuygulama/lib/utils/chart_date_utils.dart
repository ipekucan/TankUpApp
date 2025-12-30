/// Utility class for generating dynamic chart date labels and calculations.
/// Ensures charts reflect real-time dates based on DateTime.now().
class ChartDateUtils {
  ChartDateUtils._(); // Private constructor to prevent instantiation

  /// Turkish month abbreviations.
  static const List<String> monthAbbreviations = [
    'Oca', // January
    'Şub', // February
    'Mar', // March
    'Nis', // April
    'May', // May
    'Haz', // June
    'Tem', // July
    'Ağu', // August
    'Eyl', // September
    'Eki', // October
    'Kas', // November
    'Ara', // December
  ];

  /// Turkish day abbreviations (Monday to Sunday).
  static const List<String> dayAbbreviations = [
    'Pzt', // Monday
    'Sal', // Tuesday
    'Çar', // Wednesday
    'Per', // Thursday
    'Cum', // Friday
    'Cmt', // Saturday
    'Paz', // Sunday
  ];

  /// Day single letter abbreviations (for compact display).
  static const List<String> daySingleLetters = [
    'P', // Pazartesi (Monday)
    'S', // Salı (Tuesday)
    'Ç', // Çarşamba (Wednesday)
    'P', // Perşembe (Thursday)
    'C', // Cuma (Friday)
    'C', // Cumartesi (Saturday)
    'P', // Pazar (Sunday)
  ];

  /// Gets the last N months ending with the current month.
  /// Returns a list of month labels in chronological order (oldest to newest).
  /// 
  /// Example: If today is Dec 31, and count=5, returns: ['Ağu', 'Eyl', 'Eki', 'Kas', 'Ara']
  static List<String> getLastMonthsLabels(int count) {
    final now = DateTime.now();
    final labels = <String>[];
    
    for (int i = count - 1; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final monthIndex = targetDate.month - 1; // 0-based index
      labels.add(monthAbbreviations[monthIndex]);
    }
    
    return labels;
  }

  /// Gets the month label for a given DateTime.
  static String getMonthLabel(DateTime date) {
    return monthAbbreviations[date.month - 1];
  }

  /// Gets the day label for a given DateTime.
  static String getDayLabel(DateTime date) {
    return dayAbbreviations[date.weekday - 1];
  }

  /// Gets the single letter day abbreviation for a given DateTime.
  static String getDaySingleLetter(DateTime date) {
    return daySingleLetters[date.weekday - 1];
  }

  /// Calculates which week of the month a given date falls into.
  /// Returns 1-5 (or 1-6 for months with 6 weeks).
  /// 
  /// Week 1: Days 1-7
  /// Week 2: Days 8-14
  /// Week 3: Days 15-21
  /// Week 4: Days 22-28
  /// Week 5: Days 29-31 (if applicable)
  static int getWeekOfMonth(DateTime date) {
    final dayOfMonth = date.day;
    return ((dayOfMonth - 1) ~/ 7) + 1;
  }

  /// Gets the start of the week (Monday) for a given date.
  static DateTime getStartOfWeek(DateTime date) {
    final weekday = date.weekday; // 1=Monday, 7=Sunday
    return date.subtract(Duration(days: weekday - 1));
  }

  /// Gets the end of the week (Sunday) for a given date.
  static DateTime getEndOfWeek(DateTime date) {
    final weekday = date.weekday; // 1=Monday, 7=Sunday
    return date.add(Duration(days: 7 - weekday));
  }

  /// Gets the start of the month for a given date.
  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Gets the end of the month for a given date.
  static DateTime getEndOfMonth(DateTime date) {
    final nextMonth = date.month == 12
        ? DateTime(date.year + 1, 1, 1)
        : DateTime(date.year, date.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1));
  }

  /// Gets the start of a specific month (for month view calculations).
  static DateTime getMonthStart(int year, int month) {
    return DateTime(year, month, 1);
  }

  /// Gets the end of a specific month.
  static DateTime getMonthEnd(int year, int month) {
    final nextMonth = month == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1));
  }
}

