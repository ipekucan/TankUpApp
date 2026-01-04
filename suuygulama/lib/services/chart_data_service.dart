import '../providers/history_provider.dart';
import '../core/services/logger_service.dart';
import '../utils/date_helpers.dart';
import '../utils/chart_date_utils.dart';
import '../widgets/history/chart_theme.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Chart data point model for representing a single data point in the chart.
class ChartDataPoint {
  final String label;
  final Map<String, double> drinkAmounts;
  final DateTime date;

  ChartDataPoint({
    required this.label,
    required this.drinkAmounts,
    required this.date,
  });
}

/// Service for calculating chart data points and bar groups.
/// Separates business logic from UI rendering.
class ChartDataService {
  ChartDataService._(); // Private constructor to prevent instantiation

  // İçecek renkleri - Premium modern palette
  // Each drink has a carefully selected vibrant color for visual appeal
  static const Map<String, Color> drinkColors = {
    'water': Color(0xFF4F8EF7),        // Vibrant blue
    'coffee': Color(0xFF8B5A2B),       // Rich brown
    'tea': Color(0xFF6B9E6B),          // Sage green
    'soda': Color(0xFFF59E0B),         // Amber orange
    'mineral_water': Color(0xFF60A5FA), // Sky blue
    'herbal_tea': Color(0xFF84CC16),   // Lime green
    'green_tea': Color(0xFF10B981),    // Emerald
    'cold_tea': Color(0xFF22D3EE),     // Cyan
    'lemonade': Color(0xFFFBBF24),     // Golden yellow
    'iced_coffee': Color(0xFFEA580C),  // Burnt orange
    'ayran': Color(0xFF64748B),        // Slate
    'kefir': Color(0xFF94A3B8),        // Cool gray
    'milk': Color(0xFFF1F5F9),         // Off-white
    'juice': Color(0xFFEF4444),        // Red
    'smoothie': Color(0xFFA855F7),     // Purple
    'fresh_juice': Color(0xFF84CC16),  // Lime
    'sports': Color(0xFF6366F1),       // Indigo
    'protein_shake': Color(0xFF7C3AED), // Violet
    'coconut_water': Color(0xFF4ADE80), // Green
    'energy_drink': Color(0xFFDC2626), // Bright red
    'detox_water': Color(0xFF06B6D4),  // Teal
  };

  /// Builds chart data points based on the selected period.
  ///
  /// [waterProvider] - The water provider containing drink entries
  /// [selectedPeriod] - The period type (day, week, month)
  /// [selectedDrinkFilters] - Optional set of drink IDs to filter by
  ///
  /// Returns a list of [ChartDataPoint] objects ready for chart rendering.
  static List<ChartDataPoint> buildChartData(
    HistoryProvider historyProvider,
    ChartPeriod selectedPeriod,
    Set<String> selectedDrinkFilters,
  ) {
    final List<ChartDataPoint> data = [];
    final now = DateHelpers.normalizeDate(DateTime.now());

    LoggerService.logInfo(
      'ChartDataService.buildChartData start: period=$selectedPeriod filters=${selectedDrinkFilters.length} now=${DateHelpers.toDateKey(now)}',
    );

    int iterationCounter = 0;

    if (selectedPeriod == ChartPeriod.day) {
      // GÜN Modu: Current week (Monday to Sunday)
      final weekStart = DateHelpers.normalizeDate(ChartDateUtils.getStartOfWeek(now));
      
      for (int i = 0; i < 7; i++) {
        final date = DateHelpers.normalizeDate(weekStart.add(Duration(days: i)));
        final dateKey = DateHelpers.toDateKey(date);
        final entries = historyProvider.getDrinkEntriesForDate(dateKey);

        // Filtre uygula
        final filteredEntries = selectedDrinkFilters.isEmpty
            ? entries
            : entries.where((e) => selectedDrinkFilters.contains(e.drinkId)).toList();

        // İçecek bazında grupla
        final drinkAmounts = <String, double>{};
        for (var entry in filteredEntries) {
          drinkAmounts[entry.drinkId] = (drinkAmounts[entry.drinkId] ?? 0) + entry.amount;
        }

        // Etiket: Haftanın günleri (short names: Pzt, Sal, Çar, Per, Cum, Cmt, Paz)
        final dayLabel = ChartDateUtils.getDayLabel(date);

        iterationCounter++;
        if (iterationCounter % 7 == 0) {
          LoggerService.logInfo(
            'ChartDataService.buildChartData loop: i=$iterationCounter dateKey=$dateKey entries=${filteredEntries.length}',
          );
        }

        data.add(ChartDataPoint(
          label: dayLabel,
          drinkAmounts: drinkAmounts,
          date: date,
        ));
      }
    } else if (selectedPeriod == ChartPeriod.week) {
      // HAFTA Modu: Last 4 weeks ending with the current week
      // Each week is Monday to Sunday
      final currentWeekStart = DateHelpers.normalizeDate(ChartDateUtils.getStartOfWeek(now));
      
      // Generate exactly 4 weeks (strictly limit to 4 columns)
      for (int i = 3; i >= 0; i--) {
        final weekStart = DateHelpers.normalizeDate(
          currentWeekStart.subtract(Duration(days: i * 7)),
        );
        final weekEnd = DateHelpers.normalizeDate(weekStart.add(const Duration(days: 6)));
        final entries = historyProvider.getDrinkEntriesForDateRange(weekStart, weekEnd);

        // Filtre uygula
        final filteredEntries = selectedDrinkFilters.isEmpty
            ? entries
            : entries.where((e) => selectedDrinkFilters.contains(e.drinkId)).toList();

        // İçecek bazında grupla
        final drinkAmounts = <String, double>{};
        for (var entry in filteredEntries) {
          drinkAmounts[entry.drinkId] = (drinkAmounts[entry.drinkId] ?? 0) + entry.amount;
        }

        // Label: Week number (1.Hafta, 2.Hafta, 3.Hafta, 4.Hafta)
        final weekNumber = 4 - i;
        final label = '$weekNumber.Hafta';

        iterationCounter++;
        if (iterationCounter % 7 == 0) {
          LoggerService.logInfo(
            'ChartDataService.buildChartData loop: i=$iterationCounter weekStart=${DateHelpers.toDateKey(weekStart)} entries=${filteredEntries.length}',
          );
        }

        data.add(ChartDataPoint(
          label: label,
          drinkAmounts: drinkAmounts,
          date: weekStart,
        ));
      }
    } else {
      // AY Modu: First 6 months of the year (January to June)
      const monthNames = [
        'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran'
      ];
      
      final currentYear = now.year;

      for (int i = 0; i < 6; i++) {
        int targetMonth = i + 1;
        int targetYear = currentYear;

        final monthStart =
            DateHelpers.normalizeDate(ChartDateUtils.getMonthStart(targetYear, targetMonth));
        final monthEnd =
            DateHelpers.normalizeDate(ChartDateUtils.getMonthEnd(targetYear, targetMonth));
        final entries = historyProvider.getDrinkEntriesForDateRange(monthStart, monthEnd);

        // Filtre uygula
        final filteredEntries = selectedDrinkFilters.isEmpty
            ? entries
            : entries.where((e) => selectedDrinkFilters.contains(e.drinkId)).toList();

        // İçecek bazında grupla
        final drinkAmounts = <String, double>{};
        for (var entry in filteredEntries) {
          drinkAmounts[entry.drinkId] = (drinkAmounts[entry.drinkId] ?? 0) + entry.amount;
        }

        // Use full month name as requested (Ocak, Şubat, vb.)
        final label = monthNames[i];

        iterationCounter++;
        if (iterationCounter % 7 == 0) {
          LoggerService.logInfo(
            'ChartDataService.buildChartData loop: i=$iterationCounter monthStart=${DateHelpers.toDateKey(monthStart)} entries=${filteredEntries.length}',
          );
        }

        data.add(ChartDataPoint(
          label: label,
          drinkAmounts: drinkAmounts,
          date: monthStart,
        ));
      }
    }

    return data;
  }

  /// Builds bar chart groups from chart data points.
  ///
  /// [chartData] - List of chart data points
  /// [selectedPeriod] - The period type (affects bar width)
  /// [selectedDrinkFilters] - Optional set of drink IDs to filter by
  ///
  /// Returns a list of [BarChartGroupData] ready for fl_chart rendering.
  static List<BarChartGroupData> buildBarGroups(
    List<ChartDataPoint> chartData,
    ChartPeriod selectedPeriod,
    Set<String> selectedDrinkFilters,
  ) {
    return chartData.asMap().entries.map((entry) {
      final index = entry.key;
      final dataPoint = entry.value;

      // Her bar için toplam miktarı hesapla (filtre uygula)
      double totalAmount = 0.0;
      final drinkAmounts = <String, double>{};

      if (selectedDrinkFilters.isEmpty) {
        // Tüm içecekleri dahil et
        drinkAmounts.addAll(dataPoint.drinkAmounts);
      } else {
        // Sadece seçili içecekleri dahil et
        for (var filterId in selectedDrinkFilters) {
          if (dataPoint.drinkAmounts.containsKey(filterId)) {
            drinkAmounts[filterId] = dataPoint.drinkAmounts[filterId]!;
          }
        }
      }

      totalAmount = drinkAmounts.values.fold(0.0, (sum, val) => sum + val);

      // Stacked bar için rodStackItems oluştur
      final rodStackItems = <BarChartRodStackItem>[];
      double currentY = 0.0; // Her bar SIFIRDAN başlamalı

      // Önemli içecekleri sırayla ekle (with enhanced colors for premium look)
      final importantDrinks = ['water', 'coffee', 'tea', 'soda'];
      for (var drinkId in importantDrinks) {
        final amount = drinkAmounts[drinkId] ?? 0.0;
        if (amount > 0) {
          final baseColor = ChartDataService.drinkColors[drinkId] ?? Colors.grey;
          rodStackItems.add(
            BarChartRodStackItem(
              currentY, // fromY
              currentY + amount, // toY
              baseColor, // Keep solid colors for stacked bars (better clarity)
            ),
          );
          currentY += amount;
        }
      }

      // Diğer içecekleri ekle
      for (var entry in drinkAmounts.entries) {
        if (!importantDrinks.contains(entry.key) && entry.value > 0) {
          final baseColor = drinkColors[entry.key] ?? Colors.grey;
          rodStackItems.add(
            BarChartRodStackItem(
              currentY, // fromY
              currentY + entry.value, // toY
              baseColor,
            ),
          );
          currentY += entry.value;
        }
      }

      // Tek bir BarChartRodData ile stacked bar oluştur
      // Note: Bar width and radius are now handled by ChartTheme for consistency
      // Premium styling: Gradient for single-color bars, solid for stacked
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: totalAmount,
            width: ChartTheme.barWidth,
            borderRadius: ChartTheme.barBorderRadius,
            rodStackItems: rodStackItems.isNotEmpty ? rodStackItems : null,
            // For empty bars, use subtle gray; for filled use gradient
            gradient: rodStackItems.isEmpty 
                ? null
                : rodStackItems.length == 1
                    ? LinearGradient(
                        colors: [
                          rodStackItems.first.color,
                          rodStackItems.first.color.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      )
                    : null,
            color: rodStackItems.isEmpty 
                ? ChartTheme.emptyBarColor 
                : (rodStackItems.length > 1 ? null : null),
            // Removed background bar to prevent ghost column effect during transitions
          ),
        ],
        barsSpace: 0,
      );
    }).toList();
  }

  /// Calculates the maximum Y value for the chart.
  ///
  /// [chartData] - List of chart data points
  ///
  /// Returns the maximum Y value with 20% padding, clamped to minimum 500.
  static double getMaxY(List<ChartDataPoint> chartData) {
    double max = 0;
    for (var dataPoint in chartData) {
      final total = dataPoint.drinkAmounts.values.fold(0.0, (sum, val) => sum + val);
      if (total > max) max = total;
    }
    return (max * 1.2).ceilToDouble().clamp(500.0, double.infinity);
  }
}

/// Enum for chart period types
enum ChartPeriod { day, week, month }
