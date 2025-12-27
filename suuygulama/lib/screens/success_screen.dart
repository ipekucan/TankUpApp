import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../providers/achievement_provider.dart';
import '../providers/challenge_provider.dart';
import '../providers/water_provider.dart';
import '../providers/user_provider.dart';
import '../utils/unit_converter.dart';
import '../models/achievement_model.dart';
import '../widgets/challenge_card.dart';
import 'history_screen.dart';

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
      backgroundColor: AppColors.verySoftBlue,
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
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A5568),
                        letterSpacing: 0.5,
                      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
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
                  _buildChallengesTab(),
                  _buildAchievementsTab(),
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
    // HistoryScreen içeriğine ampul butonunu prop olarak geçir
    return HistoryScreen(
      hideAppBar: true,
      lightbulbButton: _buildInsightLightbulbButton(context),
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

  // Tarih anahtarı oluştur (yardımcı metod)
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Mücadeleler Sekmesi - Oyunlaştırma Merkezi
  Widget _buildChallengesTab() {
    return Consumer2<ChallengeProvider, WaterProvider>(
      builder: (context, challengeProvider, waterProvider, child) {
        final activeChallenges = challengeProvider.activeIncompleteChallenges;
        final now = DateTime.now();
        final isBefore3PM = now.hour < 15;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BÖLÜM 1: GÜNLÜK GÖREV KARTI (Daily Quest Header)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFF6B6B), // Turuncu-Kırmızı
                      Color(0xFFFF8E53), // Turuncu
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Sol: Hediye Kutusu İkonu
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.card_giftcard,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Orta: Başlık ve Alt Başlık
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Günün Görevi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isBefore3PM
                                ? '15:00\'dan önce 1.5 Litre su iç!'
                                : 'Bugün 1.5 Litre su iç!',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Sağ: Coin Ödülü
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.monetization_on,
                            color: Colors.amber,
                            size: 20.0,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '+50 Coin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // BÖLÜM 2: AKTİF MÜCADELE (My Active Challenge)
              if (activeChallenges.isNotEmpty) ...[
                const Text(
                  'Devam Eden Mücadelen',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A5568),
                  ),
                ),
                const SizedBox(height: 12),
                _buildActiveChallengeStatusCard(activeChallenges.first),
                const SizedBox(height: 24),
              ] else ...[
                const Text(
                  'Devam Eden Mücadelen',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A5568),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'Henüz aktif mücadele yok',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // BÖLÜM 3: KEŞFET BUTONU
              OutlinedButton.icon(
                onPressed: () {
                  // Şimdilik boş - ileride mücadele keşfet ekranına yönlendirilebilir
                  print('Yeni Mücadeleler Keşfet butonuna tıklandı');
                },
                icon: const Icon(Icons.explore),
                label: const Text('Yeni Mücadeleler Keşfet'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Aktif Mücadele Durum Kartı (Kompakt, İlerleme Barı ile)
  Widget _buildActiveChallengeStatusCard(Challenge challenge) {
    final progressPercentage = (challenge.progress * 100).toInt();
    // İlerleme metni varsa onu kullan, yoksa currentProgress/targetValue'yu kullan
    final progressText = challenge.progressText.isNotEmpty
        ? challenge.progressText
        : '${challenge.currentProgress.toStringAsFixed(1)} / ${challenge.targetValue.toStringAsFixed(1)}';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.withValues(alpha: 0.15),
            Colors.cyan.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.teal.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Sol: İkon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  challenge.icon,
                  color: Colors.teal[700],
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              // Orta: Başlık
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progressText,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // İlerleme Barı
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: challenge.progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.teal.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal[700]!),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$progressPercentage%',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
  
  // Başarılar Sekmesi
  Widget _buildAchievementsTab() {
    return Consumer<AchievementProvider>(
      builder: (context, achievementProvider, child) {
        final achievements = achievementProvider.achievements;
        
        // Varsayılan başarılar listesi (eğer yoksa)
        final defaultAchievements = [
          {'id': 'first_cup', 'name': 'İlk Bardak', 'emoji': '💧', 'goal': 'İlk suyunu iç'},
          {'id': 'first_step', 'name': 'İlk Su', 'emoji': '💧', 'goal': 'İlk su içişini tamamla'},
          {'id': 'first_litre', 'name': 'İlk Litre', 'emoji': '🌊', 'goal': '1 litre su iç'},
          {'id': 'fish_champion', 'name': 'Balık Şampiyonu', 'emoji': '🐠', 'goal': 'Balık karakterini kazan'},
          {'id': 'daily_goal', 'name': 'Günlük Hedef', 'emoji': '🎯', 'goal': 'Günlük su hedefine ulaş'},
          {'id': 'streak_3', 'name': '3 Gün Seri', 'emoji': '🔥', 'goal': '3 gün üst üste hedefe ulaş'},
          {'id': 'streak_7', 'name': '7 Gün Seri', 'emoji': '⭐', 'goal': '7 gün üst üste hedefe ulaş'},
          {'id': 'water_master', 'name': 'Su Ustası', 'emoji': '👑', 'goal': 'Toplamda 10 litre su iç'},
        ];
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Başarılar Listesi
              ...defaultAchievements.map((defaultAchievement) {
                final achievement = achievements.firstWhere(
                  (a) => a.id == defaultAchievement['id'],
                  orElse: () => Achievement(
                    id: defaultAchievement['id'] as String,
                    name: defaultAchievement['name'] as String,
                    description: '',
                    coinReward: 0,
                  ),
                );
                
                final isUnlocked = achievement.isUnlocked;
                final goalText = defaultAchievement['goal'] ?? '';
                
                Widget achievementCard = Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUnlocked ? Colors.white : Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isUnlocked 
                          ? AppColors.softPinkButton.withValues(alpha: 0.3)
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                    boxShadow: isUnlocked
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      // Emoji/İkon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? AppColors.softPinkButton.withValues(alpha: 0.15)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            defaultAchievement['emoji'] as String,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Başarı Bilgisi
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    achievement.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isUnlocked
                                          ? const Color(0xFF4A5568)
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                                if (isUnlocked)
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isUnlocked 
                                  ? (achievement.description.isNotEmpty 
                                      ? achievement.description 
                                      : 'Başarıyı kazandın!')
                                  : 'Kilidi açmak için: $goalText',
                              style: TextStyle(
                                fontSize: 12,
                                color: isUnlocked
                                    ? Colors.grey[600]
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Durum İkonu
                      isUnlocked
                          ? const Text(
                              '✅',
                              style: TextStyle(fontSize: 24),
                            )
                          : const Text(
                              '🔒',
                              style: TextStyle(fontSize: 24),
                            ),
                    ],
                  ),
                );
                
                // Kazanılmayan başarılar için %50 opaklık
                if (!isUnlocked) {
                  return Opacity(
                    opacity: 0.5,
                    child: achievementCard,
                  );
                }
                
                return achievementCard;
              }),
              
              const SizedBox(height: 24),
              
              // Gelecek Hedefler
              _buildFutureGoals(),
            ],
          ),
        );
      },
    );
  }


  // Gelecek Hedefler Bölümü
  Widget _buildFutureGoals() {
    final futureGoals = [
      {'name': 'Okyanus Kaşifi', 'emoji': '🌊', 'description': '10 gün üst üste hedefe ulaş'},
      {'name': 'Şekersiz Şövalye', 'emoji': '🛡️', 'description': '1 ay şekersiz içecek tüketme'},
      {'name': 'Hidrasyon Ustası', 'emoji': '💎', 'description': 'Toplamda 100 litre su iç'},
      {'name': 'Gece Koruyucusu', 'emoji': '🌙', 'description': '30 gün gece sadece su iç'},
    ];

    return Container(
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
          const Text(
            'Sıradaki Adımların',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 16),
          ...futureGoals.map((goal) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(
                    goal['emoji'] as String,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal['name'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A5568),
                          ),
                        ),
                        Text(
                          goal['description'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],


                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
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

