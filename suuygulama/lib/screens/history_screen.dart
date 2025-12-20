import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          tabs: const [
            Tab(text: 'Gün'),
            Tab(text: 'Hafta'),
            Tab(text: 'Ay'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDayView(),
          _buildWeekView(),
          _buildMonthView(),
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
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatCard(
                title: 'Bugün',
                amount: todayAmount,
                unit: 'ml',
                icon: Icons.today,
              ),
              const SizedBox(height: 20),
              _buildStatCard(
                title: 'Günlük Hedef',
                amount: waterProvider.dailyGoal,
                unit: 'ml',
                icon: Icons.flag,
              ),
              const SizedBox(height: 20),
              _buildStatCard(
                title: 'İlerleme',
                amount: (todayAmount / waterProvider.dailyGoal * 100).clamp(0.0, 100.0),
                unit: '%',
                icon: Icons.trending_up,
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
        
        // Son 7 günü hesapla
        for (int i = 0; i < 7; i++) {
          final date = now.subtract(Duration(days: i));
          final dateKey = _getDateKey(date);
          weekTotal += waterProvider.drinkHistory[dateKey] ?? 0.0;
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatCard(
                title: 'Bu Hafta',
                amount: weekTotal,
                unit: 'ml',
                icon: Icons.calendar_view_week,
              ),
              const SizedBox(height: 20),
              _buildStatCard(
                title: 'Günlük Ortalama',
                amount: weekTotal / 7,
                unit: 'ml',
                icon: Icons.bar_chart,
              ),
              const SizedBox(height: 20),
              _buildWeekChart(waterProvider),
            ],
          ),
        );
      },
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
              _buildStatCard(
                title: 'Bu Ay',
                amount: monthTotal,
                unit: 'ml',
                icon: Icons.calendar_month,
              ),
              const SizedBox(height: 20),
              _buildStatCard(
                title: 'Günlük Ortalama',
                amount: daysInMonth > 0 ? monthTotal / daysInMonth : 0.0,
                unit: 'ml',
                icon: Icons.trending_up,
              ),
              const SizedBox(height: 20),
              _buildStatCard(
                title: 'Toplam Su',
                amount: userProvider.userData.totalWaterConsumed,
                unit: 'ml',
                icon: Icons.water_drop,
              ),
            ],
          ),
        );
      },
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

