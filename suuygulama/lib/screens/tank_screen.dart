import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../utils/app_colors.dart';
import '../providers/water_provider.dart';
import '../providers/axolotl_provider.dart';
import '../providers/user_provider.dart';
import '../providers/achievement_provider.dart';
import '../models/axolotl_model.dart';

class TankScreen extends StatefulWidget {
  const TankScreen({super.key});

  @override
  State<TankScreen> createState() => _TankScreenState();
}

class _TankScreenState extends State<TankScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.verySoftBlue,
      body: SafeArea(
        child: _buildTankView(), // Tank sayfası
      ),
    );
  }

  // Tank görünümü (Ana sayfa)
  Widget _buildTankView() {
    return Consumer4<WaterProvider, AxolotlProvider, UserProvider, AchievementProvider>(
      builder: (context, waterProvider, axolotlProvider, userProvider, achievementProvider, child) {
        final fillPercentage = waterProvider.tankFillPercentage;
        
        return Column(
          children: [
            // Coin sayacı - En üstte sağda
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldCoin,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.goldCoin.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${waterProvider.tankCoins}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Boşluk - tankı ortalamak için
            const Spacer(),
            
            // Tank Container - Merkezde
            Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  // Su seviyesi (doluluk) - Tankın doluluk oranına göre mavi doluluk efekti
                  // Sadece fillPercentage > 0 ise su göster (consumedAmount / dailyGoal)
                  if (fillPercentage > 0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        height: MediaQuery.of(context).size.height * 0.5 * fillPercentage,
                        decoration: BoxDecoration(
                          color: AppColors.waterColor.withValues(alpha: 0.7),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(40),
                            bottomRight: Radius.circular(40),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.waterColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Tank dekorasyonları - Su seviyesinin üzerinde sabitlenmiş
                  ...axolotlProvider.tankDecorations.map((decoration) {
                    return _buildTankDecoration(
                      decoration,
                      MediaQuery.of(context).size.width * 0.85,
                      MediaQuery.of(context).size.height * 0.5,
                    );
                  }).toList(),
                  // Aksolot maskot - Su seviyesinin üzerinde, floating animasyonlu
                  Center(
                    child: _FloatingAxolotl(
                      axolotlProvider: axolotlProvider,
                      fillPercentage: fillPercentage,
                      tankHeight: MediaQuery.of(context).size.height * 0.5,
                      buildAxolotl: _buildAxolotl,
                    ),
                  ),
                ],
              ),
            ),
            
            // Boşluk - butonu alta itmek için
            const Spacer(),
            
            // Su İç Butonu - En altta (şık, büyük ve yumuşak köşeli)
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0, left: 20, right: 20),
              child: _buildDrinkWaterButton(
                waterProvider,
                userProvider,
                achievementProvider,
              ),
            ),
          ],
        );
      },
    );
  }


  // Aksolot maskot çizimi - AxolotlProvider'dan verileri alarak şirin, yuvarlak hatlı ve pastel tonlarda çizer
  Widget _buildAxolotl(AxolotlProvider provider) {
    final skinColor = _getSkinColor(provider.skinColor);
    final eyeColor = _getEyeColor(provider.eyeColor);
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Aksolot gövdesi - Yuvarlak ve pastel tonlarda
        Container(
          width: 110,
          height: 90,
          decoration: BoxDecoration(
            color: skinColor,
            borderRadius: BorderRadius.circular(55),
            boxShadow: [
              BoxShadow(
                color: skinColor.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        // Sol yanak (yuvarlak, pastel)
        Positioned(
          left: 15,
          top: 35,
          child: Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: skinColor.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Sağ yanak (yuvarlak, pastel)
        Positioned(
          right: 15,
          top: 35,
          child: Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: skinColor.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Sol göz
        Positioned(
          left: 30,
          top: 25,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: eyeColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: eyeColor.withValues(alpha: 0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
        // Sağ göz
        Positioned(
          right: 30,
          top: 25,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: eyeColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: eyeColor.withValues(alpha: 0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
        // Gülümseme - Yuvarlak hatlı
        Positioned(
          bottom: 25,
          child: Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: eyeColor.withValues(alpha: 0.8),
                  width: 3,
                ),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
          ),
        ),
        // Şapka (varsa)
        if (provider.accessories.any((a) => a.type == 'hat'))
          Positioned(
            top: -15,
            child: Container(
              width: 75,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.hatColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.hatColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        // Gözlük (varsa)
        if (provider.accessories.any((a) => a.type == 'glasses'))
          Positioned(
            top: 20,
            child: Container(
              width: 65,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.glassesColor.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.glassesColor,
                  width: 2,
                ),
              ),
            ),
          ),
        // Atkı (varsa)
        if (provider.accessories.any((a) => a.type == 'scarf'))
          Positioned(
            bottom: -8,
            child: Container(
              width: 90,
              height: 15,
              decoration: BoxDecoration(
                color: AppColors.scarfColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.scarfColor.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Cilt rengini Color'a dönüştürme
  Color _getSkinColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'pink':
        return AppColors.pinkSkin;
      case 'blue':
        return AppColors.blueSkin;
      case 'yellow':
        return AppColors.yellowSkin;
      case 'green':
        return AppColors.greenSkin;
      default:
        return AppColors.pinkSkin;
    }
  }

  // Göz rengini Color'a dönüştürme
  Color _getEyeColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'black':
        return AppColors.blackEye;
      case 'brown':
        return AppColors.brownEye;
      case 'blue':
        return AppColors.blueEye;
      default:
        return AppColors.blackEye;
    }
  }

  // Su İç butonu widget'ı (sadece limit kontrolü ile)
  Widget _buildDrinkWaterButton(
    WaterProvider waterProvider,
    UserProvider userProvider,
    AchievementProvider achievementProvider,
  ) {
    final hasReachedLimit = waterProvider.hasReachedDailyLimit;
    
    String buttonText = 'Su İç (250ml)';
    bool isEnabled = !hasReachedLimit;
    
    if (hasReachedLimit) {
      buttonText = 'Günlük Limit Doldu (5 litre)';
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled
            ? () async {
                final result = await waterProvider.drinkWater();
                
                if (result.success) {
                  // Toplam su miktarını güncelle
                  await userProvider.addToTotalWater(250.0);
                  
                  bool achievementUnlocked = false;
                  bool dailyGoalReached = false;
                  String? achievementName;
                  int achievementCoins = 0;
                  
                  // Başarı kontrolü - İlk Adım
                  if (result.isFirstDrink) {
                    final coins = await achievementProvider.checkFirstStep();
                    if (coins > 0) {
                      achievementUnlocked = true;
                      achievementName = 'İlk Adım';
                      achievementCoins = coins;
                      await waterProvider.addCoins(coins);
                      await userProvider.addAchievement('first_step');
                    }
                  }
                  
                  // Başarı kontrolü - Günlük Hedef (ilk kez ulaşıldığında)
                  final wasGoalReachedBefore = achievementProvider.isAchievementUnlocked('daily_goal');
                  if (waterProvider.hasReachedDailyGoal && !wasGoalReachedBefore) {
                    final coins = await achievementProvider.checkDailyGoal();
                    if (coins > 0) {
                      dailyGoalReached = true;
                      achievementUnlocked = true;
                      achievementName = 'Günlük Hedef';
                      achievementCoins = coins;
                      await waterProvider.addCoins(coins);
                      await userProvider.addAchievement('daily_goal');
                      await userProvider.updateConsecutiveDays(true);
                    }
                  } else if (waterProvider.hasReachedDailyGoal) {
                    // Günlük hedefe tekrar ulaşıldı (zaten kazanılmış)
                    await userProvider.updateConsecutiveDays(true);
                  }
                  
                  // Başarı kontrolü - Su Ustası
                  final totalWater = userProvider.userData.totalWaterConsumed;
                  final wasWaterMasterUnlocked = achievementProvider.isAchievementUnlocked('water_master');
                  final waterMasterCoins = await achievementProvider.checkWaterMaster(totalWater);
                  if (waterMasterCoins > 0 && !wasWaterMasterUnlocked) {
                    achievementUnlocked = true;
                    achievementName = 'Su Ustası';
                    achievementCoins = waterMasterCoins;
                    await waterProvider.addCoins(waterMasterCoins);
                    await userProvider.addAchievement('water_master');
                  }
                  
                  // Başarı kontrolü - Seri Başlangıcı
                  final consecutiveDays = userProvider.consecutiveDays;
                  final wasStreak3Unlocked = achievementProvider.isAchievementUnlocked('streak_3');
                  final streak3Coins = await achievementProvider.checkStreak3(consecutiveDays);
                  if (streak3Coins > 0 && !wasStreak3Unlocked) {
                    achievementUnlocked = true;
                    achievementName = 'Seri Başlangıcı';
                    achievementCoins = streak3Coins;
                    await waterProvider.addCoins(streak3Coins);
                    await userProvider.addAchievement('streak_3');
                  }
                  
                  // Başarı kontrolü - Haftalık Şampiyon
                  final wasStreak7Unlocked = achievementProvider.isAchievementUnlocked('streak_7');
                  final streak7Coins = await achievementProvider.checkStreak7(consecutiveDays);
                  if (streak7Coins > 0 && !wasStreak7Unlocked) {
                    achievementUnlocked = true;
                    achievementName = 'Haftalık Şampiyon';
                    achievementCoins = streak7Coins;
                    await waterProvider.addCoins(streak7Coins);
                    await userProvider.addAchievement('streak_7');
                  }
                  
                  // Özel başarı ekranı sadece achievement kazanıldığında veya günlük hedefe ilk kez ulaşıldığında
                  if (mounted) {
                    if (achievementUnlocked || dailyGoalReached) {
                      // Büyük başarı ekranı göster
                      _showAchievementDialog(
                        context,
                        achievementName ?? 'Günlük Hedef',
                        achievementCoins,
                        dailyGoalReached,
                      );
                    } else {
                      // Normal su içiş - sadece küçük SnackBar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.monetization_on, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text('+${result.coinsReward} Coin! 💧'),
                            ],
                          ),
                          backgroundColor: AppColors.softPinkButton,
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                        ),
                      );
                    }
                  }
                } else {
                  // Hata durumu
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result.message),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? AppColors.softPinkButton
              : Colors.grey[400],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 60,
            vertical: 22,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
          ),
          elevation: 0,
        ),
        child: Text(
          buttonText,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  // Tank dekorasyonu çizimi
  Widget _buildTankDecoration(TankDecoration decoration, double tankWidth, double tankHeight) {
    final x = decoration.x * tankWidth;
    final y = decoration.y * tankHeight;

    Widget decorationWidget;
    
    switch (decoration.type) {
      case 'coral':
        // Mercan - Pembe, yuvarlak hatlı
        decorationWidget = Container(
          width: 40,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B9D).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B9D).withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Mercan dalları
              Positioned(
                left: 5,
                top: 10,
                child: Container(
                  width: 8,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8FAB).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Positioned(
                right: 5,
                top: 15,
                child: Container(
                  width: 8,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8FAB).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: 5,
                child: Container(
                  width: 8,
                  height: 15,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8FAB).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        );
        break;
      case 'starfish':
        // Deniz yıldızı - Sarı, yıldız şeklinde
        decorationWidget = Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD93D).withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD93D).withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _StarfishPainter(),
          ),
        );
        break;
      case 'bubbles':
        // Hava kabarcıkları - Mavi, yuvarlak, animasyonlu
        decorationWidget = Stack(
          children: [
            // Büyük kabarcık
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.waterColor.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
            ),
            // Orta kabarcık
            Positioned(
              left: 15,
              top: 5,
              child: Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: AppColors.waterColor.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            // Küçük kabarcık
            Positioned(
              left: 8,
              top: 20,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.waterColor.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
            ),
          ],
        );
        break;
      default:
        decorationWidget = const SizedBox.shrink();
    }

    return Positioned(
      left: x - (decoration.type == 'coral' ? 20 : decoration.type == 'starfish' ? 17.5 : 15),
      top: y - (decoration.type == 'coral' ? 25 : decoration.type == 'starfish' ? 17.5 : 15),
      child: decorationWidget,
    );
  }
}

// Deniz yıldızı çizim painter'ı
class _StarfishPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFE66D)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // 5 kollu yıldız çizimi
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * 3.14159 / 5) - (3.14159 / 2);
      final x = center.dx + radius * 0.8 * math.cos(angle);
      final y = center.dy + radius * 0.8 * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// Floating animasyonlu aksolot widget'ı
class _FloatingAxolotl extends StatefulWidget {
  final AxolotlProvider axolotlProvider;
  final double fillPercentage;
  final double tankHeight;
  final Widget Function(AxolotlProvider) buildAxolotl;

  const _FloatingAxolotl({
    required this.axolotlProvider,
    required this.fillPercentage,
    required this.tankHeight,
    required this.buildAxolotl,
  });

  @override
  State<_FloatingAxolotl> createState() => _FloatingAxolotlState();
}

class _FloatingAxolotlState extends State<_FloatingAxolotl>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Su seviyesine göre pozisyon ayarla (suyun üzerinde)
    final waterHeight = widget.tankHeight * widget.fillPercentage;
    // Maskotu su seviyesinin üzerine yerleştir
    // Eğer su seviyesi düşükse, maskotu tankın ortasına yakın yerleştir
    // Eğer su seviyesi yüksekse, maskotu su seviyesinin üzerine yerleştir
    final minPosition = widget.tankHeight * 0.2; // Minimum pozisyon (tankın %20'si yukarıda)
    final waterTopPosition = waterHeight; // Su seviyesinin üstü
    final targetPosition = waterTopPosition > minPosition 
        ? waterTopPosition - 60 // Su seviyesinin üzerinde 60px yukarıda
        : minPosition; // Minimum pozisyon
    
    // Tankın ortasından offset hesapla (Center widget'ı kullandığımız için)
    final baseOffset = targetPosition - (widget.tankHeight / 2);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, baseOffset + _animation.value),
          child: widget.buildAxolotl(widget.axolotlProvider),
        );
      },
    );
  }
}

// Başarı dialog'u - Sadece özel durumlarda gösterilir
extension _TankScreenDialogExtension on _TankScreenState {
  void _showAchievementDialog(
    BuildContext context,
    String achievementName,
    int coins,
    bool isDailyGoal,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.softPinkButton.withValues(alpha: 0.9),
                AppColors.waterColor.withValues(alpha: 0.9),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.celebration,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                isDailyGoal ? '🎉 Günlük Hedefe Ulaştın!' : '🎉 Başarı Kazandın!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                achievementName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '+$coins Coin',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.softPinkButton,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Harika!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
