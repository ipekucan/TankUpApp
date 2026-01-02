import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/chart_data_service.dart'
    show ChartDataService, ChartDataPoint, ChartPeriod;
import '../../utils/drink_helpers.dart';
import '../../utils/unit_converter.dart';
import '../../utils/date_helpers.dart';
import '../../utils/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/history/chart_view.dart';
import '../../models/drink_model.dart';

/// Statistics tab content for SuccessScreen.
/// Refactored with unified card and drink history list.
class StatisticsTab extends StatefulWidget {
  final Widget? lightbulbButton;
  final String? dateText;

  const StatisticsTab({
    super.key,
    this.lightbulbButton,
    this.dateText,
  });

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  ChartPeriod _selectedPeriod = ChartPeriod.day;
  Set<String> _selectedDrinkFilters = {}; // Boş = Tümü
  int? _touchedBarIndex;
  List<ChartDataPoint> _lastChartData = const <ChartDataPoint>[];

  @override
  void initState() {
    super.initState();
    _selectedPeriod = ChartPeriod.day;
    _touchedBarIndex = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Date Text (Left-aligned, below header)
        if (widget.dateText != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.dateText!,
                style: AppTextStyles.dateText,
              ),
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Scrollable Content
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                sliver: SliverToBoxAdapter(
                  child: _buildUnifiedStatisticsCard(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              _buildDrinkHistorySliver(),
            ],
          ),
        ),
      ],
    );
  }

  /// Unified Statistics Card with filter button, period selector, and chart
  /// Premium design with subtle gradient background and enhanced shadows
  Widget _buildUnifiedStatisticsCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF5F9FF), // Very light blue tint
            Color(0xFFF0F7FE), // Slightly more blue but still light
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFE3EEF9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Row 1: Filter Button (Left) + Period Selector (Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Circular Beverage Filter Button
              _buildFilterButton(context),
              const SizedBox(width: 16),
              // Time Segment Control (Period Selector) - Expanded to fill space
              Expanded(
                child: _buildCompactPeriodSelector(),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Dynamic Range Label (Centered, No background)
          Center(
            child: Text(
              _getRangeLabel(),
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Row 2: Chart (compact height, without title)
          SizedBox(
            height: 180.0,
            child: Selector<HistoryProvider, _ChartComputeKey>(
              selector: (context, historyProvider) => _ChartComputeKey(
                historyRevision: historyProvider.historyRevision,
                period: _selectedPeriod,
                filtersKey: _filtersKey(_selectedDrinkFilters),
              ),
              builder: (context, computeKey, child) {
                final historyProvider = context.read<HistoryProvider>();
                return _DeferredChartView(
                  historyProvider: historyProvider,
                  computeKey: computeKey,
                  selectedPeriod: _selectedPeriod,
                  selectedDrinkFilters: _selectedDrinkFilters,
                  initialChartData: _lastChartData,
                  touchedBarIndex: _touchedBarIndex ?? -1,
                  onBarTouched: (int? index) {
                    setState(() {
                      _touchedBarIndex = index;
                    });
                  },
                  onChartDataComputed: (data) {
                    if (!mounted) return;
                    // Avoid unnecessary setState loops.
                    if (identical(_lastChartData, data)) return;
                    setState(() {
                      _lastChartData = data;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Compact Period Selector with short labels (Gün, Hafta, Ay)
  /// Wrapped in a visible light gray container
  Widget _buildCompactPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8), // More visible light gray
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: _buildCompactPeriodButton('Gün', ChartPeriod.day)),
          const SizedBox(width: 4),
          Expanded(child: _buildCompactPeriodButton('Hafta', ChartPeriod.week)),
          const SizedBox(width: 4),
          Expanded(child: _buildCompactPeriodButton('Ay', ChartPeriod.month)),
        ],
      ),
    );
  }

  Widget _buildCompactPeriodButton(String label, ChartPeriod period) {
    final isActive = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
          _touchedBarIndex = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: 34.0,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2D3748) : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF4B5563), // Darker gray when inactive
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13.0,
            height: 1.0,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// Dynamic Range Label based on selected period
  String _getRangeLabel() {
    switch (_selectedPeriod) {
      case ChartPeriod.day:
        return 'Son 7 Gün';
      case ChartPeriod.week:
        return 'Son 4 Hafta';
      case ChartPeriod.month:
        return 'Son 6 Ay';
    }
  }

  /// Drink History list as a SliverList (lazy rendering) to prevent UI freezes on resume.
  Widget _buildDrinkHistorySliver() {
    return Selector<HistoryProvider, _HistoryListComputeKey>(
      selector: (context, historyProvider) => _HistoryListComputeKey(
        historyRevision: historyProvider.historyRevision,
        period: _selectedPeriod,
        filtersKey: _filtersKey(_selectedDrinkFilters),
        touchedBarIndex: _touchedBarIndex,
        chartKey: _ChartComputeKey(
          historyRevision: historyProvider.historyRevision,
          period: _selectedPeriod,
          filtersKey: _filtersKey(_selectedDrinkFilters),
        ),
      ),
      builder: (context, computeKey, child) {
        final historyProvider = context.read<HistoryProvider>();
        return _DeferredHistoryListSliver(
          historyProvider: historyProvider,
          computeKey: computeKey,
          selectedPeriod: _selectedPeriod,
          selectedDrinkFilters: _selectedDrinkFilters,
          touchedBarIndex: _touchedBarIndex,
          chartData: _lastChartData,
        );
      },
    );
  }

  // Note: history item UI is implemented as a top-level helper to allow reuse from slivers.

  /// Filter Button (Circular Beverage Filter)
  Widget _buildFilterButton(BuildContext context) {
    final hasFilters = _selectedDrinkFilters.isNotEmpty;
    return GestureDetector(
      onTap: () => _showFilterBottomSheet(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hasFilters
              ? const Color(0xFF4F8EF7).withValues(alpha: 0.15)
              : Colors.white,
          border: Border.all(
            color: hasFilters
                ? const Color(0xFF4F8EF7)
                : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildCustomDrinkIcon(),
            Positioned(
              bottom: 2,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: hasFilters
                    ? const Color(0xFF4F8EF7)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Custom Drink Icon (3 colored circles)
  Widget _buildCustomDrinkIcon() {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Blue circle (Water)
          Positioned(
            left: 4,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Brown circle (Coffee)
          Positioned(
            top: 4,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.brown,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Orange circle (Soda)
          Positioned(
            right: 4,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show Filter Bottom Sheet
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Consumer<HistoryProvider>(
          builder: (context, historyProvider, child) {
            final today = DateTime.now();
            final todayKey = DateHelpers.toDateKey(today);
            final todayEntries = historyProvider.getDrinkEntriesForDate(todayKey);

            return _FilterBottomSheetContent(
              initialFilters: _selectedDrinkFilters,
              onApply: (filters) {
                setState(() {
                  _selectedDrinkFilters = filters;
                });
              },
              historyProvider: historyProvider,
              todayEntries: todayEntries,
              drinkAmounts: {},
            );
          },
        ),
      ),
    );
  }
}

String _filtersKey(Set<String> filters) {
  if (filters.isEmpty) return '';
  final list = filters.toList()..sort();
  return list.join(',');
}

class _HistoryListComputeKey {
  final int historyRevision;
  final ChartPeriod period;
  final String filtersKey;
  final int? touchedBarIndex;
  final _ChartComputeKey chartKey;

  const _HistoryListComputeKey({
    required this.historyRevision,
    required this.period,
    required this.filtersKey,
    required this.touchedBarIndex,
    required this.chartKey,
  });

  @override
  bool operator ==(Object other) {
    return other is _HistoryListComputeKey &&
        other.historyRevision == historyRevision &&
        other.period == period &&
        other.filtersKey == filtersKey &&
        other.touchedBarIndex == touchedBarIndex &&
        other.chartKey == chartKey;
  }

  @override
  int get hashCode =>
      Object.hash(historyRevision, period, filtersKey, touchedBarIndex, chartKey);
}

class _ChartComputeKey {
  final int historyRevision;
  final ChartPeriod period;
  final String filtersKey;

  const _ChartComputeKey({
    required this.historyRevision,
    required this.period,
    required this.filtersKey,
  });

  @override
  bool operator ==(Object other) {
    return other is _ChartComputeKey &&
        other.historyRevision == historyRevision &&
        other.period == period &&
        other.filtersKey == filtersKey;
  }

  @override
  int get hashCode => Object.hash(historyRevision, period, filtersKey);
}

class _DeferredHistoryListSliver extends StatefulWidget {
  final HistoryProvider historyProvider;
  final _HistoryListComputeKey computeKey;
  final ChartPeriod selectedPeriod;
  final Set<String> selectedDrinkFilters;
  final int? touchedBarIndex;
  final List<ChartDataPoint> chartData;

  const _DeferredHistoryListSliver({
    required this.historyProvider,
    required this.computeKey,
    required this.selectedPeriod,
    required this.selectedDrinkFilters,
    required this.touchedBarIndex,
    required this.chartData,
  });

  @override
  State<_DeferredHistoryListSliver> createState() => _DeferredHistoryListSliverState();
}

class _DeferredHistoryListSliverState extends State<_DeferredHistoryListSliver> {
  List<dynamic> _entries = const [];

  @override
  void initState() {
    super.initState();
    _scheduleRecompute();
  }

  @override
  void didUpdateWidget(covariant _DeferredHistoryListSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.computeKey != widget.computeKey) {
      _scheduleRecompute();
    }
  }

  void _scheduleRecompute() {
    final scheduledKey = widget.computeKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (scheduledKey != widget.computeKey) return;

      DateTime? selectedStartDate;
      DateTime? selectedEndDate;

      if (widget.touchedBarIndex != null &&
          widget.touchedBarIndex! >= 0 &&
          widget.touchedBarIndex! < widget.chartData.length) {
        final dataPoint = widget.chartData[widget.touchedBarIndex!];
        selectedStartDate = dataPoint.date;
        selectedEndDate = dataPoint.date;
      } else {
        switch (widget.selectedPeriod) {
          case ChartPeriod.day:
            selectedStartDate = DateTime.now();
            selectedEndDate = selectedStartDate;
            break;
          case ChartPeriod.week:
            final today = DateTime.now();
            final weekStart = today.subtract(Duration(days: today.weekday - 1));
            selectedStartDate = weekStart;
            selectedEndDate = weekStart.add(const Duration(days: 6));
            break;
          case ChartPeriod.month:
            final today = DateTime.now();
            selectedStartDate = DateTime(today.year, today.month, 1);
            selectedEndDate = DateTime(today.year, today.month + 1, 0);
            break;
        }
      }

      final entries = widget.historyProvider.getDrinkEntriesForDateRange(
        selectedStartDate,
        selectedEndDate,
      );

      final filteredEntries = widget.selectedDrinkFilters.isEmpty
          ? entries
          : entries.where((e) => widget.selectedDrinkFilters.contains(e.drinkId)).toList();

      final sortedEntries = List.from(filteredEntries)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (!mounted) return;
      if (scheduledKey != widget.computeKey) return;

      setState(() {
        _entries = sortedEntries;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (_entries.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'Henüz sıvı alımı yapılmadı.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18.0,
                  ),
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final entry = _entries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: _buildDrinkHistoryItemWidget(entry, userProvider.isMetric),
              );
            },
            childCount: _entries.length,
          ),
        );
      },
    );
  }
}

/// Individual Drink History List Item (ListTile style)
Widget _buildDrinkHistoryItemWidget(dynamic entry, bool isMetric) {
  final drinkId = entry.drinkId;
  final amount = entry.amount;
  final timestamp = entry.timestamp;
  final emoji = DrinkHelpers.getEmoji(drinkId);
  final color = ChartDataService.drinkColors[drinkId] ?? Colors.grey;
  final drinkName = DrinkHelpers.getName(drinkId);

  // Format time from timestamp (timestamp is already a DateTime)
  final timeString =
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

  return Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF5F9FF), // Very light blue tint (same as statistics card)
          Color(0xFFF0F7FE), // Slightly more blue but still light
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: const Color(0xFFE3EEF9),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
      title: Text(
        drinkName,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        UnitConverter.formatVolume(amount, isMetric),
        style: AppTextStyles.bodyMedium.copyWith(
          color: color,
          fontSize: 12,
        ),
      ),
      trailing: Text(
        timeString,
        style: AppTextStyles.bodyMedium.copyWith(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
    ),
  );
}

class _DeferredChartView extends StatefulWidget {
  final HistoryProvider historyProvider;
  final _ChartComputeKey computeKey;
  final ChartPeriod selectedPeriod;
  final Set<String> selectedDrinkFilters;
  final List<ChartDataPoint> initialChartData;
  final int touchedBarIndex;
  final ValueChanged<int?> onBarTouched;
  final ValueChanged<List<ChartDataPoint>>? onChartDataComputed;

  const _DeferredChartView({
    required this.historyProvider,
    required this.computeKey,
    required this.selectedPeriod,
    required this.selectedDrinkFilters,
    required this.initialChartData,
    required this.touchedBarIndex,
    required this.onBarTouched,
    this.onChartDataComputed,
  });

  @override
  State<_DeferredChartView> createState() => _DeferredChartViewState();
}

class _DeferredChartViewState extends State<_DeferredChartView> {
  late List<ChartDataPoint> _chartData;

  @override
  void initState() {
    super.initState();
    _chartData = widget.initialChartData;
    _scheduleRecompute();
  }

  @override
  void didUpdateWidget(covariant _DeferredChartView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.computeKey != widget.computeKey) {
      _scheduleRecompute();
    }
  }

  void _scheduleRecompute() {
    final scheduledKey = widget.computeKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // If inputs changed again before this callback executed, skip and let the latest schedule run.
      if (scheduledKey != widget.computeKey) return;

      final data = ChartDataService.buildChartData(
        widget.historyProvider,
        widget.selectedPeriod,
        widget.selectedDrinkFilters,
      );

      if (!mounted) return;
      // If inputs changed while computing, don't apply stale results.
      if (scheduledKey != widget.computeKey) return;

      setState(() {
        _chartData = data;
      });
      widget.onChartDataComputed?.call(data);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChartView(
      chartData: _chartData,
      selectedPeriod: widget.selectedPeriod,
      touchedBarIndex: widget.touchedBarIndex,
      onBarTouched: widget.onBarTouched,
    );
  }
}

// Filter Bottom Sheet Content (reuse from HistoryScreen)
class _FilterBottomSheetContent extends StatefulWidget {
  final Set<String> initialFilters;
  final Function(Set<String>) onApply;
  final HistoryProvider historyProvider;
  final List todayEntries;
  final Map<String, double> drinkAmounts;

  const _FilterBottomSheetContent({
    required this.initialFilters,
    required this.onApply,
    required this.historyProvider,
    required this.todayEntries,
    required this.drinkAmounts,
  });

  @override
  State<_FilterBottomSheetContent> createState() =>
      _FilterBottomSheetContentState();
}

class _FilterBottomSheetContentState extends State<_FilterBottomSheetContent> {
  late Set<String> _dialogSelectedFilters;

  @override
  void initState() {
    super.initState();
    _dialogSelectedFilters = Set<String>.from(widget.initialFilters);
  }

  @override
  Widget build(BuildContext context) {
    final allDrinks = DrinkData.getDrinks();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('İçecek Filtresi', style: AppTextStyles.heading3),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: _dialogSelectedFilters.isEmpty ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: _dialogSelectedFilters.isEmpty
                        ? AppColors.softPinkButton
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _dialogSelectedFilters.clear();
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _dialogSelectedFilters.isEmpty
                                  ? AppColors.softPinkButton
                                  : Colors.grey[400]!,
                              width: 2,
                            ),
                            color: _dialogSelectedFilters.isEmpty
                                ? AppColors.softPinkButton
                                : Colors.transparent,
                          ),
                          child: _dialogSelectedFilters.isEmpty
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.all_inclusive,
                          size: 32,
                          color: Color(0xFF4A5568),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text('Tümü', style: AppTextStyles.bodyLarge),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ...allDrinks.map((drink) {
                final isSelected = _dialogSelectedFilters.contains(drink.id);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isSelected ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.softPinkButton
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _dialogSelectedFilters.remove(drink.id);
                        } else {
                          _dialogSelectedFilters.add(drink.id);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.softPinkButton
                                    : Colors.grey[400]!,
                                width: 2,
                              ),
                              color: isSelected
                                  ? AppColors.softPinkButton
                                  : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            DrinkHelpers.getEmoji(drink.id),
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              drink.name,
                              style: AppTextStyles.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _dialogSelectedFilters.clear();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Temizle'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(Set<String>.from(_dialogSelectedFilters));
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.softPinkButton,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Uygula'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}