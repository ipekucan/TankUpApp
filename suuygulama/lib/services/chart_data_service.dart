import '../providers/water_provider.dart';
import '../utils/date_helpers.dart';
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
      // GÜN Modu: Son 7 gün
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
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

        // Etiket: Haftanın günleri
        final dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
        final dayIndex = date.weekday - 1;

        data.add(ChartDataPoint(
          label: dayLabels[dayIndex],
          drinkAmounts: drinkAmounts,
          date: date,
        ));
      }
    } else if (selectedPeriod == ChartPeriod.week) {
      // HAFTA Modu: Son 4 hafta - Her hafta için günlerin baş harfleri
      for (int i = 3; i >= 0; i--) {
        final weekStart = now.subtract(Duration(days: now.weekday - 1 + i * 7));
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

        // Haftanın ilk gününün baş harfini al (Pazartesi=1, Salı=2, ..., Pazar=7)
        final dayLabels = ['P', 'S', 'Ç', 'P', 'C', 'C', 'P']; // Pazartesi, Salı, Çarşamba, Perşembe, Cuma, Cumartesi, Pazar
        final firstDayOfWeek = weekStart.weekday; // 1=Pazartesi, 7=Pazar
        final label = dayLabels[firstDayOfWeek - 1]; // Haftanın ilk gününün baş harfi

        data.add(ChartDataPoint(
          label: label,
          drinkAmounts: drinkAmounts,
          date: weekStart,
        ));
      }
    } else {
      // AY Modu: Son 5 ay (Aralık başta: Ara, Oca, Şub, Mar, Nis)
      // Aralık'tan geriye doğru 5 ay
      const monthLabels = ['Ara', 'Oca', 'Şub', 'Mar', 'Nis'];

      // Mevcut ayın indeksini al (1=Ocak, 12=Aralık)
      int currentMonth = now.month;
      int currentYear = now.year;

      // Son 5 ayı oluştur (Aralık başta)
      for (int i = 0; i < 5; i++) {
        // Geriye doğru say (Aralık, Kasım, Ekim, Eylül, Ağustos)
        int monthOffset = 4 - i; // 4, 3, 2, 1, 0
        int targetMonth = currentMonth - monthOffset;
        int targetYear = currentYear;

        // Yıl geçişi kontrolü
        while (targetMonth <= 0) {
          targetMonth += 12;
          targetYear -= 1;
        }

        final monthDate = DateTime(targetYear, targetMonth, 1);
        final nextMonth = targetMonth == 12
            ? DateTime(targetYear + 1, 1, 1)
            : DateTime(targetYear, targetMonth + 1, 1);
        final monthEnd = nextMonth.subtract(const Duration(days: 1));
        final entries = waterProvider.getDrinkEntriesForDateRange(monthDate, monthEnd);

        // Filtre uygula
        final filteredEntries = selectedDrinkFilters.isEmpty
            ? entries
            : entries.where((e) => selectedDrinkFilters.contains(e.drinkId)).toList();

        // İçecek bazında grupla
        final drinkAmounts = <String, double>{};
        for (var entry in filteredEntries) {
          drinkAmounts[entry.drinkId] = (drinkAmounts[entry.drinkId] ?? 0) + entry.amount;
        }

        // Etiket: Sırasıyla 'Ara', 'Oca', 'Şub', 'Mar', 'Nis'
        data.add(ChartDataPoint(
          label: monthLabels[i],
          drinkAmounts: drinkAmounts,
          date: monthDate,
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

      // Önemli içecekleri sırayla ekle
      final importantDrinks = ['water', 'coffee', 'tea', 'soda'];
      for (var drinkId in importantDrinks) {
        final amount = drinkAmounts[drinkId] ?? 0.0;
        if (amount > 0) {
          rodStackItems.add(
            BarChartRodStackItem(
              currentY, // fromY
              currentY + amount, // toY
              ChartDataService.drinkColors[drinkId] ?? Colors.grey,
            ),
          );
          currentY += amount;
        }
      }

      // Diğer içecekleri ekle
      for (var entry in drinkAmounts.entries) {
        if (!importantDrinks.contains(entry.key) && entry.value > 0) {
          rodStackItems.add(
            BarChartRodStackItem(
              currentY, // fromY
              currentY + entry.value, // toY
              drinkColors[entry.key] ?? Colors.grey,
            ),
          );
          currentY += entry.value;
        }
      }

      // Tek bir BarChartRodData ile stacked bar oluştur
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: totalAmount,
            width: selectedPeriod == ChartPeriod.month ? 12.0 : 20.0,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            rodStackItems: rodStackItems.isNotEmpty ? rodStackItems : null,
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
