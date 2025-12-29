import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/user_provider.dart';
import '../../services/chart_data_service.dart' show ChartDataService, ChartDataPoint, ChartPeriod;
import '../../utils/unit_converter.dart';

/// Chart view widget for displaying bar chart.
/// Handles the visual rendering of chart data.
class ChartView extends StatelessWidget {
  final List<ChartDataPoint> chartData;
  final ChartPeriod selectedPeriod;
  final int touchedBarIndex;
  final ValueChanged<int?> onBarTouched;

  const ChartView({
    super.key,
    required this.chartData,
    required this.selectedPeriod,
    required this.touchedBarIndex,
    required this.onBarTouched,
  });

  @override
  Widget build(BuildContext context) {
    if (chartData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Henüz veri yok',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 18.0,
            ),
          ),
        ),
      );
    }

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Ay modu için bar genişliği ve aralık ayarları
        final isMonthMode = selectedPeriod == ChartPeriod.month;
        final groupsSpace = isMonthMode ? 4.0 : 8.0;

        // Aylık mod için normal görünüm (5 sütun, kaydırma gerekmez)
        if (isMonthMode) {
          return AspectRatio(
            aspectRatio: 1.6,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: ChartDataService.getMaxY(chartData),
                groupsSpace: groupsSpace,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      // Toplam değeri hesapla (stacked bar için tüm rod'ların toplamı)
                      double totalValue = 0;
                      if (group.barRods.isNotEmpty) {
                        // En üstteki rod'un toY değeri toplamı verir
                        totalValue = group.barRods.last.toY;
                      }

                      // Birim formatını kullan
                      final formattedValue = UnitConverter.formatVolume(totalValue, userProvider.isMetric);

                      return BarTooltipItem(
                        formattedValue,
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      );
                    },
                    tooltipRoundedRadius: 8,
                  ),
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    if (event.isInterestedForInteractions &&
                        barTouchResponse != null &&
                        barTouchResponse.spot != null) {
                      onBarTouched(barTouchResponse.spot!.touchedBarGroupIndex);
                    } else {
                      onBarTouched(null);
                    }
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < chartData.length) {
                          String label = _getBottomLabel(value.toInt(), selectedPeriod, chartData);
                          if (label.isEmpty) return const Text('');

                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              label,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 11.0,
                                fontWeight: FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 32,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                ),
                gridData: const FlGridData(
                  show: false,
                ),
                borderData: FlBorderData(show: false),
                barGroups: ChartDataService.buildBarGroups(
                  chartData,
                  selectedPeriod,
                  {},
                ),
              ),
            ),
          );
        }

        // Gün ve Hafta modları için normal görünüm
        return AspectRatio(
          aspectRatio: 1.6,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: ChartDataService.getMaxY(chartData),
              groupsSpace: groupsSpace,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => Colors.black87,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    // Toplam değeri hesapla (stacked bar için tüm rod'ların toplamı)
                    double totalValue = 0;
                    if (group.barRods.isNotEmpty) {
                      // En üstteki rod'un toY değeri toplamı verir
                      totalValue = group.barRods.last.toY;
                    }

                    // Birim formatını kullan
                    final formattedValue = UnitConverter.formatVolume(totalValue, userProvider.isMetric);

                    return BarTooltipItem(
                      formattedValue,
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    );
                  },
                  tooltipRoundedRadius: 8,
                ),
                touchCallback: (FlTouchEvent event, barTouchResponse) {
                  if (event.isInterestedForInteractions &&
                      barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    onBarTouched(barTouchResponse.spot!.touchedBarGroupIndex);
                  } else {
                    onBarTouched(null);
                  }
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < chartData.length) {
                        String label = _getBottomLabel(value.toInt(), selectedPeriod, chartData);
                        if (label.isEmpty) return const Text('');

                        // Haftalık mod için büyük ve bold yazı
                        if (selectedPeriod == ChartPeriod.week) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: Color(0xFF2C3E50),
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        // Gün modu için bold ve büyük yazı
                        if (selectedPeriod == ChartPeriod.day) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              label,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        // Ay modu için normal stil
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: selectedPeriod == ChartPeriod.day ||
                            selectedPeriod == ChartPeriod.week
                        ? 40
                        : 32,
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
              ),
              gridData: const FlGridData(
                show: false,
              ),
              borderData: FlBorderData(show: false),
              barGroups: ChartDataService.buildBarGroups(
                chartData,
                selectedPeriod,
                {},
              ),
            ),
          ),
        );
      },
    );
  }

  /// Gets the bottom label for a given index and period.
  static String _getBottomLabel(
    int index,
    ChartPeriod period,
    List<ChartDataPoint> chartData,
  ) {
    if (index < 0 || index >= chartData.length) return '';

    if (period == ChartPeriod.day) {
      // Gün modu: 'P', 'S', 'Ç', 'P', 'C', 'C', 'P' (Pazartesi'den Pazar'a)
      const dayLabels = ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'];
      if (index < dayLabels.length) {
        return dayLabels[index];
      }
    } else if (period == ChartPeriod.week) {
      // Hafta modu: '1. Hafta', '2. Hafta', '3. Hafta', '4. Hafta'
      final weekIndex = index + 1;
      if (weekIndex >= 1 && weekIndex <= 4) {
        return '$weekIndex. Hafta';
      }
    } else if (period == ChartPeriod.month) {
      // Ay modu: 'Ara', 'Oca', 'Şub', 'Mar', 'Nis' (5 sütun, Aralık başta)
      const monthLabels = ['Ara', 'Oca', 'Şub', 'Mar', 'Nis'];
      if (index < monthLabels.length) {
        return monthLabels[index];
      }
    }

    return '';
  }
}

