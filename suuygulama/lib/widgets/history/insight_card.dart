import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/water_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/date_helpers.dart';

/// Insight card widget displaying a lightbulb button with health insights.
/// Shows animated warning indicators when health issues are detected.
class InsightCard extends StatefulWidget {
  final VoidCallback onTap;

  const InsightCard({
    super.key,
    required this.onTap,
  });

  @override
  State<InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<InsightCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Ampul animasyon kontrolcüsü (1.5 saniye, sürekli döngü)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        final caffeineDrinks = [
          'coffee',
          'tea',
          'herbal_tea',
          'green_tea',
          'iced_coffee',
          'cold_tea',
          'energy_drink'
        ];
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
          animation: _animationController,
          builder: (context, child) {
            // Uyarı varsa animasyonlu scale değeri (1.0 -> 1.2)
            final scale = hasWarning
                ? 1.0 + (_animationController.value * 0.2)
                : 1.0;

            // Uyarı varsa animasyonlu glow değeri (blur radius)
            final glowIntensity = hasWarning
                ? 8.0 + (_animationController.value * 12.0) // 8 -> 20 arası
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
                      size: 34.0,
                    ),
                    onPressed: widget.onTap,
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
}

