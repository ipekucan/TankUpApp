import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/water_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/chart_data_service.dart' show ChartDataService, ChartPeriod;
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                // Unified Statistics Card
                _buildUnifiedStatisticsCard(),
                const SizedBox(height: 20),
                
                // Drink History List
                _buildDrinkHistoryList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Unified Statistics Card with filter button, period selector, and chart
  Widget _buildUnifiedStatisticsCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(24),
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
          // Row 1: Filter Button (Left) + Period Selector (Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Circular Beverage Filter Button
              _buildFilterButton(context),
              const SizedBox(width: 12),
              // Time Segment Control (Period Selector) - Expanded to fill space
              Expanded(
                child: _buildCompactPeriodSelector(),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
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
          
          // Row 2: Chart (compact height, without title)
          SizedBox(
            height: 180.0,
            child: Consumer<WaterProvider>(
              builder: (context, waterProvider, child) {
                final chartData = ChartDataService.buildChartData(
                  waterProvider,
                  _selectedPeriod,
                  _selectedDrinkFilters,
                );
                return ChartView(
                  chartData: chartData,
                  selectedPeriod: _selectedPeriod,
                  touchedBarIndex: _touchedBarIndex ?? -1,
                  onBarTouched: (index) {
                    setState(() {
                      _touchedBarIndex = index;
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
  Widget _buildCompactPeriodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(child: _buildCompactPeriodButton('Gün', ChartPeriod.day)),
        const SizedBox(width: 8),
        Expanded(child: _buildCompactPeriodButton('Hafta', ChartPeriod.week)),
        const SizedBox(width: 8),
        Expanded(child: _buildCompactPeriodButton('Ay', ChartPeriod.month)),
      ],
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
      child: Container(
        height: 38.0,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: isActive ? null : Border.all(color: Colors.grey[300]!, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[800],
            fontWeight: FontWeight.w600,
            fontSize: 14.0,
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
        return 'Son 12 Ay';
    }
  }

  /// Drink History List (Vertical ListView)
  Widget _buildDrinkHistoryList() {
    return Consumer2<WaterProvider, UserProvider>(
      builder: (context, waterProvider, userProvider, child) {
        // Get date range based on selected period and touched bar
        DateTime? selectedStartDate;
        DateTime? selectedEndDate;

        if (_touchedBarIndex != null && _touchedBarIndex! >= 0) {
          final chartData = ChartDataService.buildChartData(
            waterProvider,
            _selectedPeriod,
            _selectedDrinkFilters,
          );
          if (_touchedBarIndex! < chartData.length) {
            final dataPoint = chartData[_touchedBarIndex!];
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
          return const SizedBox.shrink();
        }

        final entries = waterProvider.getDrinkEntriesForDateRange(
          selectedStartDate,
          selectedEndDate,
        );

        // Apply filters
        final filteredEntries = _selectedDrinkFilters.isEmpty
            ? entries
            : entries
                .where((e) => _selectedDrinkFilters.contains(e.drinkId))
                .toList();

        if (filteredEntries.isEmpty) {
          return Center(
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
          );
        }

        // Sort entries by timestamp (newest first)
        final sortedEntries = List.from(filteredEntries)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...sortedEntries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: _buildDrinkHistoryItem(
                    entry,
                    userProvider.isMetric,
                  ),
                )),
          ],
        );
      },
    );
  }

  /// Individual Drink History List Item (ListTile style)
  Widget _buildDrinkHistoryItem(dynamic entry, bool isMetric) {
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

  /// Filter Button (Circular Beverage Filter)
  Widget _buildFilterButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFilterBottomSheet(context),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _selectedDrinkFilters.isEmpty
              ? Colors.grey[200]
              : AppColors.softPinkButton.withValues(alpha: 0.2),
          border: Border.all(
            color: _selectedDrinkFilters.isEmpty
                ? Colors.grey[400]!
                : AppColors.softPinkButton,
            width: 2,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildCustomDrinkIcon(),
            Positioned(
              bottom: 4,
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: _selectedDrinkFilters.isEmpty
                    ? Colors.grey[600]
                    : AppColors.softPinkButton,
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
        child: Consumer<WaterProvider>(
          builder: (context, waterProvider, child) {
            final today = DateTime.now();
            final todayKey = DateHelpers.toDateKey(today);
            final todayEntries = waterProvider.getDrinkEntriesForDate(todayKey);

            return _FilterBottomSheetContent(
              initialFilters: _selectedDrinkFilters,
              onApply: (filters) {
                setState(() {
                  _selectedDrinkFilters = filters;
                });
              },
              waterProvider: waterProvider,
              todayEntries: todayEntries,
              drinkAmounts: {},
            );
          },
        ),
      ),
    );
  }
}

// Filter Bottom Sheet Content (reuse from HistoryScreen)
class _FilterBottomSheetContent extends StatefulWidget {
  final Set<String> initialFilters;
  final Function(Set<String>) onApply;
  final WaterProvider waterProvider;
  final List todayEntries;
  final Map<String, double> drinkAmounts;

  const _FilterBottomSheetContent({
    required this.initialFilters,
    required this.onApply,
    required this.waterProvider,
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