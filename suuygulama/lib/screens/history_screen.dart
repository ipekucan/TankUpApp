import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../providers/history_provider.dart';
import '../providers/user_provider.dart';
import '../models/drink_model.dart';
import '../utils/unit_converter.dart';
import '../utils/drink_helpers.dart';
import '../utils/date_helpers.dart';
import '../theme/app_text_styles.dart';
import '../services/chart_data_service.dart' show ChartDataService, ChartPeriod;

import '../widgets/history/period_selector.dart';
import '../widgets/history/insight_card.dart';
import '../widgets/history/history_filter_button.dart';

import '../widgets/history/history_insight_dialog.dart';
import '../widgets/history/deferred_chart_view.dart';
import '../services/chart_data_service.dart' show ChartDataPoint;

class HistoryScreen extends StatefulWidget {
  final bool hideAppBar;
  final Widget? lightbulbButton; // Ampul butonu widget'ı (opsiyonel)

  const HistoryScreen({
    super.key,
    this.hideAppBar = false,
    this.lightbulbButton,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Text(
                'İstatistikler',
                style: AppTextStyles.heading3,
              ),
              actions: [
                // Akıllı Ampul İkonu (İçgörüler)
                Consumer2<HistoryProvider, UserProvider>(
                  builder: (context, historyProvider, userProvider, child) {
                    return InsightCard(
                      onTap: () => _showInsightDialog(
                        context,
                        historyProvider,
                        userProvider,
                      ),
                    );
                  },
                ),
                // Premium close button (circular, light grey background)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.grey[700],
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            slivers: [
              // Module 1: Header Sliver (FilterButton + PeriodSelector + CloseButton)
              if (widget.hideAppBar) _buildHeaderSliver(context),
              
              // Module 2: Date Title Sliver
              _buildDateTitleSliver(context),
              
              // Module 3: Chart Card Sliver
              _buildChartCardSliver(context),
              
              // Module 4: History List Sliver (Lazy loading)
              _buildHistoryListSliver(context),
            ],
          ),
          // Layer 2 (Front): Lightbulb button - Fixed bottom-right corner (floating)
          if (widget.lightbulbButton != null)
            Positioned(
              right: 24.0,
              bottom: 24.0,
              child: widget.lightbulbButton!,
            ),
        ],
      ),
    );
  }

  /// Module 1: Header Sliver (FilterButton + PeriodSelector + CloseButton)
  Widget _buildHeaderSliver(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: FilterButton + PeriodSelector
            Row(
              children: [
                _buildFilterButton(context),
                const SizedBox(width: 12),
                PeriodSelector(
                  selectedPeriod: _selectedPeriod,
                  onPeriodChanged: (period) {
                    setState(() {
                      _selectedPeriod = period;
                      _touchedBarIndex = null;
                    });
                  },
                ),
              ],
            ),
            // Right: Close Button
            GestureDetector(
              onTap: () {
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Color(0xFF4A5568),
                  size: 20.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Module 2: Date Title Sliver (Left-aligned date text)
  Widget _buildDateTitleSliver(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _getFormattedDate(),
            style: AppTextStyles.dateText,
          ),
        ),
      ),
    );
  }

  /// Module 3: Chart Card Sliver (Grey card with ChartView)
  Widget _buildChartCardSliver(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Dynamic Range Label (Centered, Bold)
              Center(
                child: Text(
                  _getRangeLabel(),
                  style: const TextStyle(
                    color: Color(0xFF4A5568),
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Chart (Fixed height)
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
                    return DeferredChartView(
                      chartData: ChartDataService.buildChartData(
                        historyProvider,
                        _selectedPeriod,
                        _selectedDrinkFilters,
                      ),
                      touchedBarIndex: _touchedBarIndex,
                      onBarTouched: (int? index) {
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

  /// Module 4: History List Sliver (SliverList with lazy loading)
  Widget _buildHistoryListSliver(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: Consumer2<HistoryProvider, UserProvider>(
        builder: (context, historyProvider, userProvider, child) {
          // Calculate date range
          final dateRange = _calculateDateRange(historyProvider);
          if (dateRange == null) {
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }

          // Get entries for the date range
          final entries = historyProvider.getDrinkEntriesForDateRange(
            dateRange.startDate,
            dateRange.endDate,
          );

          // Apply filters
          final filteredEntries = _selectedDrinkFilters.isEmpty
              ? entries
              : entries
                  .where((e) => _selectedDrinkFilters.contains(e.drinkId))
                  .toList();

          // Sort by timestamp (newest first)
          final sortedEntries = List.from(filteredEntries)
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          if (sortedEntries.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
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

          // Use SliverList for lazy loading (NO shrinkWrap)
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: _buildHistoryItem(
                    sortedEntries[index],
                    userProvider.isMetric,
                  ),
                );
              },
              childCount: sortedEntries.length,
            ),
          );
        },
      ),
    );
  }

  /// Helper: Build individual history item (Compact Row style)
  Widget _buildHistoryItem(dynamic entry, bool isMetric) {
    final drinkId = entry.drinkId;
    final amount = entry.amount;
    final timestamp = entry.timestamp;
    final emoji = DrinkHelpers.getEmoji(drinkId);
    final color = ChartDataService.drinkColors[drinkId] ?? Colors.grey;
    final drinkName = DrinkHelpers.getName(drinkId);

    // Format time from timestamp (timestamp is already a DateTime)
    final timeString = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
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

  /// Helper: Calculate date range based on selected period and touched bar
  _DateRange? _calculateDateRange(HistoryProvider historyProvider) {
    DateTime? selectedStartDate;
    DateTime? selectedEndDate;

    if (_touchedBarIndex != null && _touchedBarIndex! >= 0) {
      if (_touchedBarIndex! < _lastChartData.length) {
        final dataPoint = _lastChartData[_touchedBarIndex!];
        selectedStartDate = dataPoint.date;
        selectedEndDate = dataPoint.date;
      }
    } else {
      // Default to current period
      switch (_selectedPeriod) {
        case ChartPeriod.day:
          selectedStartDate = DateTime.now();
          selectedEndDate = selectedStartDate;
          break;
        case ChartPeriod.week:
          final today = DateTime.now();
          final weekStart = today.subtract(
            Duration(days: today.weekday - 1),
          );
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

    if (selectedStartDate == null || selectedEndDate == null) {
      return null;
    }

    return _DateRange(
      startDate: selectedStartDate,
      endDate: selectedEndDate,
    );
  }

  /// Helper: Get formatted date string
  String _getFormattedDate() {
    return DateHelpers.getFormattedTurkishDate();
  }

  /// Helper: Get range label based on selected period
  String _getRangeLabel() {
    switch (_selectedPeriod) {
      case ChartPeriod.day:
        return 'Son 7 Gün';
      case ChartPeriod.week:
        return 'Son 4 Hafta';
      case ChartPeriod.month:
        return 'Son 12 Ay';
    }
  }

  // Filtre butonu
  Widget _buildFilterButton(BuildContext context) {
    return HistoryFilterButton(
      onTap: () => _showFilterBottomSheet(context),
      hasActiveFilters: _selectedDrinkFilters.isNotEmpty,
    );
  }



  // İçgörüler Dialog'unu göster
  void _showInsightDialog(
    BuildContext context,
    HistoryProvider historyProvider,
    UserProvider userProvider,
  ) {
    showHistoryInsightDialog(context, historyProvider, userProvider);
  }



  // Filtre bottom sheet'i göster
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
            // Bugünün içecek girişlerini al
            final today = DateTime.now();
            final todayKey = DateHelpers.toDateKey(today);
            final todayEntries = historyProvider.getDrinkEntriesForDate(todayKey);

            // İçecek gruplama (ID -> toplam miktar)
            final Map<String, double> drinkAmounts = {};
            for (var entry in todayEntries) {
              drinkAmounts[entry.drinkId] =
                  (drinkAmounts[entry.drinkId] ?? 0.0) + entry.amount;
            }

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

/// Helper class for date range
class _DateRange {
  final DateTime startDate;
  final DateTime endDate;

  _DateRange({required this.startDate, required this.endDate});
}

// Filtre Bottom Sheet içeriği (StatefulWidget olarak ayrıldı)
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
        // Başlık ve kapat butonu
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

        // Filtre kartları
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Tümü seçeneği
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
                        // Checkbox
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

                        // Icon
                        const Icon(
                          Icons.all_inclusive,
                          size: 32,
                          color: Color(0xFF4A5568),
                        ),
                        const SizedBox(width: 16),

                        // İçecek adı
                        Expanded(
                          child: Text('Tümü', style: AppTextStyles.bodyLarge),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // İçecek listesi
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
                          // Checkbox
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

                          // Emoji
                          Text(
                            DrinkHelpers.getEmoji(drink.id),
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 16),

                          // İçecek adı
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

        // Alt butonlar
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