import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';
import '../utils/app_colors.dart';
import '../providers/water_provider.dart';
import '../providers/aquarium_provider.dart';
import '../providers/user_provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/challenge_provider.dart';
import '../models/achievement_model.dart';
import '../widgets/interactive_cup_modal.dart';
import '../widgets/challenge_card.dart';
import '../widgets/glass_fish_bowl.dart';
import '../providers/drink_provider.dart';
import '../utils/unit_converter.dart';
import 'drink_gallery_screen.dart';
import 'success_screen.dart';
import 'dart:async';

class TankScreen extends StatefulWidget {
  const TankScreen({super.key});

  @override
  State<TankScreen> createState() => _TankScreenState();
}

class _TankScreenState extends State<TankScreen> with TickerProviderStateMixin {
  late AnimationController _coinAnimationController;
  late Animation<double> _coinScaleAnimation;
  late AnimationController _waveController;
  late AnimationController _fillController; // Su dolum animasyonu için
  late Animation<double> _fillAnimation;
  late AnimationController _bubbleController; // Bubble animasyonu için
  late DraggableScrollableController _challengeSheetController;
  double _animatedFillPercentage = 0.0; // Animasyonlu doluluk yüzdesi
  final List<_Bubble> _bubbles = []; // Bubble listesi
  
  // WaveWidget konfigürasyonu - Ferah mavi renkler (kullanıcı isteği)
  
  @override
  void initState() {
    super.initState();
    // DraggableScrollableController'ı initState içinde oluştur
    _challengeSheetController = DraggableScrollableController();
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
    
    // Dalga animasyonu (WaveWidget için)
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    // Su dolum animasyonu (kademeli dolum için)
    _fillController = AnimationController(
      duration: const Duration(milliseconds: 800), // 800ms'de dolum
      vsync: this,
    );
    _fillAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fillController,
        curve: Curves.easeOut,
      ),
    );
    
    // Bubble animasyonu
    _bubbleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    // Bubble'ları oluştur
    _generateBubbles();
  }
  
  // Bubble'ları oluştur
  void _generateBubbles() {
    _bubbles.clear();
    final random = math.Random();
    for (int i = 0; i < 8; i++) {
      _bubbles.add(_Bubble(
        startX: random.nextDouble() * 0.8 + 0.1, // 0.1 - 0.9 arası
        size: random.nextDouble() * 8 + 4, // 4-12 arası boyut
        speed: random.nextDouble() * 0.3 + 0.1, // 0.1 - 0.4 arası hız
        delay: random.nextDouble() * 2, // 0-2 saniye gecikme
      ));
    }
  }
  
  @override
  void dispose() {
    _coinAnimationController.dispose();
    _waveController.dispose();
    _fillController.dispose();
    _bubbleController.dispose();
    _challengeSheetController.dispose();
    super.dispose();
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF87CEEB), // Üst: Açık Gök Mavisi (Sky Blue)
              Color(0xFFB0E0E6), // Orta: Açık Mavi (Powder Blue)
              Color(0xFFE0F6FF), // Alt: Çok Açık Mavi (Ice Blue)
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: _buildTankView(),
        ),
      ),
    );
  }

  // Tank görünümü (Ana sayfa)
  Widget _buildTankView() {
    return Consumer4<WaterProvider, AquariumProvider, UserProvider, AchievementProvider>(
      builder: (context, waterProvider, aquariumProvider, userProvider, achievementProvider, child) {
        // Performans optimizasyonu: Hesaplamaları önceden yap
        // UserProvider verilerinden doğrudan hesapla
        final currentIntake = waterProvider.consumedAmount;
        final dailyGoal = waterProvider.dailyGoal;
        // fillPercentage'ı 1.0 ile sınırla (görsel animasyon için %100'ü geçmemeli)
        // NOT: Sadece görsel animasyon için sınırlandırıyoruz, metin gösterimleri olduğu gibi kalacak
        final fillPercentage = (dailyGoal > 0) 
            ? (currentIntake / dailyGoal).clamp(0.0, 1.0) 
            : 0.0;
        // progressPercentage'ı clamp'lamıyoruz - %172 gibi değerler gösterilebilir
        final progressPercentage = dailyGoal > 0 
            ? (currentIntake / dailyGoal * 100)
            : 0.0;
        
        // Animasyonlu dolum: fillPercentage değiştiğinde animasyonu başlat
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          
          final currentAnimatedFill = _animatedFillPercentage.clamp(0.0, 1.0);
          final targetFill = fillPercentage.clamp(0.0, 1.0);
          
          if ((targetFill - currentAnimatedFill).abs() > 0.01) {
            // Hedef doluluk yüzdesine animasyonlu olarak yaklaş
            _fillController.reset();
            _fillAnimation = Tween<double>(
              begin: currentAnimatedFill,
              end: targetFill,
            ).animate(
              CurvedAnimation(
                parent: _fillController,
                curve: Curves.easeOut,
              ),
            )..addListener(() {
              if (mounted) {
                final newValue = _fillAnimation.value.clamp(0.0, 1.0);
                if ((newValue - _animatedFillPercentage).abs() > 0.001) {
                  _animatedFillPercentage = newValue;
                  setState(() {});
                }
              }
            });
            _fillController.forward();
          } else if (currentAnimatedFill == 0.0 && targetFill > 0.0) {
            // İlk render'da direkt atama (animasyonsuz)
            _animatedFillPercentage = targetFill;
            if (mounted) {
              setState(() {});
            }
          }
        });
        
        return Stack(
          children: [
            // Ana içerik - ScrollView
            SingleChildScrollView(
              child: Column(
              children: [
              // Üst Bar: Sol - Günlük Seri Butonu, Sağ - Coin Butonu (spaceBetween ile hizalı - jilet gibi)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Sol: Günlük Seri/Challenge Butonu (Akıllı ve Hareketli)
                    _StatusToggleButton(
                      challengeProvider: Provider.of<ChallengeProvider>(context, listen: false),
                      userProvider: userProvider,
                      progressPercentage: progressPercentage,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SuccessScreen(),
                          ),
                        );
                        
                        if (!mounted) return;
                        
                        // Eğer 'open_challenges_panel' döndüyse, mücadele panelini aç
                        if (result == 'open_challenges_panel') {
                          _challengeSheetController.animateTo(
                            0.85,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                    ),
                    
                    // Sağ: Dairesel Coin Butonu
                    ScaleTransition(
                      scale: _coinScaleAnimation,
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
                              Icons.monetization_on,
                              color: AppColors.goldCoin,
                              size: 24,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${waterProvider.tankCoins}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.goldCoin,
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
              
              const SizedBox(height: 20),
              
              // Cam Fanus Tank Tasarımı - GlassFishBowl ile
              Center(
                child: GlassFishBowl(
                  size: 300.0,
                  child: RepaintBoundary(
                    child: SizedBox(
                      width: 300.0,
                      height: 300.0,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        clipBehavior: Clip.antiAlias,
                        children: [
                          // Arka plan (şeffaf - su görünür olmalı)
                          Container(
                            width: 300.0,
                            height: 300.0,
                            color: Colors.transparent,
                          ),
                          // Su doluluk animasyonu
                          AnimatedBuilder(
                            animation: Listenable.merge([_fillAnimation, _bubbleController, _waveController]),
                            builder: (context, child) {
                              final tankSize = 300.0;
                              final currentFill = fillPercentage.clamp(0.0, 1.0);
                              final waterHeight = tankSize * currentFill;
                              final waterTop = tankSize - waterHeight;
                              
                              return SizedBox(
                                width: tankSize,
                                height: tankSize,
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  clipBehavior: Clip.antiAlias,
                                  children: [
                                    // Ana su katmanı
                                    if (waterHeight > 0)
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        height: waterHeight,
                                        child: Container(
                                          color: const Color(0xFF4FC3F7), // Ferah mavi
                                        ),
                                      ),
                                    
                                    // Wave efekti
                                    if (currentFill > 0.05 && waterHeight > 15)
                                      Positioned(
                                        bottom: waterHeight - 20,
                                        left: 0,
                                        right: 0,
                                        height: 40,
                                        child: ClipRect(
                                          child: ClipOval(
                                            child: WaveWidget(
                                              config: CustomConfig(
                                                gradients: [
                                                  [
                                                    const Color(0xFF4FC3F7).withValues(alpha: 0.7),
                                                    const Color(0xFF0288D1).withValues(alpha: 0.5),
                                                  ],
                                                  [
                                                    const Color(0xFF4FC3F7).withValues(alpha: 0.6),
                                                    const Color(0xFF0288D1).withValues(alpha: 0.4),
                                                  ],
                                                ],
                                                durations: const [4000, 5000],
                                                heightPercentages: const [0.20, 0.25],
                                              ),
                                              waveAmplitude: 5.0,
                                              waveFrequency: 1.5,
                                              backgroundColor: Colors.transparent,
                                              size: Size(tankSize, 40),
                                            ),
                                          ),
                                        ),
                                      ),
                                    
                                    // Yükselen kabarcıklar
                                    if (waterHeight > 0)
                                      ..._bubbles.map((bubble) {
                                        final bubbleProgress = ((_bubbleController.value * 2 + bubble.delay) % 2) / 2;
                                        final bubbleY = tankSize - (bubbleProgress * waterHeight * 0.8);
                                        
                                        if (bubbleY > waterTop && bubbleY < tankSize && waterHeight > 10) {
                                          final bubbleX = bubble.startX * tankSize;
                                          return Positioned(
                                            left: bubbleX - bubble.size / 2,
                                            bottom: tankSize - bubbleY - bubble.size / 2,
                                            child: Opacity(
                                              opacity: math.max(0, 1 - bubbleProgress * 1.5),
                                              child: Container(
                                                width: bubble.size,
                                                height: bubble.size,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white.withValues(alpha: 0.3),
                                                  border: Border.all(
                                                    color: Colors.white.withValues(alpha: 0.5),
                                                    width: 1,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      }),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Tank Altı: Günlük Hedef (Basit Tasarım)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Center(
                  child: Text(
                    'Günlük Hedef: ${UnitConverter.formatVolume(dailyGoal, userProvider.isMetric)}',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w500, // Medium
                      color: Colors.black45, // Soft gri / Füme
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
            ],
          ),
        ),
            // Buton Paneli - Günlük Hedef'in altında, Mücadele panelinin üstünde
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.22,
              left: 0,
              right: 0,
              child: Consumer4<DrinkProvider, WaterProvider, UserProvider, AchievementProvider>(
                builder: (context, drinkProvider, waterProvider, userProvider, achievementProvider, child) {
                  // Ana Üçlü Grup Widget'ı (Merkezde) - Menü (Sol) | Su (Merkez, Mavi, Büyük) | İçecek Ekle (Sağ)
                  return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
                      // En Sol: Menü Butonu (Kare/Izgara ikonu)
                      GestureDetector(
                        onTap: () {
                          if (!mounted) return;
                          _showDrinkSelector(context, waterProvider, userProvider, achievementProvider);
                        },
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.grid_view,
                            color: AppColors.softPinkButton,
                            size: 30,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 24), // Boşluğu artırdık
                      
                      // Merkez: Su İçme Butonu (Bardak ikonu, Mavi, En Büyük)
                      GestureDetector(
                        onTap: () {
                          if (!mounted) return;
                          _showInteractiveCupModal(
                            context,
                            waterProvider,
                            userProvider,
                            achievementProvider,
                          );
                        },
                        child: CircleAvatar(
                          radius: 36, // En büyük buton (diğerleri 30)
                          backgroundColor: AppColors.waterColor, // Mavi renk
                          child: const Icon(
                            Icons.local_drink,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 24), // Boşluğu artırdık
                      
                      // Sağ: İçecek Ekleme Butonu (Artılı Bardak ikonu)
                      GestureDetector(
                        onTap: () {
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DrinkGalleryScreen(),
                            ),
                          );
                        },
          child: Stack(
            alignment: Alignment.center,
            children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AppColors.softPinkButton,
                              child: const Icon(
                                Icons.local_drink,
                                color: Colors.white,
                                size: 24,
                              ),
              ),
                            // Sağ üst köşede küçük + işareti
              Positioned(
                              top: 2,
                              right: 2,
                child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                      ),
                                child: const Icon(
                                  Icons.add,
                                  color: AppColors.softPinkButton,
                                  size: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
                    ],
                  );
                },
              ),
            ),
            // DraggableScrollableSheet - Mücadele Kartları (Peek Height) - EN ALTA
            DraggableScrollableSheet(
              controller: _challengeSheetController,
              initialChildSize: 0.12, // Başlığın ve kartların üstünün görüneceği seviye (peek height)
              minChildSize: 0.12,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return Container(
            decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
          ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Tutma çizgisi
        Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
          decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
          ),
                      ),
                      // Scrollable içerik
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Builder(
                            builder: (context) {
                              final waterProvider = Provider.of<WaterProvider>(context, listen: false);
                              final userProvider = Provider.of<UserProvider>(context, listen: false);
                              final achievementProvider = Provider.of<AchievementProvider>(context, listen: false);
                              return _buildDailyChallengesContent(
                                waterProvider,
                                userProvider,
                                achievementProvider,
                              );
                            },
            ),
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


  // İnteraktif Bardak Modal'ını göster
  void _showInteractiveCupModal(
    BuildContext context,
    WaterProvider waterProvider,
    UserProvider userProvider,
    AchievementProvider achievementProvider,
  ) async {
    // İlk su içiş kontrolü için önceki değeri kaydet
    final previousConsumedAmount = waterProvider.consumedAmount;
    
    final result = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      isScrollControlled: true,
      builder: (context) => const InteractiveCupModal(),
    );
    
    // Modal'dan döndükten sonra (artık buton üstünde etiket gösterilmediği için kaydetme gerekmiyor)
    if (result != null && result is double) {
      // İlk Bardak başarısı kontrolü
      final currentConsumedAmount = waterProvider.consumedAmount;
      
      // Eğer önceki değer 0 idi ve şimdi > 0 ise, ilk su içildi
      if (previousConsumedAmount == 0.0 && currentConsumedAmount > 0.0) {
        if (!context.mounted) return;
        final achievementProvider = Provider.of<AchievementProvider>(context, listen: false);
        final isAlreadyUnlocked = achievementProvider.isAchievementUnlocked('first_cup');
        
        if (!isAlreadyUnlocked) {
          // Başarıyı aç ve coin ödülünü al
          final coinReward = await achievementProvider.checkFirstCup();
          
          // Coin ödülünü ekle
          if (coinReward > 0) {
            await waterProvider.addCoins(coinReward);
            // Await sonrası mounted kontrolü
            if (!mounted) return;
          }
          
          // Context kontrolü - mounted kontrolünden sonra context kullan
          if (!mounted) return;
          
          // Context'i post-frame callback ile kullan (güvenli context kullanımı)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showAchievementDialog(context, 'first_cup');
            }
          });
        }
      }
    }
  }

  // Başarı kazanıldığında gösterilecek kutlama dialogu
  void _showAchievementDialog(BuildContext context, String achievementId) {
    final achievementProvider = Provider.of<AchievementProvider>(context, listen: false);
    final achievement = achievementProvider.achievements.firstWhere(
      (a) => a.id == achievementId,
      orElse: () => Achievement(
        id: achievementId,
        name: 'İlk Bardak',
        description: 'Uygulamadaki ilk suyunu iç ve macerayı başlat!',
        coinReward: 20,
      ),
    );
    
    // İlk Bardak için özel renk ve emoji
    final cardColor = const Color(0xFF00BCD4); // Açık Mavi/Cyan
    final badgeEmoji = '💧';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
      decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cardColor,
                cardColor.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 3,
            ),
        boxShadow: [
          BoxShadow(
                color: Colors.cyan.withValues(alpha: 0.6),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 0),
              ),
              BoxShadow(
                color: cardColor.withValues(alpha: 0.4),
                blurRadius: 25,
                offset: const Offset(0, 10),
          ),
        ],
      ),
          child: Padding(
            padding: const EdgeInsets.all(30),
      child: Column(
              mainAxisSize: MainAxisSize.min,
        children: [
                // Rozet emoji (büyük)
                Text(
                  badgeEmoji,
                  style: const TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 20),
                
                // Başlık
          const Text(
                  'Yeni Bir Başarı Kazandın!',
            style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Başarı adı
                Text(
                  achievement.name,
                  style: const TextStyle(
                    fontSize: 22,
              fontWeight: FontWeight.w600,
                    color: Colors.white,
            ),
                  textAlign: TextAlign.center,
          ),
                const SizedBox(height: 8),
                
                // Ödül bilgisi
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Colors.amber,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${achievement.coinReward} Coin Kazandınız!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
                // Tamam butonu
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // setState kaldırıldı - Consumer widget'ı zaten otomatik güncellenecek
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: cardColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 8,
                  ),
                  child: const Text(
                    'Harika!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
            ),
          ),
        ),
      ),
    );
  }

  // Mücadele Kartları İçeriği (DraggableScrollableSheet için)
  Widget _buildDailyChallengesContent(
    WaterProvider waterProvider,
    UserProvider userProvider,
    AchievementProvider achievementProvider,
  ) {
    // 1. Tüm mücadeleleri al ve durumlarını hesapla
    final allChallenges = ChallengeData.getChallenges()
        .where((challenge) => challenge.id != 'first_cup')
        .map((challenge) {
      Challenge updatedChallenge = challenge;
      
      if (challenge.id == 'deep_dive') {
        // Derin Dalış: 3 gün üst üste %100 su hedefi
        final isCompleted = userProvider.consecutiveDays >= 3 && 
                            waterProvider.hasReachedDailyGoal;
        updatedChallenge = Challenge(
          id: challenge.id,
          name: challenge.name,
          description: challenge.description,
          coinReward: challenge.coinReward,
          cardColor: challenge.cardColor,
          icon: challenge.icon,
          whyStart: challenge.whyStart,
          healthBenefit: challenge.healthBenefit,
          badgeEmoji: challenge.badgeEmoji,
          isCompleted: isCompleted,
          progress: (userProvider.consecutiveDays / 3).clamp(0.0, 1.0),
          progressText: '${userProvider.consecutiveDays}/3 gün',
        );
      } else if (challenge.id == 'coral_guardian') {
        // Mercan Koruyucu: Akşam 8'den sonra sadece su (basitleştirilmiş - bugün su hedefi)
        final isCompleted = waterProvider.hasReachedDailyGoal;
        updatedChallenge = Challenge(
          id: challenge.id,
          name: challenge.name,
          description: challenge.description,
          coinReward: challenge.coinReward,
          cardColor: challenge.cardColor,
          icon: challenge.icon,
          whyStart: challenge.whyStart,
          healthBenefit: challenge.healthBenefit,
          badgeEmoji: challenge.badgeEmoji,
          isCompleted: isCompleted,
          progress: (waterProvider.consumedAmount / waterProvider.dailyGoal).clamp(0.0, 1.0),
          progressText: '${UnitConverter.formatVolume(waterProvider.consumedAmount, userProvider.isMetric)}/${UnitConverter.formatVolume(waterProvider.dailyGoal, userProvider.isMetric)}',
        );
      }
      
      return updatedChallenge;
    }).toList();
    
    // 2. Aktif ve tamamlanan mücadeleleri ayrı ayrı filtrele
    final activeChallenges = allChallenges.where((c) => !c.isCompleted).toList();
    final completedChallenges = allChallenges.where((c) => c.isCompleted).toList();
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 24),
            child: Text(
              'Mücadele Kartları',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A5568),
              ),
            ),
          ),
          
          // Aktif Görevler Başlığı (Varsa)
          if (activeChallenges.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Aktif Görevler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A5568),
                ),
              ),
            ),
            // Aktif Liste: Tamamlanmamışları buraya diz
            ...activeChallenges.map((challenge) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ChallengeCard(
                challenge: challenge,
              ),
            )),
          ],
          
          // Ayırıcı (Eğer hem aktif hem tamamlanan varsa)
          if (activeChallenges.isNotEmpty && completedChallenges.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(color: Colors.grey),
            const SizedBox(height: 20),
          ],
          
          // Tamamlananlar Başlığı
          if (completedChallenges.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Tamamlananlar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ),
            // Tamamlanan Liste: Tamamlanmışları buraya diz (Opacity 0.5 ile)
            ...completedChallenges.map((challenge) => Opacity(
              opacity: 0.5,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ChallengeCard(
                  challenge: challenge,
                ),
              ),
            )),
          ],
          
          const SizedBox(height: 20),
        ],
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

// Bubble veri modeli (plan_loading_screen.dart'daki gibi)
class _Bubble {
  final double startX; // 0.0 - 1.0 arası (tank genişliğine göre)
  final double size; // Kabarcık boyutu
  final double speed; // Yükselme hızı
  final double delay; // Başlangıç gecikmesi

  _Bubble({
    required this.startX,
    required this.size,
    required this.speed,
    required this.delay,
  });
}

// Akıllı ve Hareketli Durum Butonu
class _StatusToggleButton extends StatefulWidget {
  final ChallengeProvider challengeProvider;
  final UserProvider userProvider;
  final double progressPercentage;
  final VoidCallback onTap;

  const _StatusToggleButton({
    required this.challengeProvider,
    required this.userProvider,
    required this.progressPercentage,
    required this.onTap,
  });

  @override
  State<_StatusToggleButton> createState() => _StatusToggleButtonState();
}

class _StatusToggleButtonState extends State<_StatusToggleButton> {
  Timer? _toggleTimer;
  bool _showChallenge = false; // false = Streak, true = Challenge
  Challenge? _firstActiveChallenge;

  @override
  void initState() {
    super.initState();
    _checkActiveChallenge();
    
    // Eğer aktif mücadele varsa, 3.5 saniyede bir geçiş yap
    if (_firstActiveChallenge != null) {
      _toggleTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
        if (mounted) {
          setState(() {
            _showChallenge = !_showChallenge;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _toggleTimer?.cancel();
    super.dispose();
  }

  void _checkActiveChallenge() {
    final activeChallenges = widget.challengeProvider.activeIncompleteChallenges;
    final hasActiveChallenge = activeChallenges.isNotEmpty;
    
    if (hasActiveChallenge) {
      _firstActiveChallenge = activeChallenges.first;
      // Timer'ı başlat (eğer henüz başlatılmadıysa)
      if (_toggleTimer == null || !_toggleTimer!.isActive) {
        _toggleTimer?.cancel();
        _toggleTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
          if (mounted) {
            setState(() {
              _showChallenge = !_showChallenge;
            });
          }
        });
      }
    } else {
      _firstActiveChallenge = null;
      // Timer'ı durdur (mücadele yoksa)
      _toggleTimer?.cancel();
      _toggleTimer = null;
      if (mounted && _showChallenge) {
        setState(() {
          _showChallenge = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Aktif mücadele durumunu tekrar kontrol et (provider güncellenmiş olabilir)
    _checkActiveChallenge();
    final hasActiveChallenge = _firstActiveChallenge != null;

    // Aktif mücadele yoksa, sadece Streak göster (sabit)
    if (!hasActiveChallenge) {
      return GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Progress Ring (Günlük hedef) - Pembe/Kırmızı tonlarında
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: widget.progressPercentage / 100,
                  strokeWidth: 4,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.softPinkButton,
                  ),
                ),
              ),
              // İçerideki Dairesel Buton (Streak)
              Container(
                width: 50,
                height: 50,
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: AppColors.softPinkButton,
                      size: 20,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.userProvider.consecutiveDays}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.softPinkButton,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Aktif mücadele varsa, iki görünüm arasında geçiş yap
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Progress Ring (Mücadele ilerlemesi veya Streak)
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: _showChallenge && _firstActiveChallenge != null
                    ? _firstActiveChallenge!.progress.clamp(0.0, 1.0)
                    : widget.progressPercentage / 100,
                strokeWidth: 4,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _showChallenge ? Colors.orange : AppColors.softPinkButton,
                ),
              ),
            ),
            // İçerideki Dairesel Buton (AnimatedSwitcher ile geçiş)
            Container(
              width: 50,
              height: 50,
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: _showChallenge
                    ? Column(
                        key: const ValueKey('challenge'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emoji_events,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(_firstActiveChallenge!.progress * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        key: const ValueKey('streak'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: AppColors.softPinkButton,
                            size: 20,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.userProvider.consecutiveDays}',
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
          ],
        ),
      ),
    );
  }
}

