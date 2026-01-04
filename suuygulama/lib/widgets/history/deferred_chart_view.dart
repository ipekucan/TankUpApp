import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/chart_data_service.dart';

class DeferredChartView extends StatefulWidget {
  final List<ChartDataPoint> chartData;
  final int? touchedBarIndex;
  final Function(int? touchedIndex)? onBarTouched;
  final bool isLoading;

  const DeferredChartView({
    super.key,
    required this.chartData,
    required this.touchedBarIndex,
    this.onBarTouched,
    this.isLoading = false,
  });

  @override
  State<DeferredChartView> createState() => _DeferredChartViewState();
}

class _DeferredChartViewState extends State<DeferredChartView> {
  final ValueNotifier<bool> _isChartReady = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    // Delay chart rendering to prevent performance issues during screen transitions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300)).then((_) {
        if (mounted) {
          _isChartReady.value = true;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isChartReady,
      builder: (context, isReady, child) {
        if (widget.isLoading || !isReady) {
          // Show loading indicator or empty state
          return Container(
            height: 200,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                ),
              ),
            ),
          );
        }

        return _buildChart();
      },
    );
  }

  Widget _buildChart() {
    if (widget.chartData.isEmpty) {
      return Container(
        height: 200,
        child: const Center(
          child: Text(
            'Veri yok',
            style: TextStyle(
              color: Color(0xFFA0AEC0),
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceEvenly,
          maxY: _calculateMaxValue(),
          barGroups: _buildBarGroups(),
          borderData: FlBorderData(show: false),
          titlesData: _getTitleData(),
          gridData: const FlGridData(
            show: false,
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.grey[800]!,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final point = widget.chartData[groupIndex];
                final totalAmount = point.drinkAmounts.values.fold<double>(0, (a, b) => a + b);
                return BarTooltipItem(
                  '${totalAmount.toInt()} ml',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            touchCallback: (FlTouchEvent event, barTouchResponse) {
              if (widget.onBarTouched != null) {
                if (event is FlTapUpEvent && barTouchResponse != null && barTouchResponse.spot != null) {
                  widget.onBarTouched!(barTouchResponse.spot!.touchedBarGroupIndex);
                } else {
                  widget.onBarTouched!(null);
                }
              }
            },
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(
      widget.chartData.length,
      (index) {
        final point = widget.chartData[index];
        final totalAmount = point.drinkAmounts.values.fold<double>(0, (a, b) => a + b);

        return BarChartGroupData(
          x: index,
          barsSpace: 4,
          barRods: [
            BarChartRodData(
              toY: totalAmount,
              color: widget.touchedBarIndex == index
                  ? const Color(0xFF8B4513)
                  : const Color(0xFFD6B689),
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              borderSide: BorderSide(
                color: widget.touchedBarIndex == index
                    ? const Color(0xFF8B4513)
                    : const Color(0xFFD6B689),
                width: 1,
              ),
            ),
          ],
        );
      },
    );
  }

  FlTitlesData _getTitleData() {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (value, meta) {
            if (value < 0 || value >= widget.chartData.length) {
              return const Text('');
            }
            final point = widget.chartData[value.toInt()];
            // For day period, show day/month; for other periods, show month abbreviation
            return SideTitleWidget(
              axisSide: meta.axisSide,
              space: 4,
              child: Text(
                _formatXAxisLabel(point),
                style: const TextStyle(
                  color: Color(0xFF718096),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: const AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: 500,
        ),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );
  }

  double _calculateMaxValue() {
    if (widget.chartData.isEmpty) return 1000;
    final maxAmount = widget.chartData
        .map((point) => point.drinkAmounts.values.fold<double>(0, (a, b) => a + b))
        .reduce((a, b) => a > b ? a : b);
    return maxAmount > 0 ? maxAmount * 1.2 : 1000;
  }

  String _formatXAxisLabel(ChartDataPoint point) {
    // This method formats the X-axis labels based on the chart period
    // In the actual implementation, this would use the ChartPeriod enum
    // For now, we'll use a simple date format
    return '${point.date.day}.${point.date.month}';
  }
}