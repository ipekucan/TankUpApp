import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/app_colors.dart';
import '../providers/water_provider.dart';
import '../providers/user_provider.dart';

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
        final todayAmount = waterProvider.drinkHistory[todayKey] ?? 0.0;
        final dailyGoal = waterProvider.dailyGoal;
        
        // Son 7 günü göster (bugün dahil)
        final chartData = <BarDataPoint>[];
        final labels = <String>[];
        
        for (int i = 6; i >= 0; i--) {
          final date = today.subtract(Duration(days: i));
          final dateKey = _getDateKey(date);
          final amount = waterProvider.drinkHistory[dateKey] ?? 0.0;
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
        
        return _buildChartView(
          chartData: chartData,
          labels: labels,
          title: 'Bugün',
          currentAmount: todayAmount,
          dailyGoal: dailyGoal,
          waterProvider: waterProvider,
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
          final amount = waterProvider.drinkHistory[dateKey] ?? 0.0;
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
        
        return _buildChartView(
          chartData: chartData,
          labels: labels,
          title: 'Bu Ay',
          currentAmount: monthTotal,
          dailyGoal: dailyGoal * dayCount,
          waterProvider: waterProvider,
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
            monthTotal += waterProvider.drinkHistory[dateKey] ?? 0.0;
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
        
        return _buildChartView(
          chartData: chartData,
          labels: labels,
          title: 'Bu Yıl',
          currentAmount: yearTotal,
          dailyGoal: dailyGoal * 365,
          waterProvider: waterProvider,
        );
      },
    );
  }

  Widget _buildChartView({
    required List<BarDataPoint> chartData,
    required List<String> labels,
    required String title,
    required double currentAmount,
    required double dailyGoal,
    required WaterProvider waterProvider,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${(currentAmount / 1000.0).toStringAsFixed(2)}L',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4A5568),
                          ),
                        ),
                        Text(
                          'İçildi',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(dailyGoal / 1000.0).toStringAsFixed(2)}L',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Hedef',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
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
                                  width: 20,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8),
                                  ),
                                  color: data.isReached
                                      ? AppColors.waterColor
                                      : AppColors.waterColor.withValues(alpha: 0.3),
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
        ],
      ),
    );
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
