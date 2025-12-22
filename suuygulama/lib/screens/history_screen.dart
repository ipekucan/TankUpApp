import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../utils/app_colors.dart';
import '../providers/water_provider.dart';
import '../providers/user_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // Takvim, Gün, Hafta, Ay, Yıl
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.verySoftBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A5568)),
          onPressed: () => Navigator.pop(context),
        ),
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
            Tab(text: 'Takvim'),
            Tab(text: 'Gün'),
            Tab(text: 'Hafta'),
            Tab(text: 'Ay'),
            Tab(text: 'Yıl'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarView(),
          _buildDayView(),
          _buildWeekView(),
          _buildMonthView(),
          _buildYearView(),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    return Consumer2<WaterProvider, UserProvider>(
      builder: (context, waterProvider, userProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Takvim Widget'ı
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
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _selectedDate,
                  selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDate = selectedDay;
                    });
                  },
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: AppColors.softPinkButton,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: AppColors.softPinkButton.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: AppColors.waterColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                  eventLoader: (day) {
                    final dateKey = _getDateKey(day);
                    final amount = waterProvider.drinkHistory[dateKey] ?? 0.0;
                    return amount > 0 ? [1] : [];
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Seçilen günün detayları (Genişletilebilir)
              _buildExpandableDayDetail(waterProvider, _selectedDate),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpandableDayDetail(WaterProvider waterProvider, DateTime date) {
    final dateKey = _getDateKey(date);
    final amount = waterProvider.drinkHistory[dateKey] ?? 0.0;
    final isToday = isSameDay(date, DateTime.now());
    
    return ExpansionTile(
      title: Text(
        isToday ? 'Bugün' : '${date.day}/${date.month}/${date.year}',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4A5568),
        ),
      ),
      subtitle: Text(
        '${(amount / 1000.0).toStringAsFixed(2)}L içildi',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      leading: Icon(
        Icons.calendar_today,
        color: AppColors.softPinkButton,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildStatCard(
                title: 'Toplam Su',
                amount: amount,
                unit: 'ml',
                icon: Icons.water_drop,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                title: 'Günlük Hedef',
                amount: waterProvider.dailyGoal,
                unit: 'ml',
                icon: Icons.flag,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                title: 'İlerleme',
                amount: (amount / waterProvider.dailyGoal * 100).clamp(0.0, 100.0),
                unit: '%',
                icon: Icons.trending_up,
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDayView() {
    return Consumer2<WaterProvider, UserProvider>(
      builder: (context, waterProvider, userProvider, child) {
        final today = DateTime.now();
        final todayKey = _getDateKey(today);
        final todayAmount = waterProvider.drinkHistory[todayKey] ?? 0.0;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExpandableStatCard(
                title: 'Bugün',
                amount: todayAmount,
                unit: 'ml',
                icon: Icons.today,
                waterProvider: waterProvider,
              ),
              const SizedBox(height: 12),
              _buildExpandableStatCard(
                title: 'Günlük Hedef',
                amount: waterProvider.dailyGoal,
                unit: 'ml',
                icon: Icons.flag,
                waterProvider: waterProvider,
              ),
              const SizedBox(height: 12),
              _buildExpandableStatCard(
                title: 'İlerleme',
                amount: (todayAmount / waterProvider.dailyGoal * 100).clamp(0.0, 100.0),
                unit: '%',
                icon: Icons.trending_up,
                waterProvider: waterProvider,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeekView() {
    return Consumer2<WaterProvider, UserProvider>(
      builder: (context, waterProvider, userProvider, child) {
        final now = DateTime.now();
        double weekTotal = 0.0;
        final weekData = <String, double>{};
        
        // Son 7 günü hesapla
        for (int i = 0; i < 7; i++) {
          final date = now.subtract(Duration(days: i));
          final dateKey = _getDateKey(date);
          final amount = waterProvider.drinkHistory[dateKey] ?? 0.0;
          weekTotal += amount;
          weekData[dateKey] = amount;
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExpandableStatCard(
                title: 'Bu Hafta',
                amount: weekTotal,
                unit: 'ml',
                icon: Icons.calendar_view_week,
                waterProvider: waterProvider,
              ),
              const SizedBox(height: 12),
              _buildExpandableStatCard(
                title: 'Günlük Ortalama',
                amount: weekTotal / 7,
                unit: 'ml',
                icon: Icons.bar_chart,
                waterProvider: waterProvider,
              ),
              const SizedBox(height: 20),
              _buildWeekChart(waterProvider),
              const SizedBox(height: 20),
              // Günlük detaylar (Genişletilebilir liste)
              _buildExpandableWeekDetails(weekData),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpandableWeekDetails(Map<String, double> weekData) {
    return ExpansionTile(
      title: const Text(
        'Günlük Detaylar',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4A5568),
        ),
      ),
      leading: Icon(
        Icons.list,
        color: AppColors.softPinkButton,
      ),
      children: weekData.entries.map((entry) {
        final date = DateTime.parse(entry.key);
        final amount = entry.value;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.softPinkButton.withValues(alpha: 0.15),
            child: Text(
              '${date.day}',
              style: TextStyle(
                color: AppColors.softPinkButton,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          title: Text(
            '${date.day}/${date.month}/${date.year}',
            style: const TextStyle(fontSize: 14),
          ),
          trailing: Text(
            '${(amount / 1000.0).toStringAsFixed(2)}L',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.softPinkButton,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthView() {
    return Consumer2<WaterProvider, UserProvider>(
      builder: (context, waterProvider, userProvider, child) {
        final now = DateTime.now();
        double monthTotal = 0.0;
        int daysInMonth = 0;
        
        // Bu ayın tüm günlerini hesapla
        final lastDay = DateTime(now.year, now.month + 1, 0);
        
        for (int i = 0; i <= lastDay.day; i++) {
          final date = DateTime(now.year, now.month, i);
          if (date.isBefore(now) || date.day == now.day) {
            final dateKey = _getDateKey(date);
            monthTotal += waterProvider.drinkHistory[dateKey] ?? 0.0;
            daysInMonth++;
          }
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExpandableStatCard(
                title: 'Bu Ay',
                amount: monthTotal,
                unit: 'ml',
                icon: Icons.calendar_month,
                waterProvider: waterProvider,
              ),
              const SizedBox(height: 12),
              _buildExpandableStatCard(
                title: 'Günlük Ortalama',
                amount: daysInMonth > 0 ? monthTotal / daysInMonth : 0.0,
                unit: 'ml',
                icon: Icons.trending_up,
                waterProvider: waterProvider,
              ),
              const SizedBox(height: 12),
              _buildExpandableStatCard(
                title: 'Toplam Su',
                amount: userProvider.userData.totalWaterConsumed,
                unit: 'ml',
                icon: Icons.water_drop,
                waterProvider: waterProvider,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildYearView() {
    return Consumer2<WaterProvider, UserProvider>(
      builder: (context, waterProvider, userProvider, child) {
        final now = DateTime.now();
        double yearTotal = 0.0;
        final monthData = <String, double>{};
        
        // Bu yılın tüm aylarını hesapla
        for (int month = 1; month <= now.month; month++) {
          double monthTotal = 0.0;
          final lastDay = DateTime(now.year, month + 1, 0);
          
          for (int day = 1; day <= lastDay.day; day++) {
            final date = DateTime(now.year, month, day);
            if (date.isBefore(now) || (date.month == now.month && date.day == now.day)) {
              final dateKey = _getDateKey(date);
              monthTotal += waterProvider.drinkHistory[dateKey] ?? 0.0;
            }
          }
          
          monthData['${now.year}-${month.toString().padLeft(2, '0')}'] = monthTotal;
          yearTotal += monthTotal;
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExpandableStatCard(
                title: 'Bu Yıl',
                amount: yearTotal,
                unit: 'ml',
                icon: Icons.calendar_today,
                waterProvider: waterProvider,
              ),
              const SizedBox(height: 20),
              // Aylık detaylar (Genişletilebilir liste)
              _buildExpandableYearDetails(monthData),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpandableYearDetails(Map<String, double> monthData) {
    final monthNames = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    
    return ExpansionTile(
      title: const Text(
        'Aylık Detaylar',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4A5568),
        ),
      ),
      leading: Icon(
        Icons.calendar_view_month,
        color: AppColors.softPinkButton,
      ),
      children: monthData.entries.map((entry) {
        final parts = entry.key.split('-');
        final month = int.parse(parts[1]);
        final amount = entry.value;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.softPinkButton.withValues(alpha: 0.15),
            child: Text(
              '$month',
              style: TextStyle(
                color: AppColors.softPinkButton,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          title: Text(
            monthNames[month - 1],
            style: const TextStyle(fontSize: 14),
          ),
          trailing: Text(
            '${(amount / 1000.0).toStringAsFixed(2)}L',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.softPinkButton,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExpandableStatCard({
    required String title,
    required double amount,
    required String unit,
    required IconData icon,
    required WaterProvider waterProvider,
  }) {
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4A5568),
        ),
      ),
      subtitle: Text(
        unit == '%' 
          ? '${amount.toStringAsFixed(1)}%'
          : '${(amount / 1000.0).toStringAsFixed(2)}L',
        style: TextStyle(
          fontSize: 16,
          color: AppColors.softPinkButton,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.softPinkButton.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppColors.softPinkButton,
          size: 24,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detaylı Bilgi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                unit == '%'
                  ? 'Günlük hedefinizin %${amount.toStringAsFixed(1)}\'ini tamamladınız.'
                  : 'Toplam ${(amount / 1000.0).toStringAsFixed(2)} litre su tükettiniz.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required double amount,
    required String unit,
    required IconData icon,
  }) {
    return Container(
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
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.softPinkButton.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.softPinkButton,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(amount / 1000.0).toStringAsFixed(2)}L',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A5568),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekChart(WaterProvider waterProvider) {
    final now = DateTime.now();
    final weekData = <String, double>{};
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _getDateKey(date);
      weekData[dateKey] = waterProvider.drinkHistory[dateKey] ?? 0.0;
    }
    
    final maxValue = weekData.values.isEmpty 
        ? 1.0 
        : weekData.values.reduce((a, b) => a > b ? a : b);
    
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Haftalık Grafik',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: weekData.entries.map((entry) {
              final date = DateTime.parse(entry.key);
              final height = maxValue > 0 ? (entry.value / maxValue * 150) : 0.0;
              
              return Column(
                children: [
                  Container(
                    width: 30,
                    height: height.clamp(0.0, 150.0),
                    decoration: BoxDecoration(
                      color: AppColors.softPinkButton,
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${date.day}/${date.month}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

