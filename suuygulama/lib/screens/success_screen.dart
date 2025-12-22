import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../providers/user_provider.dart';
import '../providers/water_provider.dart';
import '../providers/achievement_provider.dart';
import '../models/achievement_model.dart';
import '../widgets/challenge_card.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _glowAnimationController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Parlama animasyonu için controller
    _glowAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(
        parent: _glowAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _glowAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _glowAnimationController.dispose();
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
                    Tab(text: 'Mücadeleler'),
                    Tab(text: 'Başarılar'),
                    Tab(text: 'T-Kart'),
                  ],
                ),
              ),
            ),
            
            // İçerik
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildChallengesTab(),
                  _buildAchievementsTab(),
                  _buildBadgesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mücadeleler Sekmesi
  Widget _buildChallengesTab() {
    return Consumer2<UserProvider, WaterProvider>(
      builder: (context, userProvider, waterProvider, child) {
        final challenges = ChallengeData.getChallenges();
        Challenge? activeChallenge;
        
        // Aktif mücadeleyi bul (ilk tamamlanmamış)
        for (var challenge in challenges) {
          if (challenge.id == 'deep_dive') {
            final isCompleted = userProvider.consecutiveDays >= 3 && 
                                waterProvider.hasReachedDailyGoal;
            if (!isCompleted) {
              activeChallenge = Challenge(
                id: challenge.id,
                name: challenge.name,
                description: challenge.description,
                coinReward: challenge.coinReward,
                cardColor: challenge.cardColor,
                icon: challenge.icon,
                whyStart: challenge.whyStart,
                healthBenefit: challenge.healthBenefit,
                badgeEmoji: challenge.badgeEmoji,
                isCompleted: false,
                progress: (userProvider.consecutiveDays / 3).clamp(0.0, 1.0),
                progressText: '${userProvider.consecutiveDays}/3 gün',
              );
              break;
            }
          }
        }
        
        if (activeChallenge == null && challenges.isNotEmpty) {
          activeChallenge = challenges.first;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (activeChallenge != null) ...[
                // Aktif Mücadele Kartı
                ChallengeCard(challenge: activeChallenge),
                
                const SizedBox(height: 20),
                
                // İlerleme Durumu
                Container(
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
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: AppColors.softPinkButton,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          activeChallenge.id == 'deep_dive'
                              ? userProvider.consecutiveDays < 3
                                  ? 'Hedefe sadece ${3 - userProvider.consecutiveDays} gün kaldı! 🔥'
                                  : 'Hedefe çok yakınsın! Son gün! 💪'
                              : 'Mücadele devam ediyor! 💪',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A5568),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Başarılar Sekmesi
  Widget _buildAchievementsTab() {
    return Consumer<AchievementProvider>(
      builder: (context, achievementProvider, child) {
        final achievements = achievementProvider.achievements;
        
        // Varsayılan başarılar listesi (eğer yoksa)
        final defaultAchievements = [
          {'id': 'first_step', 'name': 'İlk Su', 'emoji': '💧'},
          {'id': 'first_litre', 'name': 'İlk Litre', 'emoji': '🌊'},
          {'id': 'fish_champion', 'name': 'Balık Şampiyonu', 'emoji': '🐠'},
          {'id': 'daily_goal', 'name': 'Günlük Hedef', 'emoji': '🎯'},
          {'id': 'streak_3', 'name': '3 Gün Seri', 'emoji': '🔥'},
          {'id': 'streak_7', 'name': '7 Gün Seri', 'emoji': '⭐'},
          {'id': 'water_master', 'name': 'Su Ustası', 'emoji': '👑'},
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
                
                return Container(
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
                            if (achievement.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                achievement.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isUnlocked
                                      ? Colors.grey[600]
                                      : Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Kilit İkonu
                      Icon(
                        isUnlocked ? Icons.lock_open : Icons.lock,
                        color: isUnlocked
                            ? AppColors.softPinkButton
                            : Colors.grey[400],
                        size: 24,
                      ),
                    ],
                  ),
                );
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

  // Rozetler Sekmesi - Pokemon Kartı Koleksiyonu
  Widget _buildBadgesTab() {
    // Mock Data: 8 kart (ilk 3'ü kazanılmış)
    final cards = _getCardCollection();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pokemon Kartı Koleksiyonu - 2 Sütunlu Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.65, // Pokemon kartı oranı (dikey dikdörtgen)
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              return _buildPokemonCard(cards[index]);
            },
          ),
          
          const SizedBox(height: 24),
          
          // Gelecek Hedefler
          _buildFutureGoals(),
        ],
      ),
    );
  }

  // Mock Card Data
  List<Map<String, dynamic>> _getCardCollection() {
    return [
      {
        'id': 'first_cup',
        'name': 'İlk Bardak',
        'isUnlocked': true,
        'rarity': 'Başlangıç',
        'color': const Color(0xFF00BCD4), // Açık Mavi/Cyan
        'emoji': '💧',
      },
      {
        'id': 'blue_crystal_guardian',
        'name': 'Mavi Kristal Muhafızı',
        'isUnlocked': true,
        'rarity': 'Nadir',
        'color': const Color(0xFF4A9ED8), // Mavi
        'emoji': '💎',
      },
      {
        'id': 'water_drop_master',
        'name': 'Su Damlası Ustası',
        'isUnlocked': true,
        'rarity': 'Ortak',
        'color': AppColors.waterColor,
        'emoji': '🐟',
      },
      {
        'id': 'ocean_explorer',
        'name': 'Okyanus Kaşifi',
        'isUnlocked': true,
        'rarity': 'Nadir',
        'color': const Color(0xFF6B9BD1), // Açık Mavi
        'emoji': '🌊',
      },
      {
        'id': 'coral_protector',
        'name': 'Mercan Koruyucu',
        'isUnlocked': false,
        'rarity': 'Nadir',
        'color': const Color(0xFFFF6B9D), // Pembe
        'emoji': '🪸',
      },
      {
        'id': 'deep_dive_champion',
        'name': 'Derin Dalış Şampiyonu',
        'isUnlocked': false,
        'rarity': 'Efsanevi',
        'color': const Color(0xFF1E88E5), // Koyu Mavi
        'emoji': '🏆',
      },
      {
        'id': 'hydration_legend',
        'name': 'Hidrasyon Efsanesi',
        'isUnlocked': false,
        'rarity': 'Nadir',
        'color': const Color(0xFF00ACC1), // Turkuaz
        'emoji': '💧',
      },
      {
        'id': 'crystal_warrior',
        'name': 'Kristal Savaşçı',
        'isUnlocked': false,
        'rarity': 'Nadir',
        'color': const Color(0xFF9C27B0), // Mor
        'emoji': '⚔️',
      },
      {
        'id': 'aqua_guardian',
        'name': 'Su Koruyucusu',
        'isUnlocked': false,
        'rarity': 'Ortak',
        'color': const Color(0xFF00BCD4), // Cyan
        'emoji': '🛡️',
      },
    ];
  }

  // Pokemon Kartı Widget'ı (T-Kart)
  Widget _buildPokemonCard(Map<String, dynamic> card) {
    final isUnlocked = card['isUnlocked'] as bool;
    final name = card['name'] as String;
    final rarity = card['rarity'] as String;
    final color = card['color'] as Color;
    final emoji = card['emoji'] as String;

    if (isUnlocked) {
      // Kazanılmış Kart - Renkli ve Enerjik (Parlama Efekti ile)
      return AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 3,
              ),
              boxShadow: [
                // Parlama efekti - Animasyonlu (Altın veya Açık Mavi)
                BoxShadow(
                  color: (color == const Color(0xFF00BCD4) || 
                          color == AppColors.waterColor ||
                          color == const Color(0xFF6B9BD1))
                      ? Colors.cyan.withValues(alpha: _glowAnimation.value)
                      : Colors.amber.withValues(alpha: _glowAnimation.value),
                  blurRadius: 20,
                  spreadRadius: 3,
                  offset: const Offset(0, 0),
                ),
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Üst Köşe - Nadirlik Yıldızı
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '⭐',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rarity,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Orta - Emoji Görseli
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 60),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Alt Kısım - Kart Adı
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // Kazanılmamış Kart - Kilitli ve Gri
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[800]!,
              Colors.grey[700]!,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey[600]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Orta - Büyük Kilit İkonu
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '🔒',
                    style: TextStyle(fontSize: 80),
                  ),
                ],
              ),
            ),
            
            // Alt Kısım - ??? Yazısı
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: const Text(
                  '???',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                    letterSpacing: 2.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      );
    }
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
