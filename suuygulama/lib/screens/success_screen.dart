import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../providers/achievement_provider.dart';
import '../providers/challenge_provider.dart';
import '../models/achievement_model.dart';
import '../widgets/challenge_card.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final PageController _challengePageController = PageController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _challengePageController.dispose();
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

  // Mücadeleler Sekmesi - Yeniden Tasarlandı
  Widget _buildChallengesTab() {
    return Consumer<ChallengeProvider>(
      builder: (context, challengeProvider, child) {
        final activeChallenges = challengeProvider.activeIncompleteChallenges;
        
        return Column(
          children: [
            // Üst Bölüm: Aktif Mücadeleler Vitrini (PageView)
            if (activeChallenges.isNotEmpty) ...[
              SizedBox(
                height: 280,
                child: PageView.builder(
                  controller: _challengePageController,
                  itemCount: activeChallenges.length,
                  itemBuilder: (context, index) {
                    final challenge = activeChallenges[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: _buildActiveChallengeCard(challenge, challengeProvider),
                    );
                  },
                ),
              ),
              // Dots Indicator (Dinamik)
              _ChallengeDotsIndicator(
                pageController: _challengePageController,
                itemCount: activeChallenges.length,
              ),
              const SizedBox(height: 24),
            ],
            
            // Alt Bölüm: Yeni Mücadele Keşfet Butonu
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: () => _showChallengesModal(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.softPinkButton,
                            AppColors.softPinkButton.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.softPinkButton.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Yeni Bir Mücadele Keşfet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Aktif Mücadele Kartı (Gradient, İlerleme Barı, Coin, X Gün Kaldı)
  Widget _buildActiveChallengeCard(Challenge challenge, ChallengeProvider challengeProvider) {
    final progressPercentage = (challenge.progress * 100).toInt();
    final isCompleted = challenge.progress >= 1.0;
    
    // Kalan gün hesaplama (örnek - mücadele tipine göre değişebilir)
    final remainingDays = _calculateRemainingDays(challenge);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            challenge.cardColor,
            challenge.cardColor.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: challenge.cardColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Sağ Üst Köşe: Coin Ödülü Etiketi
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.monetization_on,
                    color: Colors.amber[700],
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${challenge.coinReward}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.amber[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Tamamlandı Rozeti (eğer %100 ise)
          if (isCompleted)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tamamlandı! 🎉',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // İçerik
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // İkon ve Mücadele Adı
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        challenge.icon,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            challenge.description,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                
                // İlerleme Barı
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'İlerleme',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        Text(
                          '%$progressPercentage',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: challenge.progress.clamp(0.0, 1.0),
                        minHeight: 16,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      challenge.progressText.isNotEmpty
                          ? challenge.progressText
                          : '${challenge.currentProgress.toStringAsFixed(1)} / ${challenge.targetValue.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                
                // Kalan Gün
                if (remainingDays != null && remainingDays > 0 && !isCompleted) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$remainingDays Gün Kaldı',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Kalan gün hesaplama (örnek implementasyon)
  int? _calculateRemainingDays(Challenge challenge) {
    // Bu mücadele tipine göre hesaplanabilir
    // Şimdilik basit bir örnek döndürüyorum
    if (challenge.id == 'blue_crystal') {
      return 7; // 7 günlük mücadele
    }
    return null;
  }
  
  // Mücadeleler Modal Bottom Sheet
  void _showChallengesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Tutma Çizgisi
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Başlık
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Tüm Mücadeleler',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Mücadele Listesi
            Expanded(
              child: Consumer<ChallengeProvider>(
                builder: (context, challengeProvider, child) {
                  final allChallenges = ChallengeData.getChallenges();
                  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: allChallenges.length,
                    itemBuilder: (context, index) {
                      final challenge = allChallenges[index];
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ChallengeCard(challenge: challenge),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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

// Dots Indicator Widget (PageView için)
class _ChallengeDotsIndicator extends StatefulWidget {
  final PageController pageController;
  final int itemCount;

  const _ChallengeDotsIndicator({
    required this.pageController,
    required this.itemCount,
  });

  @override
  State<_ChallengeDotsIndicator> createState() => _ChallengeDotsIndicatorState();
}

class _ChallengeDotsIndicatorState extends State<_ChallengeDotsIndicator> {
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    widget.pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_onPageChanged);
    super.dispose();
  }

  void _onPageChanged() {
    if (widget.pageController.page != null) {
      setState(() {
        _currentPage = widget.pageController.page!.round();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.itemCount,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentPage ? AppColors.softPinkButton : Colors.grey[300],
          ),
        ),
      ),
    );
  }
}

