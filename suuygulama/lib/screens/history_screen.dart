import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/app_colors.dart';
import '../providers/water_provider.dart';
import '../providers/user_provider.dart';
import '../models/drink_model.dart';
import '../utils/unit_converter.dart';

class HistoryScreen extends StatefulWidget {
  final bool hideAppBar;
  
  const HistoryScreen({super.key, this.hideAppBar = false});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedBarIndex = -1;
  double? _selectedBarValue;
  String? _selectedBarLabel;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // Filtre state'i
  Set<String> _selectedDrinkFilters = {}; // Seçili içecek ID'leri (boş = tümü gösterilir)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Gün, Hafta, Ay, Yıl
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
    
    // Tab değiştiğinde animasyonu yeniden başlat
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _animationController.reset();
        _animationController.forward();
        setState(() {
          _selectedBarIndex = -1;
          _selectedBarValue = null;
          _selectedBarLabel = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.verySoftBlue,
      appBar: widget.hideAppBar ? null : AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'İstatistikler',
          style: TextStyle(
            color: Color(0xFF4A5568),
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          // Filtre ikonu (Huni/Filtre)
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _selectedDrinkFilters.isEmpty 
                  ? Colors.grey[600]
                  : AppColors.softPinkButton,
            ),
            onPressed: () => _showFilterBottomSheet(context),
            tooltip: 'Filtrele',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.softPinkButton,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: AppColors.softPinkButton,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Gün'),
            Tab(text: 'Hafta'),
            Tab(text: 'Ay'),
            Tab(text: 'Yıl'),
          ],
        ),
      ),
      body: Column(
        children: [
          // AppBar yoksa TabBar'ı üstte göster
          if (widget.hideAppBar)
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.softPinkButton,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: AppColors.softPinkButton,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Gün'),
                  Tab(text: 'Hafta'),
                  Tab(text: 'Ay'),
                  Tab(text: 'Yıl'),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDayView(),
                _buildWeekView(),
                _buildMonthView(),
                _buildYearView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayView() {
    return Consumer2<WaterProvider, UserProvider>(
      builder: (context, waterProvider, userProvider, child) {
        final today = DateTime.now();
        final todayKey = _getDateKey(today);
        final dailyGoal = waterProvider.dailyGoal;
        
        // Son 7 günü göster (bugün dahil)
        final chartData = <BarDataPoint>[];
        final labels = <String>[];
        
        for (int i = 6; i >= 0; i--) {
          final date = today.subtract(Duration(days: i));
          final dateKey = _getDateKey(date);
          
          // Detaylı drink history'den veri al (filtre uygula)
          double amount = 0.0;
          final entries = waterProvider.getDrinkEntriesForDate(dateKey);
          final filteredEntries = _selectedDrinkFilters.isEmpty
              ? entries
              : entries.where((e) => _selectedDrinkFilters.contains(e.drinkId)).toList();
          
          // Verimli su miktarını hesapla (effectiveAmount)
          for (var entry in filteredEntries) {
            amount += entry.effectiveAmount;
          }
          
          final isReached = amount >= dailyGoal;
          
          labels.add('${date.day}/${date.month}');
          chartData.add(BarDataPoint(
            x: 6 - i,
            y: amount,
            isReached: isReached,
            dateKey: dateKey,
            date: date,
          ));
        }
        
        // Bugün için toplam miktarı hesapla
        final todayEntries = waterProvider.getDrinkEntriesForDate(todayKey);
        final filteredTodayEntries = _selectedDrinkFilters.isEmpty
            ? todayEntries
            : todayEntries.where((e) => _selectedDrinkFilters.contains(e.drinkId)).toList();
        final calculatedTodayAmount = filteredTodayEntries.fold(0.0, (sum, e) => sum + e.effectiveAmount);
        
        return _buildChartView(
          chartData: chartData,
          labels: labels,
          title: 'Bugün',
          currentAmount: calculatedTodayAmount,
          dailyGoal: dailyGoal,
          waterProvider: waterProvider,
          periodStartDate: today,
          periodEndDate: today,
        );
      },
    );
  }

  Widget _buildWeekView() {
    return Consumer2<WaterProvider, UserProvider>(
      builder: (context, waterProvider, userProvider, child) {
        final now = DateTime.now();
        final dailyGoal = waterProvider.dailyGoal;
        
        // Son 7 günü göster
        final chartData = <BarDataPoint>[];
        final labels = <String>[];
        double weekTotal = 0.0;
        
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final dateKey = _getDateKey(date);
          
          // Detaylı drink history'den veri al (filtre uygula)
          double amount = 0.0;
          final entries = waterProvider.getDrinkEntriesForDate(dateKey);
          final filteredEntries = _selectedDrinkFilters.isEmpty
              ? entries
              : entries.where((e) => _selectedDrinkFilters.contains(e.drinkId)).toList();
          
          // Verimli su miktarını hesapla (effectiveAmount)
          for (var entry in filteredEntries) {
            amount += entry.effectiveAmount;
          }
          
          final isReached = amount >= dailyGoal;
          weekTotal += amount;
          
          labels.add('${date.day}/${date.month}');
          chartData.add(BarDataPoint(
            x: 6 - i,
            y: amount,
            isReached: isReached,
            dateKey: dateKey,
            date: date,
          ));
        }
        
        return _buildChartView(
          chartData: chartData,
          labels: labels,
          title: 'Bu Hafta',
          currentAmount: weekTotal,
          dailyGoal: dailyGoal * 7,
          waterProvider: waterProvider,
        );
      },
    );
  }

  Widget _buildMonthView() {
    return Consumer2<WaterProvider, UserProvider>(
      builder: (context, waterProvider, userProvider, child) {
        final now = DateTime.now();
        final dailyGoal = waterProvider.dailyGoal;
        final lastDay = DateTime(now.year, now.month + 1, 0);
        
        // Bu ayın tüm günlerini göster
        final chartData = <BarDataPoint>[];
        final labels = <String>[];
        double monthTotal = 0.0;
        int dayCount = 0;
        
        for (int day = 1; day <= lastDay.day; day++) {
          final date = DateTime(now.year, now.month, day);
          if (date.isAfter(now)) break;
          
          final dateKey = _getDateKey(date);
          final amount = waterProvider.drinkHistory[dateKey] ?? 0.0;
          final isReached = amount >= dailyGoal;
          monthTotal += amount;
          dayCount++;
          
          labels.add('$day');
          chartData.add(BarDataPoint(
            x: day - 1,
            y: amount,
            isReached: isReached,
            dateKey: dateKey,
            date: date,
          ));
        }
        
        final monthStart = DateTime(now.year, now.month, 1);
        return _buildChartView(
          chartData: chartData,
          labels: labels,
          title: 'Bu Ay',
          currentAmount: monthTotal,
          dailyGoal: dailyGoal * dayCount,
          waterProvider: waterProvider,
          periodStartDate: monthStart,
          periodEndDate: now,
        );
      },
    );
  }

  Widget _buildYearView() {
    return Consumer2<WaterProvider, UserProvider>(
      builder: (context, waterProvider, userProvider, child) {
        final now = DateTime.now();
        final dailyGoal = waterProvider.dailyGoal;
        
        // Bu yılın tüm aylarını göster
        final chartData = <BarDataPoint>[];
        final labels = <String>[];
        final monthNames = ['O', 'Ş', 'M', 'N', 'M', 'H', 'T', 'A', 'E', 'E', 'K', 'A'];
        double yearTotal = 0.0;
        
        for (int month = 1; month <= now.month; month++) {
          double monthTotal = 0.0;
          final lastDay = DateTime(now.year, month + 1, 0);
          
          for (int day = 1; day <= lastDay.day; day++) {
            final date = DateTime(now.year, month, day);
            if (date.isAfter(now)) break;
            
            final dateKey = _getDateKey(date);
            
            // Detaylı drink history'den veri al (filtre uygula)
            final entries = waterProvider.getDrinkEntriesForDate(dateKey);
            final filteredEntries = _selectedDrinkFilters.isEmpty
                ? entries
                : entries.where((e) => _selectedDrinkFilters.contains(e.drinkId)).toList();
            
            // Verimli su miktarını hesapla (effectiveAmount)
            for (var entry in filteredEntries) {
              monthTotal += entry.effectiveAmount;
            }
          }
          
          final avgDaily = monthTotal / lastDay.day;
          final isReached = avgDaily >= dailyGoal;
          yearTotal += monthTotal;
          
          labels.add(monthNames[month - 1]);
          chartData.add(BarDataPoint(
            x: month - 1,
            y: monthTotal,
            isReached: isReached,
            dateKey: '${now.year}-${month.toString().padLeft(2, '0')}',
            date: DateTime(now.year, month, 1),
          ));
        }
        
        final yearStart = DateTime(now.year, 1, 1);
        return _buildChartView(
          chartData: chartData,
          labels: labels,
          title: 'Bu Yıl',
          currentAmount: yearTotal,
          dailyGoal: dailyGoal * 365,
          waterProvider: waterProvider,
          periodStartDate: yearStart,
          periodEndDate: now,
        );
      },
    );
  }

  // Belirli bir tarih aralığı için toplam hacim ve verimli su hesapla
  Map<String, double> _calculateVolumeStats(WaterProvider waterProvider, DateTime startDate, DateTime endDate) {
    double totalVolume = 0.0;
    double effectiveHydration = 0.0;
    
    var current = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    
    while (!current.isAfter(end)) {
      final dateKey = _getDateKey(current);
      final entries = waterProvider.getDrinkEntriesForDate(dateKey);
      
      // Filtre uygula
      final filteredEntries = _selectedDrinkFilters.isEmpty
          ? entries
          : entries.where((e) => _selectedDrinkFilters.contains(e.drinkId)).toList();
      
      for (var entry in filteredEntries) {
        totalVolume += entry.amount;
        effectiveHydration += entry.effectiveAmount;
      }
      
      current = current.add(const Duration(days: 1));
    }
    
    return {
      'totalVolume': totalVolume,
      'effectiveHydration': effectiveHydration,
    };
  }
  
  Widget _buildChartView({
    required List<BarDataPoint> chartData,
    required List<String> labels,
    required String title,
    required double currentAmount,
    required double dailyGoal,
    required WaterProvider waterProvider,
    DateTime? periodStartDate,
    DateTime? periodEndDate,
  }) {
    if (chartData.isEmpty) {
      return Center(
        child: Text(
          'Henüz veri yok',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }
    
    final maxValue = chartData.map((d) => d.y).reduce((a, b) => a > b ? a : b);
    final maxY = maxValue > 0 ? (maxValue * 1.2).clamp(dailyGoal, double.infinity) : dailyGoal;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bugün Özeti
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A5568),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Toplam Hacim vs Verimli Su Ayrımı
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    final stats = periodStartDate != null && periodEndDate != null
                        ? _calculateVolumeStats(waterProvider, periodStartDate, periodEndDate)
                        : {'totalVolume': currentAmount, 'effectiveHydration': currentAmount};
                    
                    final totalVolume = stats['totalVolume'] ?? 0.0;
                    final effectiveHydration = stats['effectiveHydration'] ?? 0.0;
                    
                    return Column(
                      children: [
                        // Toplam Hacim
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  UnitConverter.formatVolume(totalVolume, userProvider.isMetric),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4A5568),
                                  ),
                                ),
                                Text(
                                  'Toplam Hacim',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  UnitConverter.formatVolume(effectiveHydration, userProvider.isMetric),
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.softPinkButton,
                                  ),
                                ),
                                Text(
                                  'Verimli Su',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Hidrasyon verimliliği yüzdesi
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.softPinkButton.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.water_drop,
                                color: AppColors.softPinkButton,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                totalVolume > 0
                                    ? 'Hidrasyon Verimliliği: ${((effectiveHydration / totalVolume) * 100).toStringAsFixed(0)}%'
                                    : 'Henüz veri yok',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.softPinkButton,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Grafik
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 300,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxY,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (group) => Colors.transparent,
                              tooltipRoundedRadius: 8,
                              tooltipPadding: EdgeInsets.zero,
                              tooltipMargin: 8,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final data = chartData[groupIndex];
                                return BarTooltipItem(
                                  '${(data.y / 1000.0).toStringAsFixed(2)}L / ${(dailyGoal / 1000.0).toStringAsFixed(2)}L',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                            touchCallback: (FlTouchEvent event, barTouchResponse) {
                              if (event is FlTapUpEvent && barTouchResponse != null) {
                                final spot = barTouchResponse.spot;
                                if (spot != null) {
                                  final index = spot.touchedBarGroupIndex;
                                  if (index >= 0 && index < chartData.length) {
                                    final data = chartData[index];
                                    setState(() {
                                      _selectedBarIndex = index;
                                      _selectedBarValue = data.y;
                                      _selectedBarLabel = labels[index];
                                    });
                                  }
                                }
                              }
                            },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index >= 0 && index < labels.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        labels[index],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                                reservedSize: 40,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${(value / 1000.0).toStringAsFixed(1)}L',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: maxY / 5,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey[200]!,
                                strokeWidth: 1,
                              );
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: chartData.map((data) {
                            final animatedHeight = data.y * _animation.value;
                            
                            return BarChartGroupData(
                              x: data.x,
                              barRods: [
                                BarChartRodData(
                                  toY: animatedHeight,
                                  width: 24,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                    bottomLeft: Radius.zero,
                                    bottomRight: Radius.zero,
                                  ),
                                  color: data.isReached
                                      ? const Color(0xFF00BCD4) // Canlı mavi - hedefe ulaşılan
                                      : const Color(0xFF00BCD4).withValues(alpha: 0.3), // Soluk mavi - eksik
                                  gradient: data.isReached
                                      ? LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            const Color(0xFF00BCD4).withValues(alpha: 0.8),
                                            const Color(0xFF00BCD4),
                                          ],
                                        )
                                      : LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            const Color(0xFF00BCD4).withValues(alpha: 0.2),
                                            const Color(0xFF00BCD4).withValues(alpha: 0.3),
                                          ],
                                        ),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: dailyGoal,
                                    color: Colors.grey[100],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
                
                // Seçilen sütun bilgisi
                if (_selectedBarIndex >= 0 && _selectedBarValue != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.softPinkButton.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$_selectedBarLabel: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '${(_selectedBarValue! / 1000.0).toStringAsFixed(2)}L / ${(dailyGoal / 1000.0).toStringAsFixed(2)}L',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.softPinkButton,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Insight Kartları (Kafein & Şeker Kotası, Sağlık Yorumları)
          if (periodStartDate != null && periodEndDate != null)
            _buildInsightCards(waterProvider, periodStartDate, periodEndDate),
        ],
      ),
    );
  }
  
  // Insight kartları (Kafein & Şeker Kotası, Sağlık Yorumları)
  Widget _buildInsightCards(WaterProvider waterProvider, DateTime startDate, DateTime endDate) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // İçecek girişlerini al
        final entries = waterProvider.getDrinkEntriesForDateRange(startDate, endDate);
        
        // Filtre uygula
        final filteredEntries = _selectedDrinkFilters.isEmpty
            ? entries
            : entries.where((e) => _selectedDrinkFilters.contains(e.drinkId)).toList();
        
        // İçecek miktarlarını hesapla (ID -> miktar)
        final Map<String, double> drinkAmounts = {};
        for (var entry in filteredEntries) {
          drinkAmounts[entry.drinkId] = (drinkAmounts[entry.drinkId] ?? 0.0) + entry.amount;
        }
        
        // Kafeinli içecekler (kahve, çay vb.)
        final caffeineDrinks = ['coffee', 'tea', 'herbal_tea', 'green_tea', 'iced_coffee', 'cold_tea', 'energy_drink'];
        double caffeineVolume = 0.0;
        for (var drinkId in caffeineDrinks) {
          caffeineVolume += drinkAmounts[drinkId] ?? 0.0;
        }
        
        // Şekerli içecekler (meyve suyu, soda, limonata vb.)
        final sugaryDrinks = ['juice', 'fresh_juice', 'soda', 'lemonade', 'cold_tea', 'smoothie'];
        double sugaryVolume = 0.0;
        for (var drinkId in sugaryDrinks) {
          sugaryVolume += drinkAmounts[drinkId] ?? 0.0;
        }
        
        // Su miktarı
        final waterVolume = drinkAmounts['water'] ?? 0.0;
        
        // Toplam hacim
        final totalVolume = drinkAmounts.values.fold(0.0, (sum, amount) => sum + amount);
        
        // İçgörüler
        final hasHighCaffeine = caffeineVolume > waterVolume && caffeineVolume > 500;
        final hasHighSugar = sugaryVolume > waterVolume && sugaryVolume > 500;
        final hasGoodBalance = waterVolume >= (totalVolume * 0.6) && totalVolume > 0;
        
        return Column(
          children: [
            // Kafein Kotası Kartı
            if (caffeineVolume > 0)
              _buildInsightCard(
                icon: Icons.local_cafe,
                iconColor: Colors.brown,
                title: 'Kafein Kotası',
                subtitle: UnitConverter.formatVolume(caffeineVolume, userProvider.isMetric),
                message: hasHighCaffeine
                    ? '☕ Kafeinli içecekler suyunu geçti. Bir bardak suyla dengeleyin!'
                    : 'Kafein alımınız dengeli görünüyor.',
                backgroundColor: hasHighCaffeine
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
              ),
            
            const SizedBox(height: 16),
            
            // Şeker Kotası Kartı
            if (sugaryVolume > 0)
              _buildInsightCard(
                icon: Icons.cake,
                iconColor: Colors.pink,
                title: 'Şeker Kotası',
                subtitle: UnitConverter.formatVolume(sugaryVolume, userProvider.isMetric),
                message: hasHighSugar
                    ? '🍰 Şekerli içecekler suyunu geçti. Bir bardak suyla dengeleyin!'
                    : 'Şeker alımınız dengeli görünüyor.',
                backgroundColor: hasHighSugar
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
              ),
            
            const SizedBox(height: 16),
            
            // Genel Sağlık Yorumu
            if (hasGoodBalance)
              _buildInsightCard(
                icon: Icons.favorite,
                iconColor: Colors.red,
                title: 'Sağlık Durumu',
                subtitle: 'Mükemmel',
                message: '💚 Böbreklerin bayram etti! Su tüketimin harika.',
                backgroundColor: Colors.green.withOpacity(0.1),
              )
            else if (totalVolume > 0)
              _buildInsightCard(
                icon: Icons.water_drop,
                iconColor: Colors.blue,
                title: 'Su Dengesi',
                subtitle: '${((waterVolume / totalVolume) * 100).toStringAsFixed(0)}% Su',
                message: 'Su oranını artırmayı deneyin. Hidrasyon için önemli!',
                backgroundColor: Colors.blue.withOpacity(0.1),
              ),
          ],
        );
      },
    );
  }
  
  // Tek bir insight kartı
  Widget _buildInsightCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String message,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A5568),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  // İçecek emoji'si al
  String _getDrinkEmoji(String drinkId) {
    switch (drinkId) {
      case 'water':
        return '💧';
      case 'mineral_water':
        return '💧';
      case 'coffee':
        return '☕';
      case 'tea':
      case 'herbal_tea':
      case 'green_tea':
        return '🍵';
      case 'soda':
        return '🥤';
      case 'juice':
      case 'fresh_juice':
        return '🧃';
      case 'milk':
        return '🥛';
      case 'smoothie':
        return '🥤';
      default:
        return '🥤';
    }
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
        child: Consumer<WaterProvider>(
          builder: (context, waterProvider, child) {
            // Bugünün içecek girişlerini al
            final today = DateTime.now();
            final todayKey = _getDateKey(today);
            final todayEntries = waterProvider.getDrinkEntriesForDate(todayKey);
            
            // İçecek gruplama (ID -> toplam miktar)
            final Map<String, double> drinkAmounts = {};
            for (var entry in todayEntries) {
              drinkAmounts[entry.drinkId] = (drinkAmounts[entry.drinkId] ?? 0.0) + entry.amount;
            }
            
            // Tüm içecekleri al (DrinkData'dan)
            final allDrinks = DrinkData.getDrinks();
            
            return Column(
              children: [
                // Başlık ve kapat butonu
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'İçecek Filtresi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A5568),
                        ),
                      ),
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
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: allDrinks.length,
                    itemBuilder: (context, index) {
                      final drink = allDrinks[index];
                      final isSelected = _selectedDrinkFilters.contains(drink.id);
                      final amount = drinkAmounts[drink.id] ?? 0.0;
                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                      
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
                                _selectedDrinkFilters.remove(drink.id);
                              } else {
                                _selectedDrinkFilters.add(drink.id);
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
                                  _getDrinkEmoji(drink.id),
                                  style: const TextStyle(fontSize: 32),
                                ),
                                const SizedBox(width: 16),
                                
                                // İçecek adı ve miktar
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        drink.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF4A5568),
                                        ),
                                      ),
                                      if (amount > 0)
                                        Text(
                                          UnitConverter.formatVolume(amount, userProvider.isMetric),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        )
                                      else
                                        Text(
                                          'Henüz içilmedi',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[400],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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
                              _selectedDrinkFilters.clear();
                            });
                            Navigator.pop(context);
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
          },
        ),
      ),
    );
  }
}

class BarDataPoint {
  final int x;
  final double y;
  final bool isReached;
  final String dateKey;
  final DateTime date;

  BarDataPoint({
    required this.x,
    required this.y,
    required this.isReached,
    required this.dateKey,
    required this.date,
  });
}
