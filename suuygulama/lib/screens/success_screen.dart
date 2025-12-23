import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final Map<String, AnimationController> _cardRevealControllers = {};
  final Map<String, Animation<double>> _cardRevealAnimations = {};

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
    // Kart açılma animasyon controller'larını temizle
    for (var controller in _cardRevealControllers.values) {
      controller.dispose();
    }
    _cardRevealControllers.clear();
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
        return FutureBuilder<Challenge?>(
          future: _getActiveChallenge(userProvider, waterProvider),
          builder: (context, snapshot) {
            final activeChallenge = snapshot.data;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activeChallenge != null) ...[
                    // Aktif Mücadele Kartı
                    ChallengeCard(challenge: activeChallenge),
                    
                    const SizedBox(height: 20),
                    
                    // Dinamik İlerleme Durumu
                    FutureBuilder<Map<String, dynamic>>(
                      future: _getChallengeProgressData(activeChallenge.id, userProvider, waterProvider),
                      builder: (context, progressSnapshot) {
                        final progressData = progressSnapshot.data ?? {
                          'motivationText': 'Mücadele devam ediyor! 💪',
                        };
                        
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
                                  progressData['motivationText'] as String? ?? 'Mücadele devam ediyor! 💪',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4A5568),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    // Boş Durum - Henüz Mücadele Başlatılmamış
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Henüz bir mücadeleye başlamadın.',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'T-Kart koleksiyonunu genişletmek için bir mücadele seç!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Ana ekrana dön ve mücadele panelini aç
                                Navigator.pop(context, 'open_challenges_panel');
                              },
                              icon: const Icon(Icons.visibility),
                              label: const Text('Mücadeleleri Gör'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.softPinkButton,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Aktif mücadeleyi kontrol et (sadece başlatılmış mücadeleler)
  Future<Challenge?> _getActiveChallenge(
    UserProvider userProvider,
    WaterProvider waterProvider,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final challenges = ChallengeData.getChallenges();
      
      // Başlatılmış mücadeleleri kontrol et
      for (var challenge in challenges) {
        final isStarted = prefs.getBool('challenge_${challenge.id}_started') ?? false;
        
        if (isStarted) {
          // Başlangıç tarihini al
          final startDateString = prefs.getString('challenge_${challenge.id}_start_date');
          DateTime? startDate;
          if (startDateString != null) {
            try {
              startDate = DateTime.parse(startDateString);
            } catch (e) {
              startDate = DateTime.now();
            }
          } else {
            startDate = DateTime.now();
          }
          
          // Mücadele tipine göre ilerleme hesapla
          final progressData = await _calculateChallengeProgress(
            challenge.id,
            startDate,
            userProvider,
            waterProvider,
          );
          
          // Tamamlanmış mücadeleleri gösterme
          if (progressData['isCompleted'] == true) {
            continue;
          }
          
          return Challenge(
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
            progress: progressData['progress'] as double,
            progressText: progressData['progressText'] as String,
          );
        }
      }
      
      // Hiç başlatılmış mücadele yok
      return null;
    } catch (e) {
      return null;
    }
  }

  // Mücadele ilerleme verilerini al (motivasyon metni için)
  Future<Map<String, dynamic>> _getChallengeProgressData(
    String challengeId,
    UserProvider userProvider,
    WaterProvider waterProvider,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startDateString = prefs.getString('challenge_${challengeId}_start_date');
      DateTime? startDate;
      
      if (startDateString != null) {
        try {
          startDate = DateTime.parse(startDateString);
        } catch (e) {
          startDate = DateTime.now();
        }
      } else {
        startDate = DateTime.now();
      }
      
      final progressData = await _calculateChallengeProgress(
        challengeId,
        startDate,
        userProvider,
        waterProvider,
      );
      
      final motivationText = _getChallengeMotivationText(challengeId, progressData);
      
      return {
        ...progressData,
        'motivationText': motivationText,
      };
    } catch (e) {
      return {
        'motivationText': 'Mücadele devam ediyor! 💪',
      };
    }
  }

  // Mücadele ilerlemesini hesapla
  Future<Map<String, dynamic>> _calculateChallengeProgress(
    String challengeId,
    DateTime startDate,
    UserProvider userProvider,
    WaterProvider waterProvider,
  ) async {
    final now = DateTime.now();
    final daysSinceStart = now.difference(startDate).inDays;
    final prefs = await SharedPreferences.getInstance();
    
    switch (challengeId) {
      case 'blue_crystal':
        // 1 hafta (7 gün) şekerli içecek yok
        final totalDays = 7;
        final currentDay = (daysSinceStart + 1).clamp(0, totalDays);
        final isCompleted = currentDay >= totalDays;
        
        // Mücadele tamamlandıysa SharedPreferences'a kaydet
        if (isCompleted) {
          await prefs.setBool('challenge_${challengeId}_completed', true);
        }
        
        return {
          'progress': (currentDay / totalDays).clamp(0.0, 1.0),
          'progressText': '$currentDay/$totalDays gün',
          'isCompleted': isCompleted,
          'currentDay': currentDay,
          'totalDays': totalDays,
        };
        
      case 'caffeine_hunter':
        // Bugün 2 kahve yerine 2 büyük bardak su (1 günlük)
        final totalDays = 1;
        final isCompleted = daysSinceStart >= 1;
        
        // Mücadele tamamlandıysa SharedPreferences'a kaydet
        if (isCompleted) {
          await prefs.setBool('challenge_${challengeId}_completed', true);
        }
        
        return {
          'progress': isCompleted ? 1.0 : 0.0,
          'progressText': isCompleted ? 'Tamamlandı!' : '0/1 gün',
          'isCompleted': isCompleted,
          'currentDay': isCompleted ? 1 : 0,
          'totalDays': totalDays,
        };
        
      case 'deep_dive':
        // 3 gün üst üste %100 su hedefi
        final totalDays = 3;
        final consecutiveDays = userProvider.consecutiveDays;
        final hasReachedGoal = waterProvider.hasReachedDailyGoal;
        final currentProgress = consecutiveDays.clamp(0, totalDays);
        final isCompleted = consecutiveDays >= totalDays && hasReachedGoal;
        
        // Mücadele tamamlandıysa SharedPreferences'a kaydet
        if (isCompleted) {
          await prefs.setBool('challenge_${challengeId}_completed', true);
        }
        
        return {
          'progress': (currentProgress / totalDays).clamp(0.0, 1.0),
          'progressText': '$currentProgress/$totalDays gün',
          'isCompleted': isCompleted,
          'currentDay': currentProgress,
          'totalDays': totalDays,
        };
        
      case 'coral_guardian':
        // Akşam 8'den sonra sadece su (sürekli, gün bazlı değil)
        // Basitleştirilmiş: Bugün hedefe ulaşıldı mı?
        final isCompleted = waterProvider.hasReachedDailyGoal;
        
        // Mücadele tamamlandıysa SharedPreferences'a kaydet
        if (isCompleted) {
          await prefs.setBool('challenge_${challengeId}_completed', true);
        }
        
        return {
          'progress': isCompleted ? 1.0 : 0.5,
          'progressText': isCompleted ? 'Tamamlandı!' : 'Devam ediyor...',
          'isCompleted': isCompleted,
          'currentDay': isCompleted ? 1 : 0,
          'totalDays': 1,
        };
        
      default:
        return {
          'progress': 0.0,
          'progressText': 'Devam ediyor...',
          'isCompleted': false,
          'currentDay': 0,
          'totalDays': 1,
        };
    }
  }

  // Mücadeleye özel motivasyon metni
  String _getChallengeMotivationText(
    String challengeId,
    Map<String, dynamic> progressData,
  ) {
    final currentDay = progressData['currentDay'] as int;
    final totalDays = progressData['totalDays'] as int;
    final remainingDays = totalDays - currentDay;
    
    switch (challengeId) {
      case 'blue_crystal':
        if (remainingDays <= 0) {
          return 'Mücadeleyi tamamladın! Harika iş çıkardın! 💎';
        } else if (currentDay == 0) {
          return 'Mavi Kristal mücadelesine başladın! İlk gün, harika! 💎';
        } else {
          final remainingText = remainingDays > 0 ? 'Sadece $remainingDays gün kaldı! 💎' : '';
          return 'Şekersiz $currentDay. günün, harika gidiyorsun! $remainingText';
        }
        
      case 'caffeine_hunter':
        if (progressData['isCompleted'] == true) {
          return 'Kafein Avcısı mücadelesini tamamladın! Kahve bağımlılığından kurtulma yolundasın! 🚫☕';
        } else {
          return 'Bugün 2 kahve yerine 2 büyük bardak su iç! Kafein bağımlılığından kurtul! 🚫☕';
        }
        
      case 'deep_dive':
        if (remainingDays <= 0) {
          return 'Derin Dalış mücadelesini tamamladın! 3 gün üst üste hedefe ulaştın! 🌊';
        } else if (currentDay == 0) {
          return 'Derin Dalış mücadelesine başladın! 3 gün üst üste hedefe ulaş! 🌊';
        } else {
          return 'Hedefe sadece $remainingDays gün kaldı! $currentDay/3 gün tamamlandı! 🌊';
        }
        
      case 'coral_guardian':
        if (progressData['isCompleted'] == true) {
          return 'Mercan Koruyucu mücadelesini tamamladın! Gece rutinin harika! 🪸';
        } else {
          return 'Akşam 8\'den sonra sadece su iç! Daha kaliteli uyku için! 🪸';
        }
        
      default:
        return 'Mücadele devam ediyor! 💪';
    }
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

  // Rozetler Sekmesi - Pokemon Kartı Koleksiyonu
  Widget _buildBadgesTab() {
    return Consumer2<AchievementProvider, WaterProvider>(
      builder: (context, achievementProvider, waterProvider, child) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _loadCardUnlockStatuses(achievementProvider),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final cards = snapshot.data!;

            // Set tamamlama kontrolü (her render'da kontrol et)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkSetCompletion(cards, waterProvider, context);
            });

            // Set ilerlemesini hesapla
            final setProgress = _calculateSetProgress(cards);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Set İlerlemesi Göstergesi
                  ...setProgress.map((progress) => _buildSetProgressIndicator(progress)),
                  
                  if (setProgress.isNotEmpty) const SizedBox(height: 16),
                  
                  // Kart Albümü - 2 Sütunlu Grid (Albüm Düzeni)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.7, // Albüm kartı oranı
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
          },
        );
      },
    );
  }

  // T-Kart unlock durumlarını yükle
  Future<List<Map<String, dynamic>>> _loadCardUnlockStatuses(
    AchievementProvider achievementProvider,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final allCards = _getCardCollection();
    
    return allCards.map((card) {
      final cardId = card['id'] as String;
      bool isUnlocked = false;
      
      // İlk Bardak - AchievementProvider'dan kontrol et
      if (cardId == 'first_cup') {
        isUnlocked = achievementProvider.isAchievementUnlocked('first_cup');
      } else {
        // Mücadele kartları - SharedPreferences'tan kontrol et
        // Mücadele tamamlandıysa kart unlock edilir
        isUnlocked = _isChallengeCardUnlockedSync(cardId, prefs);
      }
      
      return {
        ...card,
        'isUnlocked': isUnlocked,
      };
    }).toList();
  }

  // Mücadele kartının unlock durumunu kontrol et (sync)
  bool _isChallengeCardUnlockedSync(String cardId, SharedPreferences prefs) {
    // T-Kart ID'lerini mücadele ID'lerine map et
    final Map<String, String> cardToChallengeMap = {
      'blue_crystal_guardian': 'blue_crystal',
      'water_drop_master': 'deep_dive',
      'ocean_explorer': 'deep_dive',
      'coral_protector': 'coral_guardian',
      'deep_dive_champion': 'deep_dive',
      'hydration_legend': 'deep_dive',
      'crystal_warrior': 'blue_crystal',
      'aqua_guardian': 'deep_dive',
    };
    
    final challengeId = cardToChallengeMap[cardId];
    if (challengeId == null) {
      return false; // Eşleşme yoksa kilitli
    }
    
    // Mücadele başlatıldı mı ve tamamlandı mı kontrol et
    final isStarted = prefs.getBool('challenge_${challengeId}_started') ?? false;
    if (!isStarted) {
      return false; // Mücadele başlatılmamışsa kilitli
    }
    
    // Mücadele ilerlemesini kontrol et
    final startDateString = prefs.getString('challenge_${challengeId}_start_date');
    if (startDateString == null) {
      return false; // Başlangıç tarihi yoksa kilitli
    }
    
    try {
      final startDate = DateTime.parse(startDateString);
      // Mücadele ilerlemesini hesapla (basitleştirilmiş - gerçek kontrol için UserProvider ve WaterProvider gerekli)
      // Şimdilik sadece tamamlanma flag'ini kontrol et
      final isCompleted = prefs.getBool('challenge_${challengeId}_completed') ?? false;
      
      // Eğer tamamlanma flag'i yoksa, ilerleme kontrolü yap
      if (!isCompleted) {
        // Mücadele ilerlemesini kontrol et (basitleştirilmiş)
        final now = DateTime.now();
        final daysSinceStart = now.difference(startDate).inDays;
        
        // Mücadele tipine göre kontrol
        switch (challengeId) {
          case 'blue_crystal':
            // 1 hafta (7 gün) şekerli içecek yok
            if (daysSinceStart >= 7) {
              // Mücadele tamamlandı olarak işaretle
              prefs.setBool('challenge_${challengeId}_completed', true);
              return true;
            }
            break;
          case 'deep_dive':
            // 3 gün üst üste %100 su hedefi (basitleştirilmiş kontrol)
            // Gerçek kontrol için UserProvider gerekli
            break;
          case 'coral_guardian':
            // Akşam 8'den sonra sadece su (sürekli kontrol gerekli)
            break;
          default:
            break;
        }
      }
      
      return isCompleted;
    } catch (e) {
      return false; // Parse hatası durumunda kilitli
    }
  }

  // Set Tanımları
  static const Map<String, Map<String, dynamic>> _cardSets = {
    'deniz_canlilari': {
      'name': 'Deniz Canlıları Seti',
      'cardIds': ['water_drop_master', 'ocean_explorer', 'aqua_guardian', 'first_cup'],
      'reward': 500,
    },
    'kristal_serisi': {
      'name': 'Kristal Serisi',
      'cardIds': ['blue_crystal_guardian', 'crystal_warrior'],
      'reward': 500,
    },
    'derin_sular': {
      'name': 'Derin Sular',
      'cardIds': ['deep_dive_champion', 'coral_protector', 'hydration_legend'],
      'reward': 500,
    },
  };

  // Mock Card Data
  List<Map<String, dynamic>> _getCardCollection() {
    return [
      {
        'id': 'first_cup',
        'name': 'İlk Bardak',
        'isUnlocked': false, // AchievementProvider'dan kontrol edilecek
        'rarity': 'Başlangıç',
        'color': const Color(0xFF00BCD4), // Açık Mavi/Cyan
        'emoji': '💧',
        'setId': 'deniz_canlilari', // Set ID eklendi
      },
      {
        'id': 'blue_crystal_guardian',
        'name': 'Mavi Kristal Muhafızı',
        'isUnlocked': false, // Mücadele bitmeden kilitli
        'rarity': 'Nadir',
        'color': const Color(0xFF4A9ED8), // Mavi
        'emoji': '💎',
        'setId': 'kristal_serisi',
      },
      {
        'id': 'water_drop_master',
        'name': 'Su Damlası Ustası',
        'isUnlocked': false, // Mücadele bitmeden kilitli
        'rarity': 'Ortak',
        'color': AppColors.waterColor,
        'emoji': '🐟',
        'setId': 'deniz_canlilari',
      },
      {
        'id': 'ocean_explorer',
        'name': 'Okyanus Kaşifi',
        'isUnlocked': false, // Mücadele bitmeden kilitli
        'rarity': 'Nadir',
        'color': const Color(0xFF6B9BD1), // Açık Mavi
        'emoji': '🌊',
        'setId': 'deniz_canlilari',
      },
      {
        'id': 'coral_protector',
        'name': 'Mercan Koruyucu',
        'isUnlocked': false,
        'rarity': 'Nadir',
        'color': const Color(0xFFFF6B9D), // Pembe
        'emoji': '🪸',
        'setId': 'derin_sular',
      },
      {
        'id': 'deep_dive_champion',
        'name': 'Derin Dalış Şampiyonu',
        'isUnlocked': false,
        'rarity': 'Efsanevi',
        'color': const Color(0xFF1E88E5), // Koyu Mavi
        'emoji': '🏆',
        'setId': 'derin_sular',
      },
      {
        'id': 'hydration_legend',
        'name': 'Hidrasyon Efsanesi',
        'isUnlocked': false,
        'rarity': 'Nadir',
        'color': const Color(0xFF00ACC1), // Turkuaz
        'emoji': '💧',
        'setId': 'derin_sular',
      },
      {
        'id': 'crystal_warrior',
        'name': 'Kristal Savaşçı',
        'isUnlocked': false,
        'rarity': 'Nadir',
        'color': const Color(0xFF9C27B0), // Mor
        'emoji': '⚔️',
        'setId': 'kristal_serisi',
      },
      {
        'id': 'aqua_guardian',
        'name': 'Su Koruyucusu',
        'isUnlocked': false,
        'rarity': 'Ortak',
        'color': const Color(0xFF00BCD4), // Cyan
        'emoji': '🛡️',
        'setId': 'deniz_canlilari',
      },
    ];
  }

  // Kart Albümü Widget'ı (T-Kart)
  Widget _buildPokemonCard(Map<String, dynamic> card) {
    final isUnlocked = card['isUnlocked'] as bool;
    final name = card['name'] as String;
    final color = card['color'] as Color;
    final emoji = card['emoji'] as String;

    if (isUnlocked) {
      // Kazanılmış Kart - Renkli ve Parlayan (Albümde Dolu Slot) - Kart Açılma Animasyonu ile
      final cardId = card['id'] as String;
      
      // Kart açılma animasyonu için controller oluştur (eğer yoksa)
      if (!_cardRevealControllers.containsKey(cardId)) {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 600),
          vsync: this,
        );
        final animation = CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutBack,
        );
        _cardRevealControllers[cardId] = controller;
        _cardRevealAnimations[cardId] = animation;
        controller.forward();
      }
      
      return AnimatedBuilder(
        animation: Listenable.merge([
          _glowAnimation,
          _cardRevealAnimations[cardId]!,
        ]),
        builder: (context, child) {
          final revealAnimation = _cardRevealAnimations[cardId]!;
          
          return Transform.scale(
            scale: revealAnimation.value.clamp(0.0, 1.0),
            child: Opacity(
              opacity: revealAnimation.value.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    // Parlama efekti - Animasyonlu
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
                    // Orta - Emoji Görseli
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 50),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Alt Kısım - Kart Adı ve Durum
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Koleksiyonda',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else {
      // Boş Albüm Yuvası - Kilitli Kart (Keşfedilmeyi Bekliyor)
      return Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CustomPaint(
            painter: DashedBorderPainter(
              color: Colors.grey[400]!.withValues(alpha: 0.3), // Çok hafif gri çerçeve
              strokeWidth: 1.5, // İnce çizgi
              dashLength: 6,
              dashSpace: 4,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                // Çok hafif gölge (neredeyse görünmez)
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Orta - Çok Silik Kilit İkonu (Renkli şablonlar gözükmemeli)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Silik kilit ikonu (emoji veya renkli içerik yok)
                        Icon(
                          Icons.lock_outline,
                          size: 36,
                          color: Colors.grey[400]!.withValues(alpha: 0.4), // Çok silik
                        ),
                      ],
                    ),
                  ),
                  
                  // Alt Kısım - Keşfedilmeyi Bekliyor Metni
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.transparent, // Şeffaf arka plan
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Keşfedilmeyi Bekliyor',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[500]!.withValues(alpha: 0.6), // Çok silik metin
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
            ),
          ),
        ),
      );
    }
  }

  // Set ilerlemesini hesapla
  List<Map<String, dynamic>> _calculateSetProgress(List<Map<String, dynamic>> cards) {
    final progressList = <Map<String, dynamic>>[];
    
    for (final setEntry in _cardSets.entries) {
      final setId = setEntry.key;
      final setData = setEntry.value;
      final cardIds = setData['cardIds'] as List<String>;
      
      int unlockedCount = 0;
      for (final cardId in cardIds) {
        final card = cards.firstWhere(
          (c) => c['id'] == cardId,
          orElse: () => {'isUnlocked': false},
        );
        if (card['isUnlocked'] == true) {
          unlockedCount++;
        }
      }
      
      final totalCards = cardIds.length;
      final isCompleted = unlockedCount == totalCards;
      
      progressList.add({
        'setId': setId,
        'setName': setData['name'] as String,
        'unlockedCount': unlockedCount,
        'totalCards': totalCards,
        'isCompleted': isCompleted,
      });
    }
    
    return progressList;
  }

  // Set İlerlemesi Göstergesi Widget'ı
  Widget _buildSetProgressIndicator(Map<String, dynamic> progress) {
    final setName = progress['setName'] as String;
    final unlockedCount = progress['unlockedCount'] as int;
    final totalCards = progress['totalCards'] as int;
    final isCompleted = progress['isCompleted'] as bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? Colors.green.shade300 : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Set İkonu
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green.shade100 : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check_circle : Icons.collections,
              color: isCompleted ? Colors.green.shade700 : Colors.grey.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Set Bilgisi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  setName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? Colors.green.shade800 : const Color(0xFF4A5568),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set İlerlemesi: $unlockedCount/$totalCards',
                  style: TextStyle(
                    fontSize: 14,
                    color: isCompleted ? Colors.green.shade600 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // İlerleme Çubuğu
          SizedBox(
            width: 60,
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: unlockedCount / totalCards,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? Colors.green.shade400 : AppColors.softPinkButton,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                if (isCompleted) ...[
                  const SizedBox(height: 4),
                  Icon(
                    Icons.stars,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Set tamamlama kontrolü ve ödül verme
  Future<void> _checkSetCompletion(
    List<Map<String, dynamic>> cards,
    WaterProvider waterProvider,
    BuildContext context,
  ) async {
    for (final setEntry in _cardSets.entries) {
      final setId = setEntry.key;
      final setData = setEntry.value;
      final cardIds = setData['cardIds'] as List<String>;
      
      // Bu set daha önce tamamlandı mı kontrol et
      final prefs = await SharedPreferences.getInstance();
      final completedSets = prefs.getStringList('completed_sets') ?? [];
      if (completedSets.contains(setId)) {
        continue; // Bu set zaten tamamlanmış
      }
      
      // Set içindeki tüm kartların unlock durumunu kontrol et
      bool allUnlocked = true;
      for (final cardId in cardIds) {
        final card = cards.firstWhere(
          (c) => c['id'] == cardId,
          orElse: () => {'isUnlocked': false},
        );
        if (card['isUnlocked'] != true) {
          allUnlocked = false;
          break;
        }
      }
      
      // Set tamamlandıysa ödül ver ve kutlama göster
      if (allUnlocked) {
        // Set tamamlandı olarak işaretle
        completedSets.add(setId);
        await prefs.setStringList('completed_sets', completedSets);
        
        // 500 Coin ödülü ver
        await waterProvider.addCoins(500);
        
        // Kutlama ekranını göster
        if (mounted && context.mounted) {
          _showSetCompletionCelebration(context, setData['name'] as String, 500);
        }
      }
    }
  }

  // Set Tamamlama Kutlama Ekranı
  void _showSetCompletionCelebration(BuildContext context, String setName, int coinReward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.amber.shade400,
                Colors.orange.shade600,
                Colors.pink.shade400,
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Yıldız İkonu
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.stars,
                        size: 60,
                        color: Colors.amber,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Başlık
              const Text(
                '🎉 SET TAMAMLANDI! 🎉',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Set Adı
              Text(
                setName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Mesaj
              Text(
                'Tüm Deniz Canlıları Serisini Tamamladın! 500 Coin Hediye!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.95),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Coin Ödülü
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '+$coinReward Coin',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // Tamam Butonu
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (mounted) {
                    setState(() {}); // UI'ı güncelle
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 8,
                ),
                child: const Text(
                  'Harika!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

// Dashed Border Painter - Albüm Yuvası İçin Kesik Çizgili Çerçeve
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final radius = 16.0;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    final dashPath = _dashPath(path, dashLength, dashSpace);
    canvas.drawPath(dashPath, paint);
  }

  Path _dashPath(Path path, double dashLength, double dashSpace) {
    final dashPath = Path();
    final pathMetrics = path.computeMetrics();

    for (final pathMetric in pathMetrics) {
      var distance = 0.0;
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + dashSpace;
      }
    }

    return dashPath;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
