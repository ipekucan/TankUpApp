import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../providers/water_provider.dart';
import '../providers/user_provider.dart';
import '../models/drink_model.dart';
import '../utils/unit_converter.dart';
import '../utils/drink_helpers.dart';
import '../utils/date_helpers.dart';
import '../theme/app_text_styles.dart';
import '../services/chart_data_service.dart' show ChartDataService, ChartPeriod;
import '../widgets/history/chart_view.dart';
import '../widgets/history/period_selector.dart';
import '../widgets/history/insight_card.dart';

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

  @override
  void initState() {
    super.initState();
    // Her ekran açılışında varsayılan olarak 'Gün' modunu seç
    _selectedPeriod = ChartPeriod.day;
    _touchedBarIndex = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6), // Cool grey background for better contrast
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Text(
                'İstatistikler',
                style: GoogleFonts.nunito(
                  color: const Color(0xFF4A5568),
                  fontWeight: FontWeight.w600,
                  fontSize: 20.0,
                  letterSpacing: -0.3,
                ),
              ),
              actions: [
                // Akıllı Ampul İkonu (İçgörüler)
                Consumer2<WaterProvider, UserProvider>(
                  builder: (context, waterProvider, userProvider, child) {
                    return InsightCard(
                      onTap: () => _showInsightDialog(
                        context,
                        waterProvider,
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
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Filtre Butonu (En Solda)
                    _buildFilterButton(context),
                    const SizedBox(width: 12),
                    // Zaman Butonları
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
              ),
            ),
      body: Stack(
        children: [
          // Layer 1 (Back): Scrollable content - fills entire screen
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), // Reduced top padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    ),

                  const SizedBox(height: 16.0),

                  // İçerik: İki Ayrı Kutu
                  Column(
                    children: [
                      // KUTU 1: Grafik Kutusu (Premium Card Style - Compact)
                      Container(
                        height: 250.0, // Increased height for better balance
                        width: double.infinity, // Force full width expansion
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08), // More visible shadow
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16.0), // Reduced padding
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Section Title (Bold, left-aligned)
                            Text(
                              'Sıvı Tüketim Grafiği',
                              style: GoogleFonts.nunito(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D3748),
                                letterSpacing: -0.3,
                              ),
                              textAlign: TextAlign.start, // Left-aligned
                            ),
                            const SizedBox(height: 12.0), // Reduced spacing
                            // Grafik Alanı (Expanded to fill remaining space)
                            Expanded(
                              child: Consumer<WaterProvider>(
                                builder: (context, waterProvider, child) {
                                  final chartData =
                                      ChartDataService.buildChartData(
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
                      ),

                      const SizedBox(height: 20.0),

                      // KUTU 2: Drink Consumption Grid (Premium Card Style)
                      _buildSummaryAndDetailArea(context),
                    ],
                  ),
                ],
              ),
            ),
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

  // Old _buildInsightLightbulbButton method removed - now using InsightCard widget

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

  // Old _buildPeriodButton method removed - now using PeriodSelector widget
  // Old _buildBarChart, _buildChartData, _buildBarGroups, _getMaxY methods removed
  // Now using ChartDataService and ChartView widget

  // Özet ve Detay Alanı
  Widget _buildSummaryAndDetailArea(BuildContext context) {
    return Consumer2<WaterProvider, UserProvider>(
      builder: (context, waterProvider, userProvider, child) {
        // Seçili bara göre tarih aralığını belirle
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
          // Hiçbir bar seçili değilse, varsayılan olarak bugünü/bu haftayı/bu ayı göster
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

        // Filtre uygula
        final filteredEntries = _selectedDrinkFilters.isEmpty
            ? entries
            : entries
                  .where((e) => _selectedDrinkFilters.contains(e.drinkId))
                  .toList();

        Map<String, double> drinkAmounts = {};
        for (var entry in filteredEntries) {
          drinkAmounts[entry.drinkId] =
              (drinkAmounts[entry.drinkId] ?? 0) + entry.amount;
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

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3.0, // Wide/flat cards (reverted from 2.1)
            crossAxisSpacing: 16, // Increased spacing
            mainAxisSpacing: 16, // Increased spacing
          ),
          itemCount: consumedDrinks.length,
          itemBuilder: (context, index) {
            final entry = consumedDrinks[index];
            final drinkId = entry.key;
            final amount = entry.value;
            final emoji = DrinkHelpers.getEmoji(drinkId);
            final color = ChartDataService.drinkColors[drinkId] ?? Colors.grey;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduced padding for compact layout
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08), // More visible shadow
                    blurRadius: 10,
                    offset: const Offset(0, 4), // Increased offset for better depth
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Left: Icon in a light-colored circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15), // Light colored circle
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Right: Drink Name and Amount
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            DrinkHelpers.getName(drinkId),
                            style: GoogleFonts.nunito(
                              fontSize: 14.0, // Reduced from 15.0
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2D3748), // Dark grey
                              letterSpacing: -0.2,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2.0), // Reduced spacing
                        Flexible(
                          child: Text(
                            UnitConverter.formatVolume(
                              amount,
                              userProvider.isMetric,
                            ),
                            style: GoogleFonts.nunito(
                              fontSize: 13.0, // Reduced from 14.0
                              fontWeight: FontWeight.w500,
                              color: color, // Primary color for amount
                              letterSpacing: 0.1,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // İçgörüler Dialog'unu göster
  void _showInsightDialog(
    BuildContext context,
    WaterProvider waterProvider,
    UserProvider userProvider,
  ) {
    // Bugünün verilerini al
    final today = DateTime.now();
    final todayKey = DateHelpers.toDateKey(today);
    final entries = waterProvider.getDrinkEntriesForDate(todayKey);

    // İçecek miktarlarını hesapla
    final Map<String, double> drinkAmounts = {};
    for (var entry in entries) {
      drinkAmounts[entry.drinkId] =
          (drinkAmounts[entry.drinkId] ?? 0.0) + entry.amount;
    }

    // Kafeinli içecekler
    final caffeineDrinks = [
      'coffee',
      'tea',
      'herbal_tea',
      'green_tea',
      'iced_coffee',
      'cold_tea',
      'energy_drink',
    ];
    double caffeineVolume = 0.0;
    for (var drinkId in caffeineDrinks) {
      caffeineVolume += drinkAmounts[drinkId] ?? 0.0;
    }

    // Şekerli içecekler
    final sugaryDrinks = [
      'juice',
      'fresh_juice',
      'soda',
      'lemonade',
      'cold_tea',
      'smoothie',
    ];
    double sugaryVolume = 0.0;
    for (var drinkId in sugaryDrinks) {
      sugaryVolume += drinkAmounts[drinkId] ?? 0.0;
    }

    // Su miktarı
    final waterVolume = drinkAmounts['water'] ?? 0.0;
    final totalVolume = drinkAmounts.values.fold(
      0.0,
      (sum, amount) => sum + amount,
    );

    // İçgörüler
    final hasHighCaffeine =
        caffeineVolume > waterVolume && caffeineVolume > 500;
    final hasHighSugar = sugaryVolume > waterVolume && sugaryVolume > 500;
    final hasGoodBalance =
        waterVolume >= (totalVolume * 0.6) && totalVolume > 0;
    final hasAnyData = totalVolume > 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Günlük Sağlık Özeti', style: AppTextStyles.heading3),
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
                          subtitle: UnitConverter.formatVolume(
                            caffeineVolume,
                            userProvider.isMetric,
                          ),
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
                          subtitle: UnitConverter.formatVolume(
                            sugaryVolume,
                            userProvider.isMetric,
                          ),
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
                          message:
                              '💚 Böbreklerin bayram etti! Su tüketimin harika.',
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
                          subtitle:
                              '${((waterVolume / totalVolume) * 100).toStringAsFixed(0)}% Su',
                          message:
                              'Su oranını artırmayı deneyin. Hidrasyon için önemli!',
                          backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        ),
                      ),
                  ],
                )
              : const Text(
                  'Harika gidiyorsun! Her şey yolunda.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tamam',
              style: AppTextStyles.bodyLarge.copyWith(
                color: const Color(0xFF4A5568),
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
        border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyLarge),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.bodyGrey),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: AppTextStyles.bodySmall.copyWith(
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
            final todayKey = DateHelpers.toDateKey(today);
            final todayEntries = waterProvider.getDrinkEntriesForDate(todayKey);

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
              waterProvider: waterProvider,
              todayEntries: todayEntries,
              drinkAmounts: {},
            );
          },
        ),
      ),
    );
  }

  // Yardımcı metodlar (moved to DrinkHelpers and DateHelpers)
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

// Old _ChartDataPoint class removed - now using ChartDataPoint from ChartDataService
