import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/chart_data_service.dart';
import '../../utils/app_colors.dart';

class DeferredChartView extends StatefulWidget {
  final List<ChartDataPoint> chartData;
  final int? touchedBarIndex;
  final Function(int? touchedIndex)? onBarTouched;
  final bool isLoading;
  final ChartPeriod? period; // Add period for change detection

  const DeferredChartView({
    super.key,
    required this.chartData,
    required this.touchedBarIndex,
    this.onBarTouched,
    this.isLoading = false,
    this.period,
  });

  @override
  State<DeferredChartView> createState() => _DeferredChartViewState();
}

class _DeferredChartViewState extends State<DeferredChartView> {
  final ValueNotifier<bool> _isChartReady = ValueNotifier<bool>(false);
  ChartPeriod? _lastPeriod;

  @override
  void initState() {
    super.initState();
    _lastPeriod = widget.period;
    _prepareChart();
  }

  @override
  void didUpdateWidget(DeferredChartView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If period changed, reset chart immediately
    if (widget.period != _lastPeriod) {
      _lastPeriod = widget.period;
      _isChartReady.value = false;
      _prepareChart();
    }
  }

  void _prepareChart() {
    // Immediate rendering for better performance (no delay)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _isChartReady.value = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isChartReady,
      builder: (context, isReady, child) {
        if (widget.isLoading || !isReady) {
          // Show loading indicator
          return SizedBox(
            height: 200,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
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
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Veri yok',
            style: TextStyle(
              color: AppColors.textTertiary,
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
              getTooltipColor: (group) => AppColors.textPrimary.withValues(alpha: 0.9),
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final point = widget.chartData[groupIndex];
                final totalAmount = point.drinkAmounts.values.fold<double>(0, (a, b) => a + b);
                return BarTooltipItem(
                  '${totalAmount.toInt()} ml',
                  TextStyle(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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
        
        // Build stacked bar with drink-specific colors
        return _buildStackedBarGroup(index, point);
      },
    );
  }

  BarChartGroupData _buildStackedBarGroup(int index, ChartDataPoint point) {
    final rodStackItems = <BarChartRodStackItem>[];
    double currentY = 0.0;

    // Priority drinks first (water, coffee, tea, soda)
    final priorityDrinks = ['water', 'coffee', 'tea', 'soda'];
    for (var drinkId in priorityDrinks) {
      final amount = point.drinkAmounts[drinkId] ?? 0.0;
      if (amount > 0) {
        final color = ChartDataService.drinkColors[drinkId] ?? AppColors.secondaryAqua;
        rodStackItems.add(
          BarChartRodStackItem(currentY, currentY + amount, color),
        );
        currentY += amount;
      }
    }

    // Other drinks
    for (var entry in point.drinkAmounts.entries) {
      if (!priorityDrinks.contains(entry.key) && entry.value > 0) {
        final color = ChartDataService.drinkColors[entry.key] ?? AppColors.secondaryAqua;
        rodStackItems.add(
          BarChartRodStackItem(currentY, currentY + entry.value, color),
        );
        currentY += entry.value;
      }
    }

    final totalAmount = point.drinkAmounts.values.fold<double>(0, (a, b) => a + b);

    return BarChartGroupData(
      x: index,
      barsSpace: 4,
      barRods: [
        BarChartRodData(
          toY: totalAmount,
          width: 20,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
          rodStackItems: rodStackItems.isNotEmpty ? rodStackItems : null,
          color: rodStackItems.isEmpty ? AppColors.cardBorder : null,
        ),
      ],
    );
  }

  FlTitlesData _getTitleData() {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 36,
          getTitlesWidget: (value, meta) {
            if (value < 0 || value >= widget.chartData.length) {
              return const Text('');
            }
            final point = widget.chartData[value.toInt()];
            return SideTitleWidget(
              axisSide: meta.axisSide,
              space: 4,
              child: Text(
                _formatXAxisLabel(point),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
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
    return point.label;
  }
}