import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../providers/water_provider.dart';
import '../providers/aquarium_provider.dart';
import '../providers/user_provider.dart';
import '../providers/achievement_provider.dart';
import '../models/decoration_item.dart';
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
  late AnimationController _tipAnimationController;
  String _currentTip = '';
  
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
    
    // Günün Tavsiyesi animasyonu
    _tipAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // İlk tavsiyeyi göster
    _showRandomTip();
    _tipAnimationController.forward();
    
    // Her 30 saniyede bir yeni tavsiye göster
    _tipAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _tipAnimationController.reset();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _showRandomTip();
            _tipAnimationController.forward();
          }
        });
      }
    });
  }
  
  @override
  void dispose() {
    _coinAnimationController.dispose();
    _tipAnimationController.dispose();
    super.dispose();
  }
  
  void _showRandomTip() {
    final waterProvider = Provider.of<WaterProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userName = userProvider.userData.name;
    
    setState(() {
      _currentTip = waterProvider.getRandomMessage(userName);
    });
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
        final fillPercentage = waterProvider.tankFillPercentage;
        
        final consumedAmount = waterProvider.consumedAmount;
        final dailyGoal = waterProvider.dailyGoal;
        final progressPercentage = (consumedAmount / dailyGoal * 100).clamp(0.0, 100.0);
        
        return SingleChildScrollView(
          child: Column(
            children: [
              // Sol Üst Seri Butonu ve Sağ Üst Coin
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Seri Butonu
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
                              size: 24,
                            ),
                            Text(
                              '${userProvider.consecutiveDays}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.softPinkButton,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Coin sayacı - Sağda (animasyonlu)
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
                  ],
                ),
              ),
              
              // Başlık ve İlerleme
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${consumedAmount.toStringAsFixed(0)} ml İçildi',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w300,
                        color: Color(0xFF4A5568),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Hedef: ${(dailyGoal / 1000.0).toStringAsFixed(1)}L',
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color(0xFF4A5568).withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.softPinkButton.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '%${progressPercentage.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.softPinkButton,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Tank Container - Merkezde
              Container(
                width: MediaQuery.of(context).size.width * 0.85,
                height: MediaQuery.of(context).size.height * 0.5,
                margin: const EdgeInsets.symmetric(vertical: 20),
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
                    // Su seviyesi (doluluk)
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
                    
                    // Modüler dekorasyonlar - Katmanlı yapı
                    ...aquariumProvider.activeDecorationsList.map((decoration) {
                      return _buildDecoration(
                        decoration,
                        MediaQuery.of(context).size.width * 0.85,
                        MediaQuery.of(context).size.height * 0.5,
                      );
                    }),
                  ],
                ),
              ),
              
              // Su İç Butonu ve İçecek Seçici
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  children: [
                    // İçecek seçici butonu (+)
                    GestureDetector(
                      onTap: () => _showDrinkSelector(context, waterProvider, userProvider, achievementProvider),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.softPinkButton.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.softPinkButton,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.add,
                          color: AppColors.softPinkButton,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Ana su iç butonu
                    Expanded(
                      child: GestureDetector(
                        onLongPress: () => _showDrinkSelector(context, waterProvider, userProvider, achievementProvider),
                        child: _buildDrinkWaterButton(
                          waterProvider,
                          userProvider,
                          achievementProvider,
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
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Günün Tavsiyesi Şeridi
  Widget _buildTipBanner() {
    return FadeTransition(
      opacity: _tipAnimationController,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: Colors.white.withValues(alpha: 0.9),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _currentTip.isEmpty ? 'Günün Tavsiyesi' : _currentTip,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dekorasyon çizimi
  Widget _buildDecoration(DecorationItem decoration, double tankWidth, double tankHeight) {
    final x = decoration.left * tankWidth;
    final y = (1.0 - decoration.bottom) * tankHeight; // bottom 0.0 = alt, 1.0 = üst

    // Basit dekorasyon widget'ı (icon tabanlı)
    Widget decorationWidget = Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _getDecorationColor(decoration.category).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: _getDecorationColor(decoration.category).withValues(alpha: 0.8),
          width: 2,
        ),
      ),
      child: Icon(
        _getDecorationIcon(decoration.category),
        color: _getDecorationColor(decoration.category),
        size: 28,
      ),
    );

    return Positioned(
      left: x - 25, // Merkezleme için
      top: y - 25,
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

  // Su İç butonu widget'ı
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
                  await userProvider.addToTotalWater(250.0);
                  
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
}
