import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/user_provider.dart';
import '../../services/chart_data_service.dart' show ChartDataService, ChartDataPoint, ChartPeriod;
import '../../utils/unit_converter.dart';
import 'chart_theme.dart';

/// Chart view widget for displaying bar chart.
/// Handles the visual rendering of chart data.
/// Implements tap-to-toggle tooltip interaction.
class ChartView extends StatefulWidget {
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
  State<ChartView> createState() => _ChartViewState();
}

class _ChartViewState extends State<ChartView> {
  int _touchedIndex = -1;

  @override
  void didUpdateWidget(ChartView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset touched index when period changes
    if (oldWidget.selectedPeriod != widget.selectedPeriod) {
      _touchedIndex = -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chartData.isEmpty) {
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
        return AspectRatio(
          key: ValueKey(widget.selectedPeriod),
          aspectRatio: 1.6,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              BarChart(
                _buildBarChartData(userProvider),
              ),
              // Custom persistent tooltip overlay
              if (_touchedIndex >= 0 && _touchedIndex < widget.chartData.length)
                _buildPersistentTooltip(context, userProvider),
            ],
          ),
        );
      },
    );
  }

  /// Builds a persistent tooltip overlay that shows when a bar is selected.
  /// Premium design with shadow and smooth animation.
  Widget _buildPersistentTooltip(BuildContext context, UserProvider userProvider) {
    // Safety checks
    if (widget.chartData.isEmpty || _touchedIndex < 0 || _touchedIndex >= widget.chartData.length) {
      return const SizedBox.shrink();
    }

    final barGroups = ChartDataService.buildBarGroups(
      widget.chartData,
      widget.selectedPeriod,
      {},
    );
    
    if (_touchedIndex >= barGroups.length || barGroups.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final touchedGroup = barGroups[_touchedIndex];
    double totalValue = 0;
    if (touchedGroup.barRods.isNotEmpty) {
      totalValue = touchedGroup.barRods.last.toY;
    }

    final formattedValue = UnitConverter.formatVolume(totalValue, userProvider.isMetric);
    final dataLabel = widget.chartData[_touchedIndex].label;

    // Calculate approximate position based on bar index
    final screenWidth = MediaQuery.of(context).size.width;
    final chartWidth = screenWidth - 32; // Account for padding
    final barCount = widget.chartData.length;
    
    // Prevent division by zero
    if (barCount == 0) {
      return const SizedBox.shrink();
    }
    
    final barWidth = chartWidth / barCount;
    final tooltipX = (_touchedIndex * barWidth) + (barWidth / 2) - 45; // Center of bar

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      left: tooltipX.clamp(0.0, screenWidth - 100),
      top: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: ChartTheme.tooltipBackgroundColor,
            borderRadius: BorderRadius.circular(ChartTheme.tooltipBorderRadius),
            boxShadow: ChartTheme.tooltipShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formattedValue,
                style: ChartTheme.tooltipTextStyle,
              ),
              const SizedBox(height: 2),
              Text(
                dataLabel,
                style: ChartTheme.tooltipTextStyle.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the BarChartData with proper X-axis alignment and tap-to-toggle interaction.
  BarChartData _buildBarChartData(UserProvider userProvider) {
    final groupsSpace = ChartTheme.groupsSpace;
    final barGroups = ChartDataService.buildBarGroups(
      widget.chartData,
      widget.selectedPeriod,
      {},
    );

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: ChartDataService.getMaxY(widget.chartData),
      groupsSpace: groupsSpace,
      barTouchData: BarTouchData(
        enabled: true,
        handleBuiltInTouches: false, // Disable default "hold" behavior
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (group) => ChartTheme.tooltipBackgroundColor,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            // Only show tooltip if this bar is the touched one and index is valid
            if (groupIndex != _touchedIndex || 
                _touchedIndex < 0 || 
                _touchedIndex >= widget.chartData.length) {
              // Return empty tooltip item instead of null to avoid crashes
              return BarTooltipItem('', const TextStyle(fontSize: 0));
            }

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
          if (event is FlTapUpEvent) {
            // Tap to toggle behavior
            if (barTouchResponse != null && 
                barTouchResponse.spot != null &&
                barTouchResponse.spot!.touchedBarGroupIndex >= 0 &&
                barTouchResponse.spot!.touchedBarGroupIndex < widget.chartData.length) {
              final tappedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
              if (mounted) {
                setState(() {
                  // Toggle: if same bar tapped again, deselect; otherwise select new bar
                  _touchedIndex = (_touchedIndex == tappedIndex) ? -1 : tappedIndex;
                });
                // Notify parent about the touched bar
                widget.onBarTouched(_touchedIndex >= 0 ? _touchedIndex : null);
              }
            } else {
              // Tapped on empty space - deselect
              if (mounted) {
                setState(() {
                  _touchedIndex = -1;
                });
                widget.onBarTouched(null);
              }
            }
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
            interval: 1, // Ensure every bar gets a label
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              // Only show labels for valid indices (0 to length-1)
              if (index >= 0 && index < widget.chartData.length) {
                String label = _getBottomLabel(index, widget.selectedPeriod, widget.chartData);
                if (label.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: ChartTheme.axisLabelPadding,
                  child: Text(
                    label,
                    style: ChartTheme.axisLabelStyle,
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox.shrink();
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
      barGroups: barGroups,
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

