import '../providers/water_provider.dart';
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

  // İçecek renkleri
  static const Map<String, Color> drinkColors = {
    'water': Colors.blue,
    'coffee': Colors.brown,
    'tea': Colors.green,
    'soda': Colors.orange,
    'mineral_water': Colors.lightBlue,
    'herbal_tea': Colors.lightGreen,
    'green_tea': Colors.teal,
    'cold_tea': Colors.cyan,
    'lemonade': Colors.yellow,
    'iced_coffee': Colors.deepOrange,
    'ayran': Colors.blueGrey,
    'kefir': Colors.grey,
    'milk': Colors.white,
    'juice': Colors.redAccent,
    'smoothie': Colors.purpleAccent,
    'fresh_juice': Colors.lime,
    'sports': Colors.indigo,
    'protein_shake': Colors.deepPurple,
    'coconut_water': Colors.lightGreenAccent,
    'energy_drink': Colors.red,
    'detox_water': Colors.cyanAccent,
  };

  /// Builds chart data points based on the selected period.
  ///
  /// [waterProvider] - The water provider containing drink entries
  /// [selectedPeriod] - The period type (day, week, month)
  /// [selectedDrinkFilters] - Optional set of drink IDs to filter by
  ///
  /// Returns a list of [ChartDataPoint] objects ready for chart rendering.
  static List<ChartDataPoint> buildChartData(
    WaterProvider waterProvider,
    ChartPeriod selectedPeriod,
    Set<String> selectedDrinkFilters,
  ) {
    final List<ChartDataPoint> data = [];
    final now = DateTime.now();

    if (selectedPeriod == ChartPeriod.day) {
      // GÜN Modu: Current week (Monday to Sunday)
      final weekStart = ChartDateUtils.getStartOfWeek(now);
      
      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        final dateKey = DateHelpers.toDateKey(date);
        final entries = waterProvider.getDrinkEntriesForDate(dateKey);

        // Filtre uygula
        final filteredEntries = selectedDrinkFilters.isEmpty
            ? entries
            : entries.where((e) => selectedDrinkFilters.contains(e.drinkId)).toList();

        // İçecek bazında grupla
        final drinkAmounts = <String, double>{};
        for (var entry in filteredEntries) {
          drinkAmounts[entry.drinkId] = (drinkAmounts[entry.drinkId] ?? 0) + entry.amount;
        }

        // Etiket: Haftanın günleri (single letter abbreviations: P, S, Ç, P, C, C, P)
        final dayLabel = ChartDateUtils.getDaySingleLetter(date);

        data.add(ChartDataPoint(
          label: dayLabel,
          drinkAmounts: drinkAmounts,
          date: date,
        ));
      }
    } else if (selectedPeriod == ChartPeriod.week) {
      // HAFTA Modu: Last 4 weeks ending with the current week
      // Each week is Monday to Sunday
      final currentWeekStart = ChartDateUtils.getStartOfWeek(now);
      
      // Generate exactly 4 weeks (strictly limit to 4 columns)
      for (int i = 3; i >= 0; i--) {
        final weekStart = currentWeekStart.subtract(Duration(days: i * 7));
        final weekEnd = weekStart.add(const Duration(days: 6));
        final entries = waterProvider.getDrinkEntriesForDateRange(weekStart, weekEnd);

        // Filtre uygula
        final filteredEntries = selectedDrinkFilters.isEmpty
            ? entries
            : entries.where((e) => selectedDrinkFilters.contains(e.drinkId)).toList();

        // İçecek bazında grupla
        final drinkAmounts = <String, double>{};
        for (var entry in filteredEntries) {
          drinkAmounts[entry.drinkId] = (drinkAmounts[entry.drinkId] ?? 0) + entry.amount;
        }

        // Label: Week number (1, 2, 3, 4) where 4 is the current week
        final weekNumber = 4 - i;
        final label = '$weekNumber. Hafta';

        data.add(ChartDataPoint(
          label: label,
          drinkAmounts: drinkAmounts,
          date: weekStart,
        ));
      }
    } else {
      // AY Modu: Last 5-6 months ending with the current month
      // Dynamic calculation based on DateTime.now()
      final monthLabels = ChartDateUtils.getLastMonthsLabels(5);
      final currentMonth = now.month;
      final currentYear = now.year;

      // Generate data for the last 5 months
      for (int i = 0; i < 5; i++) {
        // Calculate target month (going back from current month)
        int targetMonth = currentMonth - (4 - i);
        int targetYear = currentYear;

        // Handle year rollover
        while (targetMonth <= 0) {
          targetMonth += 12;
          targetYear -= 1;
        }

        final monthStart = ChartDateUtils.getMonthStart(targetYear, targetMonth);
        final monthEnd = ChartDateUtils.getMonthEnd(targetYear, targetMonth);
        final entries = waterProvider.getDrinkEntriesForDateRange(monthStart, monthEnd);

        // Filtre uygula
        final filteredEntries = selectedDrinkFilters.isEmpty
            ? entries
            : entries.where((e) => selectedDrinkFilters.contains(e.drinkId)).toList();

        // İçecek bazında grupla
        final drinkAmounts = <String, double>{};
        for (var entry in filteredEntries) {
          drinkAmounts[entry.drinkId] = (drinkAmounts[entry.drinkId] ?? 0) + entry.amount;
        }

        // Dynamic label from ChartDateUtils
        final label = monthLabels[i];

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
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: totalAmount,
            width: ChartTheme.barWidth,
            borderRadius: ChartTheme.barBorderRadius, // Premium rounded top (8.0)
            rodStackItems: rodStackItems.isNotEmpty ? rodStackItems : null,
            // For empty bars, use solid color
            color: rodStackItems.isEmpty ? Colors.grey[300] : null,
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
