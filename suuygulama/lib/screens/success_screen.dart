import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import '../providers/user_provider.dart';
import '../utils/unit_converter.dart';
import '../utils/date_helpers.dart';
import '../theme/app_text_styles.dart';
import '../widgets/success/statistics_tab.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> with TickerProviderStateMixin {
  late AnimationController _lightbulbAnimationController; // Ampul animasyonu için

  @override
  void initState() {
    super.initState();
    
    // Ampul animasyon kontrolcüsü (1.5 saniye, only runs when warning is active)
    _lightbulbAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    // Don't start automatically - will be controlled by health warning state
  }

  @override
  void dispose() {
    _lightbulbAnimationController.dispose();
    super.dispose();
  }

  String _getFormattedDate() {
    return DateHelpers.getFormattedTurkishDate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Padding(
            padding: const EdgeInsets.only(top: 24.0, left: 0, right: 0, bottom: 0),
            child: Column(
              children: [
                // Header Row: Only Close Button (Right-aligned)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Close Button (Compact Circle)
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
                
                // İçerik
                Expanded(
                  child: _buildStatisticsTab(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // İstatistikler Sekmesi
  Widget _buildStatisticsTab() {
    return StatisticsTab(
      lightbulbButton: _buildInsightLightbulbButton(context),
      dateText: _getFormattedDate(),
    );
  }

  // Akıllı Ampul İkonu (İçgörüler) - Smart Health Alert System
  Widget _buildInsightLightbulbButton(BuildContext context) {
    return Consumer2<HistoryProvider, UserProvider>(
      builder: (context, historyProvider, userProvider, child) {
        // Bugünün verilerini al
        final today = DateTime.now();
        final todayKey = DateHelpers.toDateKey(today);
        final entries = historyProvider.getDrinkEntriesForDate(todayKey);
        
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
        
        // Health Threshold Calculation (Absolute thresholds)
        const double caffeineThreshold = 500.0; // ml
        const double sugarThreshold = 1000.0; // ml (1 Litre)
        
        final hasHighCaffeine = caffeineVolume > caffeineThreshold;
        final hasHighSugar = sugaryVolume > sugarThreshold;
        final isHealthWarningActive = hasHighCaffeine || hasHighSugar;
        
        // Control animation based on warning state
        if (isHealthWarningActive && !_lightbulbAnimationController.isAnimating) {
          _lightbulbAnimationController.repeat(reverse: true);
        } else if (!isHealthWarningActive && _lightbulbAnimationController.isAnimating) {
          _lightbulbAnimationController.stop();
          _lightbulbAnimationController.reset();
        }
        
        return AnimatedBuilder(
          animation: _lightbulbAnimationController,
          builder: (context, child) {
            // Breathing animation: Scale pulse (1.0 -> 1.1x) when warning is active
            final scale = isHealthWarningActive 
                ? 1.0 + (_lightbulbAnimationController.value * 0.1)
                : 1.0;
            
            // Glow shadow effect when warning is active
            final glowIntensity = isHealthWarningActive
                ? 8.0 + (_lightbulbAnimationController.value * 12.0) // 8 -> 20
                : 0.0;
            
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  // Depth shadow
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                  // Glow effect (only when warning is active)
                  if (isHealthWarningActive)
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.6),
                      blurRadius: glowIntensity,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showInsightDialog(
                    context, 
                    historyProvider, 
                    userProvider,
                    isHealthWarningActive,
                    hasHighCaffeine,
                    hasHighSugar,
                    caffeineVolume,
                    sugaryVolume,
                  ),
                  borderRadius: BorderRadius.circular(50),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Color coding: Yellow/Amber when warning, White when normal
                        color: isHealthWarningActive 
                            ? Colors.yellow[700] 
                            : Colors.white,
                      ),
                      child: Icon(
                        Icons.lightbulb,
                        // Icon color: White when warning, Grey when normal
                        color: isHealthWarningActive 
                            ? Colors.white 
                            : Colors.grey[400],
                        size: 28.0,
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

  // İçgörüler Dialog'unu göster - Contextual Info Dialog
  void _showInsightDialog(
    BuildContext context,
    HistoryProvider historyProvider,
    UserProvider userProvider,
    bool isHealthWarningActive,
    bool hasHighCaffeine,
    bool hasHighSugar,
    double caffeineVolume,
    double sugaryVolume,
  ) {
    // Bugünün verilerini al
    final today = DateTime.now();
    final todayKey = DateHelpers.toDateKey(today);
    final entries = historyProvider.getDrinkEntriesForDate(todayKey);
    
    // İçecek miktarlarını hesapla
    final Map<String, double> drinkAmounts = {};
    for (var entry in entries) {
      drinkAmounts[entry.drinkId] = (drinkAmounts[entry.drinkId] ?? 0.0) + entry.amount;
    }
    
    // Su miktarı
    final waterVolume = drinkAmounts['water'] ?? 0.0;
    final totalVolume = drinkAmounts.values.fold(0.0, (sum, amount) => sum + amount);
    final hasGoodBalance = waterVolume >= (totalVolume * 0.6) && totalVolume > 0;
    final hasAnyData = totalVolume > 0;
    
    // If warning is active, show specific alert dialog
    if (isHealthWarningActive) {
      _showHealthWarningDialog(
        context,
        hasHighCaffeine,
        hasHighSugar,
        caffeineVolume,
        sugaryVolume,
        userProvider,
      );
      return;
    }
    
    // Normal state: Show standard daily health summary
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
                          message: 'Kafein alımınız dengeli görünüyor.',
                          backgroundColor: Colors.green.withValues(alpha: 0.1),
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
                          message: 'Şeker alımınız dengeli görünüyor.',
                          backgroundColor: Colors.green.withValues(alpha: 0.1),
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

  // Health Warning Dialog - Shows specific alert when thresholds are exceeded
  void _showHealthWarningDialog(
    BuildContext context,
    bool hasHighCaffeine,
    bool hasHighSugar,
    double caffeineVolume,
    double sugaryVolume,
    UserProvider userProvider,
  ) {
    // Determine which warnings to show
    String header = 'Dikkat: Sağlık Sınırı Aşıldı!';
    String body = '';
    IconData warningIcon = Icons.warning;
    
    if (hasHighCaffeine && hasHighSugar) {
      body = 'Bugün ${UnitConverter.formatVolume(caffeineVolume, userProvider.isMetric)} kafeinli içecek ve ${UnitConverter.formatVolume(sugaryVolume, userProvider.isMetric)} şekerli içecek tükettin. Bu miktarlar önerilen günlük limitleri aşıyor. Böbreklerini ve genel sağlığını korumak için daha fazla su içmeyi ve bu içecekleri azaltmayı düşün.';
    } else if (hasHighCaffeine) {
      header = 'Dikkat: Kafein Sınırı Aşıldı!';
      body = 'Bugün ${UnitConverter.formatVolume(caffeineVolume, userProvider.isMetric)} kafeinli içecek tükettin. Bu miktar önerilen günlük limiti (500ml) aşıyor. Fazla kafein uyku kalitesini etkileyebilir ve dehidrasyona neden olabilir. Daha fazla su içmeyi unutma!';
    } else if (hasHighSugar) {
      header = 'Dikkat: Şeker Sınırı Aşıldı!';
      body = 'Bugün ${UnitConverter.formatVolume(sugaryVolume, userProvider.isMetric)} şekerli içecek tükettin. Bu miktar önerilen günlük limiti (1 Litre) aşıyor. Fazla şeker böbreklerini yorabilir ve sağlık sorunlarına yol açabilir. Su tüketimini artırmayı ve şekerli içecekleri azaltmayı düşün.';
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              warningIcon,
              color: Colors.amber[700],
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                header,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A5568),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          body,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF4A5568),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Anladım',
              style: TextStyle(
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


