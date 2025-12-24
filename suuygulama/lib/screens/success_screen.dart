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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
                                'Yeni bir mücadeleye başlayarak kendini zorla ve başarılar kazan!',
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

