import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mücadele modeli
class Challenge {
  final String id;
  final String name;
  final String description;
  final int coinReward;
  final Color cardColor;
  final IconData icon;
  final String whyStart;
  final String healthBenefit;
  final bool isCompleted;
  final double progress;
  final String progressText;
  final String badgeEmoji; // Rozet emoji (placeholder görsel)

  Challenge({
    required this.id,
    required this.name,
    required this.description,
    required this.coinReward,
    required this.cardColor,
    required this.icon,
    required this.whyStart,
    required this.healthBenefit,
    this.isCompleted = false,
    this.progress = 0.0,
    this.progressText = '',
    required this.badgeEmoji,
  });
}

// Pokemon kartı tarzı Challenge Card Widget'ı
class ChallengeCard extends StatefulWidget {
  final Challenge challenge;
  final VoidCallback? onTap;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.onTap,
  });

  @override
  State<ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends State<ChallengeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      _showChallengeDetail();
    }
  }

  void _showChallengeDetail() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: _buildDetailCard(),
      ),
    );
  }

  Widget _buildDetailCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: widget.challenge.cardColor,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.challenge.cardColor.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Üst kısım - Görsel alan ve ödül
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.challenge.cardColor.withValues(alpha: 0.2),
                          widget.challenge.cardColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(21),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // İkon (Pokemon görseli yerine)
                        Center(
                          child: Icon(
                            widget.challenge.icon,
                            size: 100,
                            color: widget.challenge.cardColor.withValues(alpha: 0.6),
                          ),
                        ),
                        // Sol üst - Rozet (Badge)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.challenge.cardColor,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                widget.challenge.badgeEmoji,
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                          ),
                        ),
                        // Sağ üst - Ödül (HP puanı gibi)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: widget.challenge.cardColor,
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '🟡',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.challenge.coinReward}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: widget.challenge.cardColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Alt kısım - İçerik
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mücadele ismi (Pokemon yeteneği gibi)
                        Text(
                          widget.challenge.name,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: widget.challenge.cardColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.challenge.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Neden Başlamalısın?
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: widget.challenge.cardColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: widget.challenge.cardColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: widget.challenge.cardColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Neden Başlamalısın?',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: widget.challenge.cardColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.challenge.whyStart,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[800],
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Sağlık Kazanımı
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: widget.challenge.cardColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: widget.challenge.cardColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.favorite,
                                    color: widget.challenge.cardColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Sağlık Kazanımı',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: widget.challenge.cardColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.challenge.healthBenefit,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[800],
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Mücadeleye Başla ve Kapat butonları
                        Row(
                          children: [
                            // Mücadeleye Başla butonu
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  // Mücadeleyi başlat - SharedPreferences'a kaydet
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setBool('challenge_${widget.challenge.id}_started', true);
                                  await prefs.setString('challenge_${widget.challenge.id}_start_date', DateTime.now().toIso8601String());
                                  
                                  if (!context.mounted) return;
                                  
                                  // Başarı mesajı göster
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${widget.challenge.name} mücadelesi başlatıldı! 🎯'),
                                      backgroundColor: widget.challenge.cardColor,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: widget.challenge.cardColor,
                                  elevation: 4,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: const Text(
                                  'Mücadeleye Başla',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Kapat butonu
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: widget.challenge.cardColor,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(
                                    color: widget.challenge.cardColor,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: const Text(
                                  'Kapat',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.challenge.cardColor,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.challenge.cardColor.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Görsel alan (üst kısım)
              Container(
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.challenge.cardColor.withValues(alpha: 0.15),
                      widget.challenge.cardColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(17),
                  ),
                ),
                child: Stack(
                  children: [
                    // İkon (Pokemon görseli yerine)
                    Center(
                      child: Icon(
                        widget.challenge.icon,
                        size: 70,
                        color: widget.challenge.cardColor.withValues(alpha: 0.5),
                      ),
                    ),
                    // Sağ üst - Ödül (HP puanı gibi)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: widget.challenge.cardColor,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '🟡',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.challenge.coinReward}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: widget.challenge.cardColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Alt kısım - Mücadele ismi (Pokemon yeteneği gibi)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(17),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.challenge.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: widget.challenge.cardColor,
                          letterSpacing: 0.3,
                        ),
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
  }
}

// 4 Şablon Mücadele
class ChallengeData {
  static List<Challenge> getChallenges() {
    return [
      // Kolay (20 Coin)
      Challenge(
        id: 'caffeine_hunter',
        name: 'Kafein Avcısı',
        description: 'Bugün 2 kahve yerine 2 büyük bardak su',
        coinReward: 20, // Kolay
        cardColor: const Color(0xFF8B4513), // Kahverengi
        icon: Icons.local_cafe,
        whyStart: 'Kafein dehidrasyona neden olabilir. Kahve yerine su içerek vücudunuzun gerçekten ihtiyaç duyduğu sıvıyı sağlarsınız.',
        healthBenefit: 'Daha iyi hidrasyon, daha stabil enerji seviyeleri ve daha kaliteli uyku. Kafein bağımlılığından kurtulmak için ilk adım!',
        badgeEmoji: '🚫☕', // Kahve yasağı rozeti
      ),
      // Orta (50 Coin)
      Challenge(
        id: 'coral_guardian',
        name: 'Mercan Koruyucu',
        description: 'Akşam 8\'den sonra sadece su tüket',
        coinReward: 50, // Orta
        cardColor: const Color(0xFFFF6B9D), // Pembe/Mercan
        icon: Icons.nightlight_round,
        whyStart: 'Gece geç saatlerde şekerli veya kafeinli içecekler uyku kalitenizi bozar. Sadece su içerek daha iyi bir gece uykusu sağlarsınız.',
        healthBenefit: 'Daha kaliteli uyku, daha iyi metabolizma ve sabah daha dinç uyanma. Gece rutininizi optimize edin!',
        badgeEmoji: '🪸', // Mercan rozeti
      ),
      Challenge(
        id: 'blue_crystal',
        name: 'Mavi Kristal',
        description: '1 hafta şekerli içecek yok',
        coinReward: 50, // Orta
        cardColor: const Color(0xFF4A9ED8), // Mavi
        icon: Icons.diamond,
        whyStart: 'Şekerli içecekler vücudunuzun su dengesini bozar ve gereksiz kalori ekler. Bu mücadele ile hem hidrasyonunuzu iyileştirir hem de kilo kontrolüne yardımcı olursunuz.',
        healthBenefit: 'Şekersiz bir hafta, kan şekeri seviyenizi dengeleyecek, enerji seviyenizi artıracak ve cildinizin daha sağlıklı görünmesini sağlayacak.',
        badgeEmoji: '💎', // Balık Kristali rozeti
      ),
      // Zor (100 Coin)
      Challenge(
        id: 'deep_dive',
        name: 'Derin Dalış',
        description: '3 gün üst üste %100 su hedefi',
        coinReward: 100, // Zor
        cardColor: const Color(0xFF6B9BD1), // Açık Mavi
        icon: Icons.water_drop,
        whyStart: 'Düzenli su tüketimi alışkanlık haline getirmek için en etkili yöntem. 3 gün üst üste hedefe ulaşmak, kalıcı bir rutin oluşturmanıza yardımcı olur.',
        healthBenefit: 'Optimal hidrasyon, gelişmiş bilişsel fonksiyon, daha iyi sindirim ve genel sağlık. Vücudunuz size teşekkür edecek!',
        badgeEmoji: '🌊', // Dalga rozeti
      ),
    ];
  }
}

