import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../providers/water_provider.dart';
import '../providers/user_provider.dart';
import '../utils/unit_converter.dart';
import '../utils/date_helpers.dart';
import '../theme/app_text_styles.dart';
import '../widgets/success/statistics_tab.dart';
import '../widgets/success/challenges_tab.dart';
import '../widgets/success/achievements_tab.dart';
import '../core/constants/app_constants.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final PageController _challengePageController = PageController();
  late AnimationController _lightbulbAnimationController; // Ampul animasyonu için

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.index = 0; // Varsayılan olarak İstatistikler sekmesi (index 0)
    
    // Ampul animasyon kontrolcüsü (1.5 saniye, sürekli döngü)
    _lightbulbAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _challengePageController.dispose();
    _lightbulbAnimationController.dispose();
    super.dispose();
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final weekdays = [
      'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 
      'Cuma', 'Cumartesi', 'Pazar'
    ];
    final day = now.day;
    final month = months[now.month - 1];
    final weekday = weekdays[now.weekday - 1];
    return '$day $month $weekday';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSubtle,
      body: SafeArea(
        child: Column(
          children: [
            // Üst Bilgi - Tarih ve Kapatma Butonu
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _getFormattedDate(),
                      style: AppTextStyles.dateText,
                    ),
                  ),
                  // Kapatma Butonu (X)
                  GestureDetector(
                    onTap: () {
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFF4A5568),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Üçlü Navigasyon - Tab Butonları
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
                vertical: AppConstants.mediumSpacing,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.softPinkButton,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF4A5568),
                  labelStyle: AppTextStyles.tabLabelSelected,
                  unselectedLabelStyle: AppTextStyles.tabLabelUnselected,
                  tabs: const [
                    Tab(text: 'İstatistikler'),
                    Tab(text: 'Mücadeleler'),
                    Tab(text: 'Başarılar'),
                  ],
                ),
              ),
            ),
            
            // İçerik
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildStatisticsTab(),
                  const ChallengesTab(),
                  const AchievementsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // İstatistikler Sekmesi
  Widget _buildStatisticsTab() {
    return StatisticsTab(
      lightbulbButton: _buildInsightLightbulbButton(context),
    );
  }

  // Akıllı Ampul İkonu (İçgörüler)
  Widget _buildInsightLightbulbButton(BuildContext context) {
    return Consumer2<WaterProvider, UserProvider>(
      builder: (context, waterProvider, userProvider, child) {
        // Bugünün verilerini al
        final today = DateTime.now();
        final todayKey = DateHelpers.toDateKey(today);
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
            
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  // Derinlik için gölge (küçültüldü)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10, // Küçültüldü (15 -> 10)
                    spreadRadius: 1, // Küçültüldü (2 -> 1)
                    offset: const Offset(0, 2), // Küçültüldü (4 -> 2)
                  ),
                  // Glow efekti (sadece uyarı varsa)
                  if (hasWarning)
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.6),
                      blurRadius: glowIntensity,
                      spreadRadius: 2, // Küçültüldü (3 -> 2)
                    ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showInsightDialog(context, waterProvider, userProvider),
                  borderRadius: BorderRadius.circular(50),
                  child: Transform.scale(
                    scale: scale,
                      child: Container(
                      padding: const EdgeInsets.all(10.0), // Küçültüldü (14 -> 10)
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // İkon (küçültüldü)
                          Icon(
                            Icons.lightbulb,
                            color: hasWarning ? Colors.amber : Colors.grey[400],
                            size: 28.0, // Küçültüldü (40 -> 28)
                          ),
                          // Kırmızı badge (uyarı varsa)
                          if (hasWarning)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // İçgörüler Dialog'unu göster
  void _showInsightDialog(BuildContext context, WaterProvider waterProvider, UserProvider userProvider) {
    // Bugünün verilerini al
    final today = DateTime.now();
    final todayKey = DateHelpers.toDateKey(today);
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
              : Text(
                  'Harika gidiyorsun! Her şey yolunda.',
                  style: AppTextStyles.bodyGrey.copyWith(fontSize: 16),
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

  // Tarih anahtarı oluştur (moved to DateHelpers utility class)

  // Removed - Now using ChallengesTab and AchievementsTab widgets
}

// Dots Indicator Widget (PageView için)
class _ChallengeDotsIndicator extends StatefulWidget {
  final PageController pageController;
  final int itemCount;

  const _ChallengeDotsIndicator({
    required this.pageController,
    required this.itemCount,
  });

  @override
  State<_ChallengeDotsIndicator> createState() => _ChallengeDotsIndicatorState();
}

class _ChallengeDotsIndicatorState extends State<_ChallengeDotsIndicator> {
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    widget.pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_onPageChanged);
    super.dispose();
  }

  void _onPageChanged() {
    if (widget.pageController.page != null) {
      setState(() {
        _currentPage = widget.pageController.page!.round();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.itemCount,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentPage ? AppColors.softPinkButton : Colors.grey[300],
          ),
        ),
      ),
    );
  }
}

