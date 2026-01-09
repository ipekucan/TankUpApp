import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../providers/history_provider.dart';
import '../providers/user_provider.dart';
import '../providers/daily_hydration_provider.dart';
import '../utils/unit_converter.dart';
import '../utils/drink_helpers.dart';
import '../utils/date_helpers.dart';
import '../theme/app_text_styles.dart';
import '../services/chart_data_service.dart';
import '../widgets/history/deferred_chart_view.dart';
import '../widgets/history/period_selector.dart';
import '../widgets/history/history_filter_section.dart';
import '../widgets/history/history_statistics_section.dart';

/// HistoryScreen - High-performance hydration history and statistics display.
///
/// Architecture:
/// - Uses CustomScrollView with Slivers for efficient scrolling
/// - Selector-based state management to prevent unnecessary rebuilds
/// - Synchronous chart data rendering via ChartDataService cache
/// - Strict adherence to AppColors and AppTextStyles design system
class HistoryScreen extends StatefulWidget {
  final bool hideAppBar;

  const HistoryScreen({
    super.key,
    this.hideAppBar = false,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  ChartPeriod _selectedPeriod = ChartPeriod.day;
  int? _touchedBarIndex;
  Set<String> _selectedDrinkFilters = {}; // Empty = All drinks
  
  // Memoization cache
  List<ChartDataPoint>? _cachedChartData;
  int? _cachedRevision;
  ChartPeriod? _cachedPeriod;
  Set<String>? _cachedFilters;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              backgroundColor: AppColors.backgroundWhite,
              elevation: 0,
              centerTitle: false,
              title: Text(
                'Geçmiş',
                style: AppTextStyles.appBarTitle,
              ),
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header Section: Period Selector
          _buildPeriodSelectorSliver(),

          // Date Display Section
          _buildDateDisplaySliver(),

          // Chart Section
          _buildChartSliver(),

          // Statistics Cards Section
          _buildStatisticsSliver(),

          // History List Header
          _buildHistoryHeaderSliver(),

          // History Entries List
          _buildHistoryListSliver(),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  /// Period Selector Section with Filter Button
  Widget _buildPeriodSelectorSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            HistoryFilterButton(
              onTap: _showFilterBottomSheet,
              activeFilterCount: _selectedDrinkFilters.length,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PeriodSelector(
                selectedPeriod: _selectedPeriod,
                onPeriodChanged: (period) {
                  setState(() {
                    _selectedPeriod = period;
                    _touchedBarIndex = null;
                    // Invalidate cache when period changes
                    _cachedPeriod = null;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Date Display Section
  Widget _buildDateDisplaySliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          DateHelpers.getFormattedTurkishDate(),
          style: AppTextStyles.dateText.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// Chart Section with Memoized Data Calculation
  Widget _buildChartSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Label
              Center(
                child: Text(
                  _getPeriodLabel(),
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Chart with Memoized Data
              SizedBox(
                height: 200,
                child: Selector<HistoryProvider, int>(
                  selector: (context, historyProvider) => historyProvider.historyRevision,
                  builder: (context, revision, child) {
                    // Calculate chart data only if cache is invalid
                    final chartData = _getChartData(context, revision);

                    return DeferredChartView(
                      chartData: chartData,
                      touchedBarIndex: _touchedBarIndex,
                      period: _selectedPeriod,
                      onBarTouched: (index) {
                        setState(() {
                          _touchedBarIndex = index;
                        });
                      },
                      isLoading: false,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Memoized chart data calculation
  List<ChartDataPoint> _getChartData(BuildContext context, int revision) {
    // Check if cache is still valid
    final filtersChanged = _cachedFilters == null || 
        !_setEquals(_cachedFilters!, _selectedDrinkFilters);
    
    if (_cachedChartData != null &&
        _cachedRevision == revision &&
        _cachedPeriod == _selectedPeriod &&
        !filtersChanged) {
      // Cache hit - return cached data
      return _cachedChartData!;
    }
    
    // Cache miss - recalculate
    final historyProvider = context.read<HistoryProvider>();
    final newChartData = ChartDataService.buildChartData(
      historyProvider,
      _selectedPeriod,
      _selectedDrinkFilters,
    );
    
    // Update cache
    _cachedChartData = newChartData;
    _cachedRevision = revision;
    _cachedPeriod = _selectedPeriod;
    _cachedFilters = Set.from(_selectedDrinkFilters);
    
    return newChartData;
  }
  
  /// Helper to compare sets
  bool _setEquals(Set<String> set1, Set<String> set2) {
    if (set1.length != set2.length) return false;
    return set1.every((element) => set2.contains(element));
  }

  /// Statistics Cards Section
  Widget _buildStatisticsSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Selector<HistoryProvider, int>(
          selector: (context, historyProvider) => historyProvider.historyRevision,
          builder: (context, revision, child) {
            final historyProvider = context.read<HistoryProvider>();
            final userProvider = context.read<UserProvider>();
            final dailyHydrationProvider = context.read<DailyHydrationProvider>();
            final stats = _calculateStatistics(
              historyProvider,
              userProvider,
              dailyHydrationProvider,
            );

            return HistoryStatisticsSection(
              dailyAverage: stats['dailyAverage']!,
              completionRate: stats['completionRate']!,
              total: stats['total']!,
            );
          },
        ),
      ),
    );
  }

  /// History List Header
  Widget _buildHistoryHeaderSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Text(
          'Detaylı Geçmiş',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// History Entries List with Lazy Loading
  Widget _buildHistoryListSliver() {
    return Consumer2<HistoryProvider, UserProvider>(
      builder: (context, historyProvider, userProvider, child) {
        final entries = _getEntriesForPeriod(historyProvider);

        if (entries.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.water_drop_outlined,
                      size: 64,
                      color: AppColors.textTertiary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz sıvı alımı yapılmadı',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = entries[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildHistoryItem(entry, userProvider.isMetric),
                );
              },
              childCount: entries.length,
            ),
          ),
        );
      },
    );
  }

  /// Individual History Item
  Widget _buildHistoryItem(dynamic entry, bool isMetric) {
    final drinkId = entry.drinkId;
    final amount = entry.amount;
    final timestamp = entry.timestamp;
    final emoji = DrinkHelpers.getEmoji(drinkId);
    final color = ChartDataService.drinkColors[drinkId] ?? AppColors.textTertiary;
    final drinkName = DrinkHelpers.getName(drinkId);
    final timeString = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Text(
          drinkName,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          UnitConverter.formatVolume(amount, isMetric),
          style: AppTextStyles.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.backgroundSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            timeString,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  /// Helper: Get period label
  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case ChartPeriod.day:
        return 'Günlük Görünüm';
      case ChartPeriod.week:
        return 'Haftalık Görünüm';
      case ChartPeriod.month:
        return 'Aylık Görünüm';
    }
  }

  /// Helper: Get entries for selected period
  List<dynamic> _getEntriesForPeriod(HistoryProvider historyProvider) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (_selectedPeriod) {
      case ChartPeriod.day:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case ChartPeriod.week:
        startDate = now.subtract(const Duration(days: 28));
        break;
      case ChartPeriod.month:
        startDate = DateTime(now.year, now.month - 6, now.day);
        break;
    }

    final entries = historyProvider.getDrinkEntriesForDateRange(startDate, endDate);
    
    // Apply drink filters
    final filteredEntries = _selectedDrinkFilters.isEmpty
        ? entries
        : entries.where((e) => _selectedDrinkFilters.contains(e.drinkId)).toList();
    
    filteredEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filteredEntries;
  }

  /// Helper: Calculate statistics
  Map<String, dynamic> _calculateStatistics(
    HistoryProvider historyProvider,
    UserProvider userProvider,
    DailyHydrationProvider dailyHydrationProvider,
  ) {
    final now = DateTime.now();
    DateTime startDate;
    int days;

    switch (_selectedPeriod) {
      case ChartPeriod.day:
        startDate = now.subtract(const Duration(days: 6));
        days = 7;
        break;
      case ChartPeriod.week:
        startDate = now.subtract(const Duration(days: 27));
        days = 28;
        break;
      case ChartPeriod.month:
        startDate = DateTime(now.year, now.month - 5, now.day);
        days = 180;
        break;
    }

    final entries = historyProvider.getDrinkEntriesForDateRange(startDate, now);
    final totalAmount = entries.fold<double>(0, (sum, entry) => sum + entry.amount);
    final dailyAverage = days > 0 ? totalAmount / days : 0.0;
    final dailyGoal = dailyHydrationProvider.dailyGoal;
    final completionRate = dailyGoal > 0 ? (dailyAverage / dailyGoal * 100).clamp(0.0, 100.0) : 0.0;

    return {
      'dailyAverage': UnitConverter.formatVolume(dailyAverage, userProvider.isMetric),
      'completionRate': completionRate.toDouble(),
      'total': UnitConverter.formatVolume(totalAmount, userProvider.isMetric),
    };
  }

  /// Show Filter Bottom Sheet
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => HistoryFilterBottomSheet(
        initialFilters: _selectedDrinkFilters,
        onApply: (filters) {
          setState(() {
            _selectedDrinkFilters = filters;
            _touchedBarIndex = null;
          });
        },
      ),
    );
  }
}
