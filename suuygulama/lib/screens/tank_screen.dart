import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../providers/water_provider.dart';
import '../providers/aquarium_provider.dart';
import '../providers/user_provider.dart';
import '../providers/achievement_provider.dart';
import '../models/decoration_item.dart';
import '../models/drink_model.dart';
import '../widgets/interactive_cup_modal.dart';
import 'drink_gallery_screen.dart';
import 'history_screen.dart';

class TankScreen extends StatefulWidget {
  const TankScreen({super.key});

  @override
  State<TankScreen> createState() => _TankScreenState();
}

class _TankScreenState extends State<TankScreen> with TickerProviderStateMixin {
  late AnimationController _coinAnimationController;
  late Animation<double> _coinScaleAnimation;
  late AnimationController _scrollIndicatorController;
  late Animation<double> _scrollIndicatorAnimation;
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  
  @override
  void initState() {
    super.initState();
    // Coin animasyonu için controller
    _coinAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _coinScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _coinAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    
    // Scroll göstergesi animasyonu
    _scrollIndicatorController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scrollIndicatorAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _scrollIndicatorController,
        curve: Curves.easeInOut,
      ),
    );
    _scrollIndicatorController.repeat(reverse: true);
    
    // Dalga animasyonu
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 2 * 3.14159).animate(
      CurvedAnimation(
        parent: _waveController,
        curve: Curves.linear,
      ),
    );
    _waveController.repeat();
  }
  
  @override
  void dispose() {
    _coinAnimationController.dispose();
    _scrollIndicatorController.dispose();
    _waveController.dispose();
    super.dispose();
  }
  
  void _animateCoin() {
    _coinAnimationController.forward().then((_) {
      _coinAnimationController.reverse();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.verySoftBlue,
      body: SafeArea(
        child: _buildTankView(),
      ),
    );
  }

  // Tank görünümü (Ana sayfa)
  Widget _buildTankView() {
    return Consumer4<WaterProvider, AquariumProvider, UserProvider, AchievementProvider>(
      builder: (context, waterProvider, aquariumProvider, userProvider, achievementProvider, child) {
        // Performans optimizasyonu: Hesaplamaları önceden yap
        final fillPercentage = waterProvider.tankFillPercentage;
        final consumedAmount = waterProvider.consumedAmount;
        final dailyGoal = waterProvider.dailyGoal;
        final progressPercentage = dailyGoal > 0 
            ? (consumedAmount / dailyGoal * 100).clamp(0.0, 100.0)
            : 0.0;
        
        // Dekorasyonları önceden hesapla (build içinde map kullanmamak için)
        final decorations = aquariumProvider.activeDecorationsList;
        
        return SingleChildScrollView(
          child: Column(
            children: [
              // Sağ Üst: Coin + Streak Butonu (Dikey)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Sağ Üst: Coin + Streak (Dikey)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Coin sayacı (animasyonlu)
                        ScaleTransition(
                          scale: _coinScaleAnimation,
                          child: Container(
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
                        ),
                        const SizedBox(height: 12),
                        // Streak Butonu (Sol üstten taşındı)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HistoryScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_fire_department,
                                  color: AppColors.softPinkButton,
                                  size: 22,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${userProvider.consecutiveDays}. Gün',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.softPinkButton,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Modern Başlık ve İlerleme - Ferah Düzen
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      '${consumedAmount.toStringAsFixed(0)} ml İçildi',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w300,
                        color: AppColors.softPinkButton,
                        letterSpacing: 0.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          'Hedef: ${(dailyGoal / 1000.0).toStringAsFixed(1)}L',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF4A5568).withValues(alpha: 0.7),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.softPinkButton,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.softPinkButton.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '%${progressPercentage.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Yuvarlak Fanus Tank Tasarımı
              Container(
                width: MediaQuery.of(context).size.width * 0.75,
                height: MediaQuery.of(context).size.width * 0.75, // Kare form (küre için)
                margin: const EdgeInsets.symmetric(vertical: 20),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Dış Çerçeve - Kalın Border ile Yuvarlak Fanus
                    Container(
                      width: MediaQuery.of(context).size.width * 0.75,
                      height: MediaQuery.of(context).size.width * 0.75,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.softPinkButton,
                          width: 6, // Kalın border
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.softPinkButton.withValues(alpha: 0.1),
                            const Color(0xFF9B7EDE).withValues(alpha: 0.1), // Mor
                            const Color(0xFF6B9BD1).withValues(alpha: 0.1), // Mavi
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.softPinkButton.withValues(alpha: 0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: const Color(0xFF9B7EDE).withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(-5, -5),
                          ),
                        ],
                      ),
                    ),
                    
                    // Su Seviyesi - ClipOval ile Taşma Önleme
                    ClipOval(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.75,
                        height: MediaQuery.of(context).size.width * 0.75,
                        child: Stack(
                          children: [
                            // Su doluluk animasyonu
                            if (fillPercentage > 0)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: AnimatedBuilder(
                                  animation: _waveAnimation,
                                  builder: (context, child) {
                                    final waterHeight = MediaQuery.of(context).size.width * 0.75 * fillPercentage;
                                    return Container(
                                      height: waterHeight,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            AppColors.waterColor.withValues(alpha: 0.9),
                                            const Color(0xFF6B9BD1).withValues(alpha: 0.8), // Mavi ton
                                            AppColors.softPinkButton.withValues(alpha: 0.6), // Pembe ton
                                          ],
                                        ),
                                      ),
                                      child: CustomPaint(
                                        size: Size(
                                          MediaQuery.of(context).size.width * 0.75,
                                          waterHeight,
                                        ),
                                        painter: CircularTankWavePainter(
                                          waveOffset: _waveAnimation.value,
                                          fillPercentage: fillPercentage,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Modüler dekorasyonlar - Yuvarlak tank için optimize edilmiş
                    ...decorations.map((decoration) {
                      return _buildCircularDecoration(
                        decoration,
                        MediaQuery.of(context).size.width * 0.75,
                      );
                    }),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Üçlü Yuvarlak Buton Sistemi - Standardize Edilmiş
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Sol Buton - Şeffaf (Yer Tutucu) - Aynı Boyutta
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.transparent,
                    ),
                    
                    // Orta Buton - Su Bardağı (Dinamik Metin ile)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Üstte küçük metin (sadece su eklendikten sonra)
                        FutureBuilder<Map<String, dynamic>>(
                          future: _getLastAddedAmountWithUnit(),
                          builder: (context, snapshot) {
                            final data = snapshot.data;
                            if (data != null) {
                              final amount = data['amount'];
                              final unit = data['unit'] as String;
                              final hasAmount = amount != null && (amount as num) > 0;
                              
                              if (hasAmount) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.softPinkButton.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '+${(amount as double).toStringAsFixed(unit == 'oz' ? 1 : 0)} $unit',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        const SizedBox(height: 8),
                        // Ana Buton - CircleAvatar ile Standardize
                        GestureDetector(
                          onTap: () => _showInteractiveCupModal(
                            context,
                            waterProvider,
                            userProvider,
                            achievementProvider,
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.softPinkButton,
                            child: const Icon(
                              Icons.local_drink,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Sağ Buton - Menü - CircleAvatar ile Standardize
                    GestureDetector(
                      onTap: () => _showDrinkSelector(context, waterProvider, userProvider, achievementProvider),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.grid_view,
                          color: AppColors.softPinkButton,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Günlük Mücadeleler Bölümü
              _buildDailyChallenges(
                waterProvider,
                userProvider,
                achievementProvider,
              ),
              
              const SizedBox(height: 30),
              
              // Hızlı Ekle Barı
              _buildQuickAddBar(waterProvider, userProvider, achievementProvider),
              
              const SizedBox(height: 20),
              
              // Scroll Göstergesi (Animasyonlu)
              _buildScrollIndicator(),
            ],
          ),
        );
      },
    );
  }

  // Yuvarlak tank için dekorasyon çizimi
  Widget _buildCircularDecoration(DecorationItem decoration, double tankDiameter) {
    // Yuvarlak tank için açı ve yarıçap hesaplama
    final angle = decoration.left * 2 * math.pi; // 0-1 arası değeri 0-2π'ye çevir
    final radius = (tankDiameter / 2) * (0.3 + decoration.bottom * 0.4); // Merkezden uzaklık
    final centerX = tankDiameter / 2;
    final centerY = tankDiameter / 2;
    
    final x = centerX + radius * math.cos(angle) - 25; // Merkezleme için -25
    final y = centerY + radius * math.sin(angle) - 25;

    // Basit dekorasyon widget'ı (icon tabanlı)
    Widget decorationWidget = Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _getDecorationColor(decoration.category).withValues(alpha: 0.6),
        shape: BoxShape.circle,
        border: Border.all(
          color: _getDecorationColor(decoration.category).withValues(alpha: 0.8),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        _getDecorationIcon(decoration.category),
        color: _getDecorationColor(decoration.category),
        size: 28,
      ),
    );

    return Positioned(
      left: x,
      top: y,
      child: decorationWidget,
    );
  }

  // Kategoriye göre renk
  Color _getDecorationColor(String category) {
    switch (category) {
      case 'Zemin/Kum':
        return const Color(0xFFD4A574); // Kum rengi
      case 'Arka Plan':
        return const Color(0xFF6B9BD1); // Mavi arka plan
      case 'Süs':
        return const Color(0xFFFF6B9D); // Pembe süs
      default:
        return AppColors.softPink;
    }
  }


  // Kategoriye göre icon
  IconData _getDecorationIcon(String category) {
    switch (category) {
      case 'Zemin/Kum':
        return Icons.landscape;
      case 'Arka Plan':
        return Icons.water;
      case 'Süs':
        return Icons.star;
      default:
        return Icons.auto_awesome;
    }
  }


  // Hızlı Ekle Barı
  Widget _buildQuickAddBar(
    WaterProvider waterProvider,
    UserProvider userProvider,
    AchievementProvider achievementProvider,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hızlı Ekle',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Su (250ml)
              _buildQuickAddButton(
                icon: Icons.water_drop,
                label: 'Su',
                amount: '250ml',
                color: const Color(0xFF4A9ED8),
                onTap: () => _quickAddDrink(
                  waterProvider,
                  userProvider,
                  achievementProvider,
                  DrinkData.getDrinks().firstWhere((d) => d.id == 'water'),
                  250.0,
                ),
              ),
              // Kahve (150ml)
              _buildQuickAddButton(
                icon: Icons.local_cafe,
                label: 'Kahve',
                amount: '150ml',
                color: const Color(0xFF8B4513),
                onTap: () => _quickAddDrink(
                  waterProvider,
                  userProvider,
                  achievementProvider,
                  DrinkData.getDrinks().firstWhere((d) => d.id == 'coffee'),
                  150.0,
                ),
              ),
              // Çay (100ml)
              _buildQuickAddButton(
                icon: Icons.emoji_food_beverage,
                label: 'Çay',
                amount: '100ml',
                color: const Color(0xFF6B8E23),
                onTap: () => _quickAddDrink(
                  waterProvider,
                  userProvider,
                  achievementProvider,
                  DrinkData.getDrinks().firstWhere((d) => d.id == 'tea'),
                  100.0,
                ),
              ),
              // Diğer İçecekler (+)
              _buildQuickAddButton(
                icon: Icons.add_circle_outline,
                label: 'Diğer',
                amount: '',
                color: AppColors.softPinkButton,
                onTap: () => _showDrinkSelector(context, waterProvider, userProvider, achievementProvider),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickAddButton({
    required IconData icon,
    required String label,
    required String amount,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (amount.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Future<void> _quickAddDrink(
    WaterProvider waterProvider,
    UserProvider userProvider,
    AchievementProvider achievementProvider,
    Drink drink,
    double amount,
  ) async {
    final result = await waterProvider.drink(drink, amount);
    
    if (result.success) {
      await userProvider.addToTotalWater(amount * drink.hydrationFactor);
      
      if (result.isFirstDrink) {
        final coins = await achievementProvider.checkFirstStep();
        if (coins > 0) {
          await waterProvider.addCoins(coins);
          await userProvider.addAchievement('first_step');
        }
      }
      
      final wasGoalReachedBefore = achievementProvider.isAchievementUnlocked('daily_goal');
      if (waterProvider.hasReachedDailyGoal && !wasGoalReachedBefore) {
        final coins = await achievementProvider.checkDailyGoal();
        if (coins > 0) {
          await waterProvider.addCoins(coins);
          await userProvider.addAchievement('daily_goal');
          await userProvider.updateConsecutiveDays(true);
        }
      } else if (waterProvider.hasReachedDailyGoal) {
        await userProvider.updateConsecutiveDays(true);
      }
      
      final totalWater = userProvider.userData.totalWaterConsumed;
      final wasWaterMasterUnlocked = achievementProvider.isAchievementUnlocked('water_master');
      final waterMasterCoins = await achievementProvider.checkWaterMaster(totalWater);
      if (waterMasterCoins > 0 && !wasWaterMasterUnlocked) {
        await waterProvider.addCoins(waterMasterCoins);
        await userProvider.addAchievement('water_master');
      }
      
      final consecutiveDays = userProvider.consecutiveDays;
      final wasStreak3Unlocked = achievementProvider.isAchievementUnlocked('streak_3');
      final streak3Coins = await achievementProvider.checkStreak3(consecutiveDays);
      if (streak3Coins > 0 && !wasStreak3Unlocked) {
        await waterProvider.addCoins(streak3Coins);
        await userProvider.addAchievement('streak_3');
      }
      
      final wasStreak7Unlocked = achievementProvider.isAchievementUnlocked('streak_7');
      final streak7Coins = await achievementProvider.checkStreak7(consecutiveDays);
      if (streak7Coins > 0 && !wasStreak7Unlocked) {
        await waterProvider.addCoins(streak7Coins);
        await userProvider.addAchievement('streak_7');
      }
      
      if (mounted) {
        _animateCoin();
      }
    }
  }

  // İçecek galerisi ekranına yönlendir
  void _showDrinkSelector(
    BuildContext context,
    WaterProvider waterProvider,
    UserProvider userProvider,
    AchievementProvider achievementProvider,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DrinkGalleryScreen(),
      ),
    );
  }
  
  // Son eklenen miktarı ve birimi al
  Future<Map<String, dynamic>> _getLastAddedAmountWithUnit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final amount = prefs.getDouble('last_added_amount');
      final unit = prefs.getString('preferred_unit') ?? 'ml';
      
      if (amount != null && amount > 0) {
        // Birime göre dönüştür
        double displayAmount = amount;
        if (unit == 'oz') {
          displayAmount = amount / 29.5735;
        }
        return {'amount': displayAmount, 'unit': unit};
      }
      return {'amount': null, 'unit': unit};
    } catch (e) {
      return {'amount': null, 'unit': 'ml'};
    }
  }

  // İnteraktif Bardak Modal'ını göster
  void _showInteractiveCupModal(
    BuildContext context,
    WaterProvider waterProvider,
    UserProvider userProvider,
    AchievementProvider achievementProvider,
  ) async {
    final result = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      isScrollControlled: true,
      builder: (context) => const InteractiveCupModal(),
    );
    
    // Modal'dan döndükten sonra son eklenen miktarı kaydet
    if (result != null && result is double) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_added_amount', result);
      if (mounted) {
        setState(() {}); // Buton metnini güncelle
      }
    }
  }

  // Günlük Mücadeleler Bölümü
  Widget _buildDailyChallenges(
    WaterProvider waterProvider,
    UserProvider userProvider,
    AchievementProvider achievementProvider,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
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
            'Günlük Mücadeleler',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 20),
          
          // Mücadele 1: 3 Gün Üst Üste Hedef
          _buildChallengeCard(
            title: '3 Gün Üst Üste Hedef',
            description: 'Günlük su hedefine 3 gün üst üste ulaş',
            coinReward: 50,
            isCompleted: userProvider.consecutiveDays >= 3,
            progress: (userProvider.consecutiveDays / 3).clamp(0.0, 1.0),
            progressText: '${userProvider.consecutiveDays}/3 gün',
          ),
          
          const SizedBox(height: 16),
          
          // Mücadele 2: Bugün 2 Litre Su
          _buildChallengeCard(
            title: 'Bugün 2 Litre Su',
            description: 'Bugün en az 2 litre su iç',
            coinReward: 20,
            isCompleted: waterProvider.consumedAmount >= 2000.0,
            progress: (waterProvider.consumedAmount / 2000.0).clamp(0.0, 1.0),
            progressText: '${(waterProvider.consumedAmount / 1000.0).toStringAsFixed(1)}/2.0L',
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard({
    required String title,
    required String description,
    required int coinReward,
    required bool isCompleted,
    required double progress,
    required String progressText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.softPinkButton.withValues(alpha: 0.1)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? AppColors.softPinkButton
              : Colors.grey[300]!,
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isCompleted
                            ? AppColors.softPinkButton
                            : const Color(0xFF4A5568),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.goldCoin.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Color(0xFFD4AF37),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+$coinReward',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Progress Bar
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.softPinkButton
                        : AppColors.softPinkButton.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                progressText,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (isCompleted)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.softPinkButton,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tamamlandı',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.softPinkButton,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Animasyonlu Scroll Göstergesi
  Widget _buildScrollIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: AnimatedBuilder(
        animation: _scrollIndicatorAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _scrollIndicatorAnimation.value),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey[400],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Mücadeleler için kaydır',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Tank dalga animasyonu için CustomPainter (Eski - Dikdörtgen tank için)
class TankWavePainter extends CustomPainter {
  final double waveOffset;
  final double fillPercentage;

  TankWavePainter({
    required this.waveOffset,
    required this.fillPercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPercentage <= 0) return;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Yumuşak dalga çizgisi (üst kısım)
    final path = Path();
    final waveHeight = 8.0;

    path.moveTo(0, size.height - 10);

    for (double x = 0; x <= size.width; x += 2) {
      final y = size.height - 10 +
          waveHeight * math.sin(x / size.width * 2 * math.pi + waveOffset);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(TankWavePainter oldDelegate) {
    return oldDelegate.waveOffset != waveOffset ||
        oldDelegate.fillPercentage != fillPercentage;
  }
}

// Yuvarlak tank dalga animasyonu için CustomPainter
class CircularTankWavePainter extends CustomPainter {
  final double waveOffset;
  final double fillPercentage;

  CircularTankWavePainter({
    required this.waveOffset,
    required this.fillPercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPercentage <= 0) return;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Yuvarlak tank için yumuşak dalga çizgisi (üst kısım)
    final path = Path();
    final waveHeight = 6.0;
    final centerX = size.width / 2;
    final radius = size.width / 2;

    // Yuvarlak formda dalga çizgisi
    path.moveTo(0, size.height - 10);

    for (double x = 0; x <= size.width; x += 1.5) {
      // Yuvarlak form için y koordinatını hesapla
      final normalizedX = (x - centerX) / radius;
      if (normalizedX.abs() <= 1.0) {
        final y = size.height - 10 +
            waveHeight * math.sin(x / size.width * 2 * math.pi + waveOffset);
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CircularTankWavePainter oldDelegate) {
    return oldDelegate.waveOffset != waveOffset ||
        oldDelegate.fillPercentage != fillPercentage;
  }
}
