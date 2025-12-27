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
  final Widget? lightbulbButton; // Ampul butonu widget'ı (opsiyonel)
  
  const HistoryScreen({super.key, this.hideAppBar = false, this.lightbulbButton});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

enum ChartPeriod { day, week, month }

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  ChartPeriod _selectedPeriod = ChartPeriod.day;
  Set<String> _selectedDrinkFilters = {}; // Boş = Tümü
  int _touchedBarIndex = -1;
  late AnimationController _lightbulbAnimationController;
  
  @override
  void initState() {
    super.initState();
    // Her ekran açılışında varsayılan olarak 'Gün' modunu seç
    _selectedPeriod = ChartPeriod.day;
    _touchedBarIndex = -1;
    
    // Ampul animasyon kontrolcüsü (1.5 saniye, sürekli döngü)
    _lightbulbAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _lightbulbAnimationController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _lightbulbAnimationController.dispose();
    super.dispose();
  }



  // İçecek renkleri
  static const Map<String, Color> _drinkColors = {
    'water': Colors.blue,
    'coffee': Colors.brown,
    'tea': Colors.green,
    'soda': Colors.orange,
    'mineral_water': Colors.lightBlue,
    'herbal_tea': Colors.lightGreen,
    'green_tea': Colors.teal,
    'cold_tea': Colors.cyan,
    'lemonade': Colors.yellow,
    'iced_coffee': Colors.deepOrange,
    'ayran': Colors.blueGrey,
    'kefir': Colors.grey,
    'milk': Colors.white,
    'juice': Colors.redAccent,
    'smoothie': Colors.purpleAccent,
    'fresh_juice': Colors.lime,
    'sports': Colors.indigo,
    'protein_shake': Colors.deepPurple,
    'coconut_water': Colors.lightGreenAccent,
    'energy_drink': Colors.red,
    'detox_water': Colors.cyanAccent,
  };

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
          // Akıllı Ampul İkonu (İçgörüler)
          _buildInsightLightbulbButton(context),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Filtre Butonu (En Solda)
              _buildFilterButton(context),
              const SizedBox(width: 12),
              // Zaman Butonları
              _buildPeriodButton('Gün', ChartPeriod.day),
              const SizedBox(width: 8),
              _buildPeriodButton('Hafta', ChartPeriod.week),
              const SizedBox(width: 8),
              _buildPeriodButton('Ay', ChartPeriod.month),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top Row (hideAppBar durumunda görünür)
            if (widget.hideAppBar)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Renkli Bardak Butonu (En Solda)
                    _buildFilterButton(context),
                    const SizedBox(width: 12),
                    // Zaman Butonları
                    _buildPeriodButton('Gün', ChartPeriod.day),
                    const SizedBox(width: 8),
                    _buildPeriodButton('Hafta', ChartPeriod.week),
                    const SizedBox(width: 8),
                    _buildPeriodButton('Ay', ChartPeriod.month),
                  ],
                ),
              ),
            
            // İçerik: İki Ayrı Kutu
            Column(
              children: [
                // KUTU 1: Grafik Kutusu
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Grafik Başlığı
                            Text(
                              'Sıvı Tüketim Grafiği',
                              style: const TextStyle(
                                fontSize: 22.0, // Büyütüldü
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A5568),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            // Grafik Alanı
                            _buildBarChart(context),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16.0),
                
                // KUTU 2: Liste Kutusu
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: 20.0,
                          left: 20.0,
                          right: 20.0,
                          bottom: widget.lightbulbButton != null ? 90.0 : 20.0, // Ampul varsa alt padding artır
                        ),
                        child: _buildSummaryAndDetailArea(context),
                      ),
                    ),
                    // Ampul butonu (eğer sağlanmışsa) - Liste kutusunun SOL ALT köşesinde
                    if (widget.lightbulbButton != null)
                      Positioned(
                        left: 24.0,
                        bottom: 24.0,
                        child: widget.lightbulbButton!,
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Akıllı Ampul İkonu (İçgörüler)
  Widget _buildInsightLightbulbButton(BuildContext context) {
    return Consumer2<WaterProvider, UserProvider>(
      builder: (context, waterProvider, userProvider, child) {
        // Bugünün verilerini al
        final today = DateTime.now();
        final todayKey = _getDateKey(today);
        final entries = waterProvider.getDrinkEntriesForDate(todayKey);
        
        // İçecek miktarlarını hesapla
        final Map<String, double> drinkAmounts = {};
        for (var entry in entries) {
          drinkAmounts[entry.drinkId] = (drinkAmounts[entry.drinkId] ?? 0.0) + entry.amount;
        }
        
        // Kafeinli içecekler
        final caffeineDrinks = ['coffee', 'tea', 'herbal_tea', 'green_tea', 'iced_coffee', 'cold_tea', 'energy_drink'];
        double caffeineVolume = 0.0;
        for (var drinkId in caffeineDrinks) {
          caffeineVolume += drinkAmounts[drinkId] ?? 0.0;
        }
        
        // Şekerli içecekler
        final sugaryDrinks = ['juice', 'fresh_juice', 'soda', 'lemonade', 'cold_tea', 'smoothie'];
        double sugaryVolume = 0.0;
        for (var drinkId in sugaryDrinks) {
          sugaryVolume += drinkAmounts[drinkId] ?? 0.0;
        }
        
        // Su miktarı
        final waterVolume = drinkAmounts['water'] ?? 0.0;
        final totalVolume = drinkAmounts.values.fold(0.0, (sum, amount) => sum + amount);
        
        // Uyarı durumları
        final hasHighCaffeine = caffeineVolume > waterVolume && caffeineVolume > 500;
        final hasHighSugar = sugaryVolume > waterVolume && sugaryVolume > 500;
        final hasLowWaterRatio = totalVolume > 0 && waterVolume < (totalVolume * 0.6);
        final hasWarning = hasHighCaffeine || hasHighSugar || hasLowWaterRatio;
        
        return AnimatedBuilder(
          animation: _lightbulbAnimationController,
          builder: (context, child) {
            // Uyarı varsa animasyonlu scale değeri (1.0 -> 1.2)
            final scale = hasWarning 
                ? 1.0 + (_lightbulbAnimationController.value * 0.2)
                : 1.0;
            
            // Uyarı varsa animasyonlu glow değeri (blur radius)
            final glowIntensity = hasWarning
                ? 8.0 + (_lightbulbAnimationController.value * 12.0) // 8 -> 20 arası
                : 0.0;
            
            return Stack(
              children: [
                // Glow efekti (sadece uyarı varsa)
                if (hasWarning)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.6),
                            blurRadius: glowIntensity,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // İkon butonu
                Transform.scale(
                  scale: scale,
                  child: IconButton(
                    icon: Icon(
                      Icons.lightbulb,
                      color: hasWarning ? Colors.amber : Colors.grey[400],
                      size: 34.0, // Daha büyük ve görünür
                    ),
                    onPressed: () => _showInsightDialog(context, waterProvider, userProvider),
                  ),
                ),
                
                // Kırmızı badge (uyarı varsa)
                if (hasWarning)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // Filtre butonu
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
            // Özel bardak ikonu (3 renkli daireler)
            _buildCustomDrinkIcon(),
            // Aşağı ok
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

  // Özel bardak ikonu (3 renkli daireler)
  Widget _buildCustomDrinkIcon() {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Mavi daire (Su)
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
          // Kahverengi daire (Kahve)
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
          // Turuncu daire (Asitli)
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

  // Zaman modu butonu
  Widget _buildPeriodButton(String label, ChartPeriod period) {
    final isActive = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
          _touchedBarIndex = -1;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[800],
            fontWeight: FontWeight.w600,
            fontSize: 17.0, // Büyütüldü (14 -> 17)
          ),
        ),
      ),
    );
  }

  // Stacked Bar Chart
  Widget _buildBarChart(BuildContext context) {
    return Consumer2<WaterProvider, UserProvider>(
      builder: (context, waterProvider, userProvider, child) {
        final chartData = _buildChartData(waterProvider);
        
        if (chartData.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Henüz veri yok',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 18.0, // Büyütüldü (16 -> 18)
                ),
              ),
            ),
          );
        }

        // Ay modu için bar genişliği ve aralık ayarları
        final isMonthMode = _selectedPeriod == ChartPeriod.month;
        final groupsSpace = isMonthMode ? 4.0 : 8.0;
        
        // Aylık mod için kaydırılabilir grafik
        if (isMonthMode) {
          final screenWidth = MediaQuery.of(context).size.width;
          final chartWidth = screenWidth * 2.0; // 2x ekran genişliği (yaklaşık 6 ay görünür olacak)
          
          return SizedBox(
            height: MediaQuery.of(context).size.width / 1.6, // AspectRatio 1.6'ya uygun yükseklik
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxY(chartData),
                    groupsSpace: groupsSpace,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => Colors.black87,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
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
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0, // Büyütüldü (14 -> 16)
                            ),
                          );
                        },
                        tooltipRoundedRadius: 8,
                      ),
                      touchCallback: (FlTouchEvent event, barTouchResponse) {
                        if (event.isInterestedForInteractions &&
                            barTouchResponse != null &&
                            barTouchResponse.spot != null) {
                          setState(() {
                            _touchedBarIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                          });
                        } else {
                          setState(() {
                            _touchedBarIndex = -1;
                          });
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
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < chartData.length) {
                              // Gün modu için manuel mapping: Tek harf gösterim
                              String label;
                              if (_selectedPeriod == ChartPeriod.day) {
                                final dataPoint = chartData[value.toInt()];
                                // DateTime.weekday: 1=Pazartesi, 2=Salı, ..., 7=Pazar
                                switch (dataPoint.date.weekday) {
                                  case DateTime.monday: // 1
                                    label = 'P';
                                    break;
                                  case DateTime.tuesday: // 2
                                    label = 'S';
                                    break;
                                  case DateTime.wednesday: // 3
                                    label = 'Ç';
                                    break;
                                  case DateTime.thursday: // 4
                                    label = 'P';
                                    break;
                                  case DateTime.friday: // 5
                                    label = 'C';
                                    break;
                                  case DateTime.saturday: // 6
                                    label = 'C';
                                    break;
                                  case DateTime.sunday: // 7
                                    label = 'P';
                                    break;
                                  default:
                                    label = '';
                                }
                              } else {
                                // Hafta ve Ay modları için mevcut label'ı kullan
                                label = chartData[value.toInt()].label;
                              }
                              
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: _selectedPeriod == ChartPeriod.day ? 14.0 : 11,
                                    fontWeight: _selectedPeriod == ChartPeriod.day ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
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
                          showTitles: false, // Sol ekseni kaldır
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: false, // Grid çizgilerini tamamen kaldır
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: _buildBarGroups(chartData),
                  ),
                ),
              ),
            ),
          );
        }
        
        // Gün ve Hafta modları için normal görünüm
        return AspectRatio(
          aspectRatio: 1.6,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _getMaxY(chartData),
              groupsSpace: groupsSpace,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => Colors.black87,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
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
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0, // Büyütüldü (14 -> 16)
                              ),
                            );
                  },
                  tooltipRoundedRadius: 8,
                ),
                touchCallback: (FlTouchEvent event, barTouchResponse) {
                  if (event.isInterestedForInteractions &&
                      barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    setState(() {
                      _touchedBarIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                    });
                  } else {
                    setState(() {
                      _touchedBarIndex = -1;
                    });
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
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < chartData.length) {
                        // Gün modu için manuel mapping: Tek harf gösterim
                        String label;
                        if (_selectedPeriod == ChartPeriod.day) {
                          final dataPoint = chartData[value.toInt()];
                          // DateTime.weekday: 1=Pazartesi, 2=Salı, ..., 7=Pazar
                          switch (dataPoint.date.weekday) {
                            case DateTime.monday: // 1
                              label = 'P';
                              break;
                            case DateTime.tuesday: // 2
                              label = 'S';
                              break;
                            case DateTime.wednesday: // 3
                              label = 'Ç';
                              break;
                            case DateTime.thursday: // 4
                              label = 'P';
                              break;
                            case DateTime.friday: // 5
                              label = 'C';
                              break;
                            case DateTime.saturday: // 6
                              label = 'C';
                              break;
                            case DateTime.sunday: // 7
                              label = 'P';
                              break;
                            default:
                              label = '';
                          }
                        } else if (_selectedPeriod == ChartPeriod.week) {
                          // Haftalık mod için mevcut label'ı kullan (büyük ve bold)
                          label = chartData[value.toInt()].label;
                        } else {
                          // Ay modu için mevcut label'ı kullan
                          label = chartData[value.toInt()].label;
                        }
                        
                        // Haftalık mod için büyük ve bold yazı
                        if (_selectedPeriod == ChartPeriod.week) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: Color(0xFF2C3E50), // Koyu gri
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        
                        // Gün modu için bold ve büyük yazı
                        if (_selectedPeriod == ChartPeriod.day) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                        }
                        
                        // Ay modu için normal stil
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: _selectedPeriod == ChartPeriod.day || _selectedPeriod == ChartPeriod.week ? 40 : 32,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false, // Sol ekseni kaldır
                  ),
                ),
              ),
              gridData: FlGridData(
                show: false, // Grid çizgilerini tamamen kaldır
              ),
              borderData: FlBorderData(show: false),
              barGroups: _buildBarGroups(chartData),
            ),
          ),
        );
      },
    );
  }

  // Grafik verilerini oluştur
  List<_ChartDataPoint> _buildChartData(WaterProvider waterProvider) {
    final List<_ChartDataPoint> data = [];
    final now = DateTime.now();
    
    if (_selectedPeriod == ChartPeriod.day) {
      // GÜN Modu: Son 7 gün
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey = _getDateKey(date);
        final entries = waterProvider.getDrinkEntriesForDate(dateKey);
        
        // Filtre uygula
        final filteredEntries = _selectedDrinkFilters.isEmpty
            ? entries
            : entries.where((e) => _selectedDrinkFilters.contains(e.drinkId)).toList();
        
        // İçecek bazında grupla
        final drinkAmounts = <String, double>{};
        for (var entry in filteredEntries) {
          drinkAmounts[entry.drinkId] = (drinkAmounts[entry.drinkId] ?? 0) + entry.amount;
        }
        
        // Etiket: Haftanın günleri
        final dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
        final dayIndex = date.weekday - 1;
        
        data.add(_ChartDataPoint(
          label: dayLabels[dayIndex],
          drinkAmounts: drinkAmounts,
          date: date,
        ));
      }
    } else if (_selectedPeriod == ChartPeriod.week) {
      // HAFTA Modu: Son 4 hafta - Her hafta için günlerin baş harfleri
      for (int i = 3; i >= 0; i--) {
        final weekStart = now.subtract(Duration(days: now.weekday - 1 + i * 7));
        final weekEnd = weekStart.add(const Duration(days: 6));
        final entries = waterProvider.getDrinkEntriesForDateRange(weekStart, weekEnd);
        
        // Filtre uygula
        final filteredEntries = _selectedDrinkFilters.isEmpty
            ? entries
            : entries.where((e) => _selectedDrinkFilters.contains(e.drinkId)).toList();
        
        // İçecek bazında grupla
        final drinkAmounts = <String, double>{};
        for (var entry in filteredEntries) {
          drinkAmounts[entry.drinkId] = (drinkAmounts[entry.drinkId] ?? 0) + entry.amount;
        }
        
        // Haftanın ilk gününün baş harfini al (Pazartesi=1, Salı=2, ..., Pazar=7)
        final dayLabels = ['P', 'S', 'Ç', 'P', 'C', 'C', 'P']; // Pazartesi, Salı, Çarşamba, Perşembe, Cuma, Cumartesi, Pazar
        final firstDayOfWeek = weekStart.weekday; // 1=Pazartesi, 7=Pazar
        final label = dayLabels[firstDayOfWeek - 1]; // Haftanın ilk gününün baş harfi
        
        data.add(_ChartDataPoint(
          label: label,
          drinkAmounts: drinkAmounts,
          date: weekStart,
        ));
      }
    } else {
      // AY Modu: Mevcut yılın 12 ayı (Ocak - Aralık)
      final monthNames = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
      
      for (int month = 1; month <= 12; month++) {
        final monthDate = DateTime(now.year, month, 1);
        final nextMonth = month == 12 
            ? DateTime(now.year + 1, 1, 1)
            : DateTime(now.year, month + 1, 1);
        final monthEnd = nextMonth.subtract(const Duration(days: 1));
        final entries = waterProvider.getDrinkEntriesForDateRange(monthDate, monthEnd);
        
        // Filtre uygula
        final filteredEntries = _selectedDrinkFilters.isEmpty
            ? entries
            : entries.where((e) => _selectedDrinkFilters.contains(e.drinkId)).toList();
        
        // İçecek bazında grupla
        final drinkAmounts = <String, double>{};
        for (var entry in filteredEntries) {
          drinkAmounts[entry.drinkId] = (drinkAmounts[entry.drinkId] ?? 0) + entry.amount;
        }
        
        data.add(_ChartDataPoint(
          label: monthNames[month - 1],
          drinkAmounts: drinkAmounts,
          date: monthDate,
        ));
      }
    }
    
    return data;
  }

  // Bar gruplarını oluştur
  List<BarChartGroupData> _buildBarGroups(List<_ChartDataPoint> chartData) {
    return chartData.asMap().entries.map((entry) {
      final index = entry.key;
      final dataPoint = entry.value;
      
      // Her bar için toplam miktarı hesapla (filtre uygula)
      double totalAmount = 0.0;
      final drinkAmounts = <String, double>{};
      
      if (_selectedDrinkFilters.isEmpty) {
        // Tüm içecekleri dahil et
        drinkAmounts.addAll(dataPoint.drinkAmounts);
      } else {
        // Sadece seçili içecekleri dahil et
        for (var filterId in _selectedDrinkFilters) {
          if (dataPoint.drinkAmounts.containsKey(filterId)) {
            drinkAmounts[filterId] = dataPoint.drinkAmounts[filterId]!;
          }
        }
      }
      
      totalAmount = drinkAmounts.values.fold(0.0, (sum, val) => sum + val);
      
      // Stacked bar için rodStackItems oluştur
      final rodStackItems = <BarChartRodStackItem>[];
      double currentY = 0.0; // Her bar SIFIRDAN başlamalı
      
      // Önemli içecekleri sırayla ekle
      final importantDrinks = ['water', 'coffee', 'tea', 'soda'];
      for (var drinkId in importantDrinks) {
        final amount = drinkAmounts[drinkId] ?? 0.0;
        if (amount > 0) {
          rodStackItems.add(
            BarChartRodStackItem(
              currentY, // fromY
              currentY + amount, // toY
              _drinkColors[drinkId] ?? Colors.grey,
            ),
          );
          currentY += amount;
        }
      }
      
      // Diğer içecekleri ekle
      for (var entry in drinkAmounts.entries) {
        if (!importantDrinks.contains(entry.key) && entry.value > 0) {
          rodStackItems.add(
            BarChartRodStackItem(
              currentY, // fromY
              currentY + entry.value, // toY
              _drinkColors[entry.key] ?? Colors.grey,
            ),
          );
          currentY += entry.value;
        }
      }
      
      // Tek bir BarChartRodData ile stacked bar oluştur
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: totalAmount,
            width: _selectedPeriod == ChartPeriod.month ? 12.0 : 20.0,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            rodStackItems: rodStackItems.isNotEmpty ? rodStackItems : null,
            color: rodStackItems.isEmpty ? Colors.grey[300] : null,
          ),
        ],
        barsSpace: 0,
      );
    }).toList();
  }

  // Maksimum Y değerini hesapla
  double _getMaxY(List<_ChartDataPoint> chartData) {
    double max = 0;
    for (var dataPoint in chartData) {
      final total = dataPoint.drinkAmounts.values.fold(0.0, (sum, val) => sum + val);
      if (total > max) max = total;
    }
    return (max * 1.2).ceilToDouble().clamp(500.0, double.infinity);
  }

  // Özet ve Detay Alanı
  Widget _buildSummaryAndDetailArea(BuildContext context) {
    return Consumer2<WaterProvider, UserProvider>(
      builder: (context, waterProvider, userProvider, child) {
        // Seçili bara göre tarih aralığını belirle
        DateTime? selectedStartDate;
        DateTime? selectedEndDate;
        String periodLabel = '';

        if (_touchedBarIndex != -1) {
          final chartData = _buildChartData(waterProvider);
          if (_touchedBarIndex >= 0 && _touchedBarIndex < chartData.length) {
            final dataPoint = chartData[_touchedBarIndex];
            selectedStartDate = dataPoint.date;
            selectedEndDate = dataPoint.date;
            
            switch (_selectedPeriod) {
              case ChartPeriod.day:
                periodLabel = _getWeekdayName(dataPoint.date.weekday);
                break;
              case ChartPeriod.week:
                periodLabel = '${_touchedBarIndex + 1}. Hafta';
                break;
              case ChartPeriod.month:
                final monthNames = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 
                                    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
                periodLabel = monthNames[dataPoint.date.month - 1];
                break;
            }
          }
        } else {
          // Hiçbir bar seçili değilse, varsayılan olarak bugünü/bu haftayı/bu ayı göster
          switch (_selectedPeriod) {
            case ChartPeriod.day:
              selectedStartDate = DateTime.now();
              selectedEndDate = selectedStartDate;
              periodLabel = 'Bugün';
              break;
            case ChartPeriod.week:
              final today = DateTime.now();
              final weekStart = today.subtract(Duration(days: today.weekday - 1));
              selectedStartDate = weekStart;
              selectedEndDate = weekStart.add(const Duration(days: 6));
              periodLabel = 'Bu Hafta';
              break;
            case ChartPeriod.month:
              final today = DateTime.now();
              selectedStartDate = DateTime(today.year, today.month, 1);
              selectedEndDate = DateTime(today.year, today.month + 1, 0);
              periodLabel = 'Bu Ay';
              break;
          }
        }

        if (selectedStartDate == null || selectedEndDate == null) {
          return const SizedBox.shrink();
        }

        final entries = waterProvider.getDrinkEntriesForDateRange(selectedStartDate, selectedEndDate);

        // Filtre uygula
        final filteredEntries = _selectedDrinkFilters.isEmpty
            ? entries
            : entries.where((e) => _selectedDrinkFilters.contains(e.drinkId)).toList();

        Map<String, double> drinkAmounts = {};
        for (var entry in filteredEntries) {
          drinkAmounts[entry.drinkId] = (drinkAmounts[entry.drinkId] ?? 0) + entry.amount;
        }

        // Sadece içilmiş içecekleri filtrele (amount > 0)
        final consumedDrinks = drinkAmounts.entries
            .where((entry) => entry.value > 0)
            .toList();

        if (consumedDrinks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Henüz sıvı alımı yapılmadı.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 18.0, // Büyütüldü (16 -> 18)
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$periodLabel Detayları',
              style: const TextStyle(
                fontSize: 22.0, // Büyütüldü (16 -> 22)
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5568),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.0, // Biraz daha dikey alan için küçültüldü (3.2 -> 3.0)
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: consumedDrinks.length,
              itemBuilder: (context, index) {
                final entry = consumedDrinks[index];
                final drinkId = entry.key;
                final amount = entry.value;
                final emoji = _getDrinkEmoji(drinkId);
                final color = _drinkColors[drinkId] ?? Colors.grey;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Vertical padding artırıldı (2.0 -> 4.0)
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Sol: İçecek İkonu
                      Text(
                        emoji,
                        style: const TextStyle(fontSize: 20), // Biraz küçültüldü (22 -> 20)
                      ),
                      const SizedBox(width: 8), // Width azaltıldı (10 -> 8)
                      // Sağ: İçecek İsmi ve Miktarı
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getDrinkName(drinkId),
                              style: TextStyle(
                                fontSize: 14.0, // Başlık font boyutu
                                height: 1.0, // Satır yüksekliği sıkılaştırıldı (1.1 -> 1.0)
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              UnitConverter.formatVolume(amount, userProvider.isMetric),
                              style: TextStyle(
                                fontSize: 15.0, // Değer font boyutu
                                height: 1.0, // Satır yüksekliği sıkılaştırıldı (1.1 -> 1.0)
                                color: Colors.grey[900],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // İçgörüler Dialog'unu göster
  void _showInsightDialog(BuildContext context, WaterProvider waterProvider, UserProvider userProvider) {
    // Bugünün verilerini al
    final today = DateTime.now();
    final todayKey = _getDateKey(today);
    final entries = waterProvider.getDrinkEntriesForDate(todayKey);
    
    // İçecek miktarlarını hesapla
    final Map<String, double> drinkAmounts = {};
    for (var entry in entries) {
      drinkAmounts[entry.drinkId] = (drinkAmounts[entry.drinkId] ?? 0.0) + entry.amount;
    }
    
    // Kafeinli içecekler
    final caffeineDrinks = ['coffee', 'tea', 'herbal_tea', 'green_tea', 'iced_coffee', 'cold_tea', 'energy_drink'];
    double caffeineVolume = 0.0;
    for (var drinkId in caffeineDrinks) {
      caffeineVolume += drinkAmounts[drinkId] ?? 0.0;
    }
    
    // Şekerli içecekler
    final sugaryDrinks = ['juice', 'fresh_juice', 'soda', 'lemonade', 'cold_tea', 'smoothie'];
    double sugaryVolume = 0.0;
    for (var drinkId in sugaryDrinks) {
      sugaryVolume += drinkAmounts[drinkId] ?? 0.0;
    }
    
    // Su miktarı
    final waterVolume = drinkAmounts['water'] ?? 0.0;
    final totalVolume = drinkAmounts.values.fold(0.0, (sum, amount) => sum + amount);
    
    // İçgörüler
    final hasHighCaffeine = caffeineVolume > waterVolume && caffeineVolume > 500;
    final hasHighSugar = sugaryVolume > waterVolume && sugaryVolume > 500;
    final hasGoodBalance = waterVolume >= (totalVolume * 0.6) && totalVolume > 0;
    final hasAnyData = totalVolume > 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Günlük Sağlık Özeti',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
        content: SingleChildScrollView(
          child: hasAnyData
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kafein Kotası
                    if (caffeineVolume > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildInsightCard(
                          icon: Icons.local_cafe,
                          iconColor: Colors.brown,
                          title: 'Kafein Kotası',
                          subtitle: UnitConverter.formatVolume(caffeineVolume, userProvider.isMetric),
                          message: hasHighCaffeine
                              ? '☕ Kafeinli içecekler suyunu geçti. Bir bardak suyla dengeleyin!'
                              : 'Kafein alımınız dengeli görünüyor.',
                          backgroundColor: hasHighCaffeine
                              ? Colors.orange.withValues(alpha: 0.1)
                              : Colors.green.withValues(alpha: 0.1),
                        ),
                      ),
                    
                    // Şeker Kotası
                    if (sugaryVolume > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildInsightCard(
                          icon: Icons.cake,
                          iconColor: Colors.pink,
                          title: 'Şeker Kotası',
                          subtitle: UnitConverter.formatVolume(sugaryVolume, userProvider.isMetric),
                          message: hasHighSugar
                              ? '🍰 Şekerli içecekler suyunu geçti. Bir bardak suyla dengeleyin!'
                              : 'Şeker alımınız dengeli görünüyor.',
                          backgroundColor: hasHighSugar
                              ? Colors.orange.withValues(alpha: 0.1)
                              : Colors.green.withValues(alpha: 0.1),
                        ),
                      ),
                    
                    // Genel Sağlık Yorumu
                    if (hasGoodBalance)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildInsightCard(
                          icon: Icons.favorite,
                          iconColor: Colors.red,
                          title: 'Sağlık Durumu',
                          subtitle: 'Mükemmel',
                          message: '💚 Böbreklerin bayram etti! Su tüketimin harika.',
                          backgroundColor: Colors.green.withValues(alpha: 0.1),
                        ),
                      )
                    else if (totalVolume > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildInsightCard(
                          icon: Icons.water_drop,
                          iconColor: Colors.blue,
                          title: 'Su Dengesi',
                          subtitle: '${((waterVolume / totalVolume) * 100).toStringAsFixed(0)}% Su',
                          message: 'Su oranını artırmayı deneyin. Hidrasyon için önemli!',
                          backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        ),
                      ),
                  ],
                )
              : const Text(
                  'Harika gidiyorsun! Her şey yolunda.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tamam',
              style: TextStyle(
                color: Color(0xFF4A5568),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
          color: iconColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  // Yardımcı metodlar
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Pazartesi';
      case DateTime.tuesday:
        return 'Salı';
      case DateTime.wednesday:
        return 'Çarşamba';
      case DateTime.thursday:
        return 'Perşembe';
      case DateTime.friday:
        return 'Cuma';
      case DateTime.saturday:
        return 'Cumartesi';
      case DateTime.sunday:
        return 'Pazar';
      default:
        return '';
    }
  }

  String _getDrinkEmoji(String drinkId) {
    switch (drinkId) {
      case 'water':
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

  String _getDrinkName(String drinkId) {
    final allDrinks = DrinkData.getDrinks();
    return allDrinks.firstWhere(
      (drink) => drink.id == drinkId,
      orElse: () => Drink(id: 'other', name: 'Diğer', caloriePer100ml: 0, hydrationFactor: 0),
    ).name;
  }
}

// Filtre Bottom Sheet içeriği (StatefulWidget olarak ayrıldı)
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
  State<_FilterBottomSheetContent> createState() => _FilterBottomSheetContentState();
}

class _FilterBottomSheetContentState extends State<_FilterBottomSheetContent> {
  late Set<String> _dialogSelectedFilters;

  @override
  void initState() {
    super.initState();
    _dialogSelectedFilters = Set<String>.from(widget.initialFilters);
  }

  // İçecek miktarlarını hesapla
  Map<String, double> _getDrinkAmounts() {
    final Map<String, double> amounts = {};
    for (var entry in widget.todayEntries) {
      amounts[entry.drinkId] = (amounts[entry.drinkId] ?? 0.0) + entry.amount;
    }
    return amounts;
  }

  // İçecek emoji'sini al (static helper method)
  static String _getDrinkEmojiStatic(String drinkId) {
    switch (drinkId) {
      case 'water':
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

  @override
  Widget build(BuildContext context) {
    final drinkAmounts = _getDrinkAmounts();
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
                                // 1. 'Tümü' seçildiğinde: Liste tamamen temizlenir (boş liste = Tümü)
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
                                    const Expanded(
                                      child: Text(
                                        'Tümü',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF4A5568),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // İçecek listesi
                          ...allDrinks.map((drink) {
                            final isSelected = _dialogSelectedFilters.contains(drink.id);
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
                                  // 2. Özel içecek seçildiğinde:
                                  setState(() {
                                    if (isSelected) {
                                      // İçecek zaten seçili, kaldır
                                      _dialogSelectedFilters.remove(drink.id);
                                      // Liste boş kaldıysa otomatik olarak 'Tümü' seçili olur (boş liste = Tümü)
                                      // Ek işlem gerekmez
                                    } else {
                                      // İçecek ekleniyor
                                      // Liste boşsa (Tümü seçili) direkt eklenir, zaten doğru davranış
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
                                        _getDrinkEmojiStatic(drink.id),
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
                                // Tümü seçimini temizle (liste boş = Tümü seçili)
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
                                // Parent widget'ın state'ini güncelle ve kapat
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

// Grafik veri noktası
class _ChartDataPoint {
  final String label;
  final Map<String, double> drinkAmounts;
  final DateTime date;
  
  _ChartDataPoint({
    required this.label,
    required this.drinkAmounts,
    required this.date,
  });
}
