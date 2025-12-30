import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/user_provider.dart';
import '../../services/chart_data_service.dart' show ChartDataService, ChartDataPoint, ChartPeriod;
import '../../utils/unit_converter.dart';
import 'chart_theme.dart';

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
        // Unified groups space for all periods
        final groupsSpace = ChartTheme.groupsSpace;

        // Aylık mod için normal görünüm (5 sütun, kaydırma gerekmez)
        if (selectedPeriod == ChartPeriod.month) {
          return AspectRatio(
            key: ValueKey(selectedPeriod),
            aspectRatio: 1.6,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: ChartDataService.getMaxY(chartData),
                groupsSpace: groupsSpace,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => ChartTheme.tooltipBackgroundColor,
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
                        ChartTheme.tooltipTextStyle,
                      );
                    },
                    tooltipRoundedRadius: ChartTheme.tooltipBorderRadius,
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
                            padding: ChartTheme.axisLabelPadding,
                            child: Text(
                              label,
                              style: ChartTheme.axisLabelStyle,
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: ChartTheme.bottomAxisReservedSize,
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
          key: ValueKey(selectedPeriod),
          aspectRatio: 1.6,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: ChartDataService.getMaxY(chartData),
              groupsSpace: groupsSpace,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => ChartTheme.tooltipBackgroundColor,
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
                      ChartTheme.tooltipTextStyle,
                    );
                  },
                  tooltipRoundedRadius: ChartTheme.tooltipBorderRadius,
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

                        // Unified styling for all periods
                        return Padding(
                          padding: ChartTheme.axisLabelPadding,
                          child: Text(
                            label,
                            style: ChartTheme.axisLabelStyle,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: ChartTheme.bottomAxisReservedSize,
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
  /// Uses the label from ChartDataPoint (which is dynamically calculated).
  static String _getBottomLabel(
    int index,
    ChartPeriod period,
    List<ChartDataPoint> chartData,
  ) {
    if (index < 0 || index >= chartData.length) return '';
    
    // Return the label from the data point (already calculated dynamically)
    return chartData[index].label;
  }
}

