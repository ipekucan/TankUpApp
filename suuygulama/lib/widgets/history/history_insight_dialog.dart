import 'package:flutter/material.dart';
import '../../providers/history_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/date_helpers.dart';
import '../../theme/app_text_styles.dart';

void showHistoryInsightDialog(
  BuildContext context,
  HistoryProvider historyProvider,
  UserProvider userProvider,
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

  // Kafein ve şeker içeriği kontrolü
  final caffeineDrinks = ['coffee', 'tea', 'green_tea', 'herbal_tea', 'iced_coffee', 'energy_drink'];
  final sugaryDrinks = ['soda', 'juice', 'smoothie', 'fresh_juice', 'lemonade'];

  bool hasHighCaffeine = false;
  bool hasHighSugar = false;
  double caffeineVolume = 0.0;
  double sugaryVolume = 0.0;

  for (var drinkId in caffeineDrinks) {
    final volume = drinkAmounts[drinkId] ?? 0.0;
    if (volume > 0) {
      caffeineVolume += volume;
    }
  }
  if (caffeineVolume > 500) { // 500ml'den fazla kafein içeren içecek
    hasHighCaffeine = true;
  }

  for (var drinkId in sugaryDrinks) {
    final volume = drinkAmounts[drinkId] ?? 0.0;
    if (volume > 0) {
      sugaryVolume += volume;
    }
  }
  if (sugaryVolume > 500) { // 500ml'den fazla şeker içeren içecek
    hasHighSugar = true;
  }

  // If warning is active, show specific alert dialog
  if (hasHighCaffeine || hasHighSugar) {
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
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(
            Icons.lightbulb,
            color: Colors.yellow[700],
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Günlük İçme Alışkanlığı',
            style: TextStyle(
              color: Color(0xFF4A5568),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!hasAnyData)
                Text(
                  'Bugün içecek kaydınız yok. İlk içeceği eklemek için Tank ekranını kullanabilirsiniz.',
                  style: AppTextStyles.bodyGrey.copyWith(fontSize: 16),
                )
              else if (hasGoodBalance)
                _buildInsightCard(
                  icon: Icons.water_drop,
                  iconColor: Colors.blue,
                  title: 'İdeal Su Dengesi',
                  subtitle: '${((waterVolume / totalVolume) * 100).toStringAsFixed(0)}% Su',
                  message: 'Harika! Su tüketiminiz ideal seviyede.',
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                )
              else if (totalVolume > 0)
                _buildInsightCard(
                  icon: Icons.water_drop,
                  iconColor: Colors.blue,
                  title: 'Su Dengesi',
                  subtitle: '${((waterVolume / totalVolume) * 100).toStringAsFixed(0)}% Su',
                  message: 'Su oranını artırmayı deneyin. Hidrasyon için önemli!',
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                ),
            ],
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

void _showHealthWarningDialog(
  BuildContext context,
  bool hasHighCaffeine,
  bool hasHighSugar,
  double caffeineVolume,
  double sugaryVolume,
  UserProvider userProvider,
) {
  String title = 'Dikkat!';
  String message = 'Bugünkü içecek tüketiminizle ilgili bazı konulara dikkat etmeniz faydalı olabilir:\n\n';

  if (hasHighCaffeine) {
    message += '• Kafein içeren içecekler (${caffeineVolume.toStringAsFixed(0)}ml) tüketiminiz yüksek.\n';
  }
  if (hasHighSugar) {
    message += '• Şeker içeren içecekler (${sugaryVolume.toStringAsFixed(0)}ml) tüketiminiz yüksek.\n';
  }

  message += '\nDengeli su tüketimi vücudunuz için daha faydalı olacaktır.';

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange[700],
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF4A5568),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Text(
            message,
            style: AppTextStyles.bodyGrey.copyWith(fontSize: 16),
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

Widget _buildInsightCard({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
  required String message,
  required Color backgroundColor,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
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
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF718096),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
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