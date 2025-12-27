import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';
import '../utils/app_colors.dart';
import '../utils/unit_converter.dart';
import '../providers/water_provider.dart';
import '../providers/user_provider.dart';
import '../providers/achievement_provider.dart';
import '../models/drink_model.dart';
import 'package:provider/provider.dart';

class InteractiveCupModal extends StatefulWidget {
  const InteractiveCupModal({super.key});

  @override
  State<InteractiveCupModal> createState() => _InteractiveCupModalState();
}

class _InteractiveCupModalState extends State<InteractiveCupModal>
    with TickerProviderStateMixin {
  double _currentAmount = 0.0; // ml cinsinden
  bool _isLoading = true;
  double? _selectedTemplateMax; // Seçili şablonun maksimum kapasitesi
  double? _selectedTemplateAmount; // Hangi hazır buton seçili (null = manuel ayar)
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  late AnimationController _bubbleController;
  late Animation<double> _bubbleAnimation;
  final ScrollController _templateScrollController = ScrollController();
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  
  // Öğretici el animasyonu için
  late AnimationController _handAnimationController;
  late Animation<double> _handAnimation;
  bool _showTutorial = false; // Tutorial gösterilecek mi?
  bool _hasInteracted = false; // Kullanıcı ekrana dokundu mu?
  
  // Şablon miktarlar (ml cinsinden) - 250 ile başlar
  final List<double> _templateAmounts = [250, 330, 500, 1000];

  @override
  void initState() {
    super.initState();
    
    // Dalga animasyonu
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 2 * 3.14159).animate(
      CurvedAnimation(
        parent: _waveController,
        curve: Curves.linear,
      ),
    );
    _waveController.repeat();
    
    // Kabarcık animasyonu
    _bubbleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _bubbleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bubbleController,
        curve: Curves.linear,
      ),
    );
    _bubbleController.repeat();
    
    // Öğretici el animasyonu (pulse/scale + yukarı-aşağı hareket)
    _handAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _handAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _handAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _loadPreferredUnit();
    _checkTutorialStatus();
  }
  
  // Tutorial durumunu kontrol et (sadece ilk kullanımda göster)
  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('seen_hand_tutorial') ?? false;
    
    if (!hasSeen && mounted) {
      setState(() {
        _showTutorial = true;
      });
      _handAnimationController.repeat(reverse: true);
      // Hemen kaydet - bir sonraki açılışta gösterme
      await prefs.setBool('seen_hand_tutorial', true);
      
      // 5 saniye sonra otomatik gizle
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && !_hasInteracted) {
          setState(() {
            _showTutorial = false;
          });
          _handAnimationController.stop();
        }
      });
    } else {
      if (mounted) {
        setState(() {
          _showTutorial = false;
        });
      }
    }
  }
  
  void _hideHandAnimation() {
    if (!_showTutorial || _hasInteracted) return;
    
    if (mounted) {
      setState(() {
        _showTutorial = false;
        _hasInteracted = true;
      });
      _handAnimationController.stop();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _bubbleController.dispose();
    _handAnimationController.dispose();
    _templateScrollController.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPreferredUnit() async {
    // Artık _preferredUnit kullanmıyoruz, UserProvider.isMetric kullanıyoruz
    setState(() {
      _currentAmount = 250.0; // 250 ile başla
      _selectedTemplateAmount = 250.0; // Başlangıçta 250ml butonu varsayılan olarak seçili (aktif/siyah)
      _selectedTemplateMax = 250.0; // Maksimum kapasiteyi 250ml olarak ayarla
      _isLoading = false;
    });
    
    // UserProvider'dan birim bilgisini al ve TextField'ı güncelle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final displayValue = userProvider.isMetric 
            ? _currentAmount 
            : (_currentAmount * 0.033814); // Oz hesaplama: targetMl * 0.033814
        _amountController.text = displayValue.toStringAsFixed(userProvider.isMetric ? 0 : 1);
        // Seçili öğeyi merkeze getir (250ml butonu)
        _scrollToSelectedTemplate();
      }
    });
  }
  
  void _selectTemplateAmount(double amount) {
    setState(() {
      _selectedTemplateAmount = amount; // Hangi hazır buton seçili
      _selectedTemplateMax = amount; // Maksimum kapasiteyi şablon miktarına ayarla
      _currentAmount = amount.clamp(0.0, amount);
    });
    
    // UserProvider'dan birim bilgisini al ve TextField'ı güncelle
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final displayValue = userProvider.isMetric 
        ? _currentAmount 
        : (_currentAmount * 0.033814); // Oz hesaplama: targetMl * 0.033814
    _amountController.text = displayValue.toStringAsFixed(userProvider.isMetric ? 0 : 1);
    
    // Seçili öğeyi merkeze getir
    _scrollToSelectedTemplate();
  }

  void _scrollToSelectedTemplate() {
    if (!_templateScrollController.hasClients) return;
    
    // En yakın şablon miktarını bul
    double minDiff = double.infinity;
    int selectedIndex = 0;
    for (int i = 0; i < _templateAmounts.length; i++) {
      final diff = (_currentAmount - _templateAmounts[i]).abs();
      if (diff < minDiff) {
        minDiff = diff;
        selectedIndex = i;
      }
    }
    
    // Scroll pozisyonunu hesapla (her öğe: padding 20*2 + margin 8*2 + içerik genişliği ~60 = ~96px)
    final itemWidth = 96.0; // 20*2 (padding) + 8*2 (margin) + ~60 (içerik)
    final screenWidth = MediaQuery.of(context).size.width;
    final scrollPosition = (selectedIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
    
    final maxScroll = _templateScrollController.position.maxScrollExtent;
    final clampedPosition = scrollPosition.clamp(0.0, maxScroll);
    
    _templateScrollController.animateTo(
      clampedPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // Maksimum sınır - Seçili şablon miktarına göre (ml cinsinden)
  double get _maxAmountMl {
    return _selectedTemplateMax ?? 1000.0;
  }

  // Drag işlemi - Artırılmış hassasiyet
  void _onVerticalDragUpdate(DragUpdateDetails details) {
    // Kullanıcı etkileşime geçti, el animasyonunu gizle
    if (!_hasInteracted) {
      _hideHandAnimation();
    }
    
    // Manuel kaydırma yapıldığında hazır buton seçimini iptal et
    if (_selectedTemplateAmount != null) {
      setState(() {
        _selectedTemplateAmount = null; // Manuel ayar moduna geç
      });
    }
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    setState(() {
      // Yukarı kaydırma = artır, aşağı kaydırma = azalt
      // Hassasiyeti artırmak için delta'yı 2.5 ile çarp
      final delta = -details.delta.dy * 2.5; // 2.5x hassasiyet çarpanı
      
      // 10'ar 10'ar artış için hassasiyet ayarı
      double stepSize;
      if (!userProvider.isMetric) {
        stepSize = 0.3; // oz için yaklaşık 10ml karşılığı
      } else {
        stepSize = 10.0; // ml için 10'ar 10'ar
      }
      
      // Delta'yı step size'a göre yuvarla (daha az hareketle tepki vermek için)
      final steps = (delta / 15.0).round(); // Her 15px drag = 1 step (daha hassas)
      final deltaAmount = steps * stepSize;
      
      // Display değerini güncelle (ml'den display'e çevir)
      final currentDisplay = userProvider.isMetric 
          ? _currentAmount 
          : (_currentAmount * 0.033814); // Oz hesaplama: targetMl * 0.033814
      final maxDisplay = userProvider.isMetric 
          ? _maxAmountMl 
          : (_maxAmountMl * 0.033814); // Oz hesaplama: targetMl * 0.033814
      final newDisplay = (currentDisplay + deltaAmount).clamp(0.0, maxDisplay);
      
      // ml'ye geri çevir ve 10'un katına yuvarla
      if (!userProvider.isMetric) {
        _currentAmount = (newDisplay / 0.033814).roundToDouble(); // Oz'dan ml'ye: oz / 0.033814 = ml
      } else {
        _currentAmount = newDisplay.roundToDouble();
      }
      
      // 10'un katına yuvarla (240, 250, 260 gibi)
      _currentAmount = (_currentAmount / 10).round() * 10.0;
      
      // Maksimum ml sınırını kontrol et - Seçili şablon miktarına göre (0 ile max arasında clamp)
      _currentAmount = _currentAmount.clamp(0.0, _maxAmountMl);
      
      // TextField'ı güncelle
      final displayValue = userProvider.isMetric 
          ? _currentAmount 
          : (_currentAmount * 0.033814); // Oz hesaplama: targetMl * 0.033814
      final newText = displayValue.toStringAsFixed(userProvider.isMetric ? 0 : 1);
      if (_amountController.text != newText) {
        _amountController.text = newText;
      }
    });
    
    // Manuel kaydırma sırasında şablon slider'ı güncelleme - butonlar aktif olmamalı
    // _scrollToSelectedTemplate() çağrısını kaldırdık
  }

  // Su seviyesi yüzdesi - Hazır buton seçiliyse sabit görsel seviye (%80-85), manuel ayardaysa dinamik
  double get _fillPercentage {
    if (_maxAmountMl <= 0) return 0.0;
    
    // Hazır buton seçiliyse sabit görsel yükseklik (tüm butonlar için aynı - içilmeye hazır dolu bardak görünümü)
    if (_selectedTemplateAmount != null) {
      return 0.82; // Sabit görsel seviye %82 - içilmeye hazır dolu bir bardak gibi (tam dolu değil, ağzına kadar taşmış değil)
    }
    
    // Manuel ayar modunda: Su seviyesi seçilen miktara göre hesaplanır (maksimum %92 ile sınırlı - dudak payı)
    final percentage = (_currentAmount / _maxAmountMl).clamp(0.0, 0.92);
    return percentage;
  }

  // Su ekleme işlemi
  Future<void> _addDrink() async {
    if (_currentAmount <= 0) return;

    final waterProvider = Provider.of<WaterProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final achievementProvider = Provider.of<AchievementProvider>(context, listen: false);

    final water = DrinkData.getDrinks().firstWhere((d) => d.id == 'water');
    final result = await waterProvider.drink(water, _currentAmount, context: context);

    if (!mounted) return;

    if (result.success) {
      await userProvider.addToTotalWater(_currentAmount * water.hydrationFactor);

      if (!mounted) return;
      
      // Su ekleme başarı bildirimi
      final formattedAmount = UnitConverter.formatVolume(_currentAmount, userProvider.isMetric);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💦', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$formattedAmount su başarıyla eklendi!',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.softPinkButton,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );

      if (result.isFirstDrink) {
        final coins = await achievementProvider.checkFirstStep();
        if (coins > 0) {
          await waterProvider.addCoins(coins);
          await userProvider.addAchievement('first_step');
        }
      }

      if (!mounted) return;

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

      if (!mounted) return;

      final totalWater = userProvider.userData.totalWaterConsumed;
      final wasWaterMasterUnlocked = achievementProvider.isAchievementUnlocked('water_master');
      final waterMasterCoins = await achievementProvider.checkWaterMaster(totalWater);
      if (waterMasterCoins > 0 && !wasWaterMasterUnlocked) {
        await waterProvider.addCoins(waterMasterCoins);
        await userProvider.addAchievement('water_master');
      }

      if (!mounted) return;

      final consecutiveDays = userProvider.consecutiveDays;
      final wasStreak3Unlocked = achievementProvider.isAchievementUnlocked('streak_3');
      final streak3Coins = await achievementProvider.checkStreak3(consecutiveDays);
      if (streak3Coins > 0 && !wasStreak3Unlocked) {
        await waterProvider.addCoins(streak3Coins);
        await userProvider.addAchievement('streak_3');
      }

      if (!mounted) return;

      final wasStreak7Unlocked = achievementProvider.isAchievementUnlocked('streak_7');
      final streak7Coins = await achievementProvider.checkStreak7(consecutiveDays);
      if (streak7Coins > 0 && !wasStreak7Unlocked) {
        await waterProvider.addCoins(streak7Coins);
        await userProvider.addAchievement('streak_7');
      }

      if (!mounted) return;
      
      // Şanslı Yudum ve diğer bonus bildirimleri
      if (result.isLuckyDrink) {
        // Şanslı Yudum bildirimi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Şanslı Yudum! +10 Coin kazandın! 🍀',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.amber.shade700,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
      if (result.isEarlyBird) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erken Kuş Bonusu! +5 Coin 🌅'),
            backgroundColor: Colors.orange.shade400,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      if (result.isNightOwl) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gece Kuşu Bonusu! +5 Coin 🌙'),
            backgroundColor: Colors.indigo.shade400,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      if (result.isDailyGoalBonus) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Günlük Hedefe Ulaşıldı! +15 Coin 🎯'),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      // Son eklenen miktarı kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_added_amount', _currentAmount);
      
      if (!mounted) return;
      Navigator.pop(context, _currentAmount); // Son eklenen miktarı döndür
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              
              // Başlık Satırı - Sadeleştirilmiş (Sadece "Su" başlığı, gereksiz ikonlar yok)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Su',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A5568),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),

              // Görsel Bardak - Sürükle-Doldur
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Kullanıcı dokundu, el animasyonunu gizle
                          if (!_hasInteracted) {
                            _hideHandAnimation();
                          }
                        },
                        onVerticalDragUpdate: _onVerticalDragUpdate,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _buildCupWidget(),
                            // Öğretici el animasyonu - Suyun tam ortasında, pulse + yukarı-aşağı
                            Visibility(
                              visible: _showTutorial && !_hasInteracted,
                              child: AnimatedBuilder(
                                animation: _handAnimation,
                                builder: (context, child) {
                                  // Pulse animasyonu (büyüyüp küçülme)
                                  final scale = 0.8 + (_handAnimation.value * 0.4); // 0.8 - 1.2 arası
                                  // Hafif yukarı-aşağı hareket
                                  final verticalOffset = math.sin(_handAnimation.value * 2 * math.pi) * 15;
                                  
                                  return Positioned(
                                    // Suyun tam ortasında konumlandır (bardağın ortası)
                                    // cupWidth = 200, cupHeight = 300
                                    top: 300 * 0.4, // Bardağın ortası (120px)
                                    left: 200 * 0.5 - 24, // Merkez (ikon genişliği 48, yarısı 24)
                                    child: Transform.translate(
                                      offset: Offset(0, verticalOffset),
                                      child: Transform.scale(
                                        scale: scale,
                                        child: Icon(
                                          Icons.touch_app, // Parmak ikonu
                                          size: 48,
                                          color: Colors.white.withValues(alpha: 0.9), // Yarı saydam beyaz
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Şablon Slider - Yatay Kaydırılabilir
              _buildTemplateSlider(),

              const SizedBox(height: 16),

              // Özel Miktar TextField - Template butonlarıyla aynı tasarım
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildAmountPanel(),
              ),

              const SizedBox(height: 16),

              // +Su Butonu
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: ElevatedButton(
                  onPressed: _currentAmount > 0 ? () {
                    _addDrink();
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.softPinkButton,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '+Su',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Görsel Bardak Widget'ı - Temiz ve hatasız Stack yapısı
  Widget _buildCupWidget() {
    const double cupBorderRadius = 30.0;
    const double cupBorderWidth = 3.0;
    const double cupWidth = 200.0;
    const double cupHeight = 300.0;
    
    return Container(
      width: cupWidth,
      height: cupHeight,
      decoration: BoxDecoration(
        color: Colors.white, // Bardağın arka plan rengi
        borderRadius: BorderRadius.circular(cupBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge, // KRİTİK: Suyun köşelerden taşmasını engeller
      child: Stack(
        children: [
          // KATMAN 1 (EN ALT): Su Animasyonu
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedBuilder(
              animation: Listenable.merge([_waveAnimation, _bubbleAnimation]),
              builder: (context, child) {
                // Hazır buton seçiliyse %85 sabit, manuel sürükleme ise dinamik
                double waterHeight;
                if (_selectedTemplateAmount != null) {
                  // Hazır buton seçili - hesaplama yapmadan direkt %85
                  waterHeight = cupHeight * 0.85;
                } else {
                  // Manuel ayar - dinamik yükseklik
                  waterHeight = cupHeight * _fillPercentage;
                }
                
                if (waterHeight <= 0) {
                  return const SizedBox.shrink();
                }
                
                // Hazır buton seçildiğinde su seviyesi %85, manuel sürüklemede dinamik
                // WaveWidget'ta heightPercentages ters çalışır (1.0 = boş, 0.0 = dolu)
                // Su %85 doluyken, dalga katmanları üst yüzeyde olmalı
                final isPresetSelected = _selectedTemplateAmount != null;
                final heightPercentages = isPresetSelected
                    ? const [0.12, 0.15] // Hazır buton: Su bardağın %85'ine kadar dolu (dalga üst yüzeyde)
                    : [
                        0.20 - (_fillPercentage * 0.15), // Manuel: Dinamik seviye
                        0.25 - (_fillPercentage * 0.20),
                      ];
                
                return SizedBox(
                  width: cupWidth,
                  height: waterHeight,
                  child: WaveWidget(
                    config: CustomConfig(
                      gradients: [
                        [
                          const Color(0xFFB3E5FC), // Soft mavi
                          const Color(0xFF81D4FA), // Soft mavi
                        ],
                        [
                          const Color(0xFFB3E5FC).withValues(alpha: 0.9),
                          const Color(0xFF81D4FA).withValues(alpha: 0.8),
                        ],
                      ],
                      durations: const [4000, 5000],
                      heightPercentages: heightPercentages,
                    ),
                    waveAmplitude: 8.0, // Biraz daha belirgin dalga
                    waveFrequency: 1.5,
                    backgroundColor: Colors.transparent, // Sabit açık mavi alanı kaldır - sadece dalga görünsün
                    size: Size(cupWidth, waterHeight),
                  ),
                );
              },
            ),
          ),
          
          // KATMAN 2 (ORTA): Metin/İkon (varsa) - Şimdilik boş
          
          // KATMAN 3 (EN ÜST): Bardak Çerçevesi
          Container(
            width: cupWidth,
            height: cupHeight,
            decoration: BoxDecoration(
              color: Colors.transparent, // Şeffaf içerik
              borderRadius: BorderRadius.circular(cupBorderRadius),
              border: Border.all(
                color: AppColors.softPinkButton.withValues(alpha: 0.3),
                width: cupBorderWidth,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Şablon Slider Widget'ı
  Widget _buildTemplateSlider() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return SizedBox(
          height: 60,
          child: Row(
            children: [
              // Template butonları
              Expanded(
                child: ListView.builder(
                  controller: _templateScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _templateAmounts.length,
                  itemBuilder: (context, index) {
                    final amount = _templateAmounts[index];
                    // Birime göre gösterim: isMetric true ise ml, false ise oz
                    // Oz hesaplama: targetMl * 0.033814 (kullanıcının istediği formül)
                    final displayText = userProvider.isMetric
                        ? '${amount.toStringAsFixed(0)} ml'
                        : '${(amount * 0.033814).toStringAsFixed(1)} oz';
                    // Seçili öğe kontrolü - sadece buton tıklandığında aktif (manuel drag sırasında aktif olmamalı)
                    final isSelected = _selectedTemplateAmount == amount;

                    return GestureDetector(
                      onTap: () {
                        _selectTemplateAmount(amount);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.black
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            displayText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Miktar Paneli Widget'ı - TextField ile (Template butonlarıyla aynı tasarım)
  Widget _buildAmountPanel() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final unitLabel = userProvider.isMetric ? 'ml' : 'oz';
        // TextField'ın focus durumunu kontrol et
        final hasFocus = _amountFocusNode.hasFocus;
        final hasValue = _amountController.text.isNotEmpty && _amountController.text != '0';
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
            boxShadow: hasFocus || hasValue
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: _amountController,
            focusNode: _amountFocusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              letterSpacing: 0.5,
            ),
              decoration: InputDecoration(
              hintText: userProvider.isMetric ? 'Miktar (ml)' : 'Miktar (oz)',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              suffixText: unitLabel,
              suffixStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            onChanged: (value) {
              // TextField değişikliğini işle - global birim ayarına göre
              // Manuel giriş yapıldığında hazır buton seçimini iptal et
              if (value.isEmpty) {
                setState(() {
                  _currentAmount = 0.0;
                  _selectedTemplateAmount = null; // Manuel giriş moduna geç
                });
                return;
              }
              
              final numValue = double.tryParse(value);
              if (numValue != null && numValue >= 0) {
                // Display değerinden ml'ye çevir (global birim ayarına göre)
                double newAmount;
                if (!userProvider.isMetric) {
                  // oz ise ml'ye çevir: oz / 0.033814 = ml (ters işlem)
                  newAmount = numValue / 0.033814;
                } else {
                  newAmount = numValue;
                }
                
                // Maksimum sınırı kontrol et
                final maxMl = _selectedTemplateMax ?? 1000.0;
                newAmount = newAmount.clamp(0.0, maxMl);
                
                if ((_currentAmount - newAmount).abs() > 0.1) {
                  setState(() {
                    _currentAmount = newAmount;
                    _selectedTemplateAmount = null; // Manuel giriş moduna geç
                  });
                }
              }
            },
            onSubmitted: (value) {
              // Klavye kapandığında veya onaylandığında focus'u kaldır
              _amountFocusNode.unfocus();
            },
          ),
        );
      },
    );
  }
}

// Bardak dalga animasyonu için CustomPainter - Gerçekçi dalgalı su
class CupWavePainter extends CustomPainter {
  final double waveOffset;
  final double fillPercentage;

  CupWavePainter({
    required this.waveOffset,
    required this.fillPercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPercentage <= 0) return;

    // Su dolgusunu çiz - dalgalı üst yüzey ile
    final waterPaint = Paint()
      ..color = AppColors.waterColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    // Gradient için başka bir paint
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.waterColor.withValues(alpha: 0.9),
        AppColors.waterColor.withValues(alpha: 0.7),
      ],
    );

    // Dalgalı üst yüzey path'i - Wave paketi parametreleri (waveAmplitude: 5.0, waveFrequency: 1.5)
    final path = Path();
    final waveHeight = 5.0; // waveAmplitude: 5.0
    final waveFrequency = 1.5; // waveFrequency: 1.5

    // Sol alt köşe
    path.moveTo(0, size.height);

    // Alt kenar (düz)
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);

    // Üst kenar (dalgalı)
    for (double x = size.width; x >= 0; x -= 1.0) {
      final y = waveHeight * math.sin((x / size.width * waveFrequency * 2 * math.pi) + waveOffset);
      path.lineTo(x, y);
    }

    path.close();

    // Gradient ile doldur
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final shader = gradient.createShader(rect);
    waterPaint.shader = shader;
    
    canvas.drawPath(path, waterPaint);

    // Üst yüzeyde parlaklık efekti (beyaz çizgi)
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final highlightPath = Path();
    for (double x = 0; x <= size.width; x += 1.0) {
      final y = waveHeight * math.sin((x / size.width * waveFrequency * 2 * math.pi) + waveOffset);
      if (x == 0) {
        highlightPath.moveTo(x, y);
      } else {
        highlightPath.lineTo(x, y);
      }
    }
    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(CupWavePainter oldDelegate) {
    return oldDelegate.waveOffset != waveOffset ||
        oldDelegate.fillPercentage != fillPercentage;
  }
}

// Şeffaf kabarcık animasyonu için CustomPainter
class BubblePainter extends CustomPainter {
  final double bubbleOffset;
  final double fillPercentage;

  BubblePainter({
    required this.bubbleOffset,
    required this.fillPercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPercentage <= 0) return;

    final random = math.Random(42); // Sabit seed ile tutarlı kabarcıklar
    final bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    // Kabarcık sayısı su seviyesine göre değişir
    final bubbleCount = (fillPercentage * 15).round();

    for (int i = 0; i < bubbleCount; i++) {
      // X pozisyonu rastgele ama tutarlı
      final xSeed = random.nextDouble() * 1000 + i * 100;
      final x = (xSeed % size.width).toDouble();

      // Y pozisyonu animasyonla yukarı hareket eder
      final startY = size.height * (0.7 + random.nextDouble() * 0.3); // Alt %30'dan başlar
      final bubbleProgress = (bubbleOffset + (i * 0.15)) % 1.0; // Her kabarcık farklı hızda
      final y = startY - (bubbleProgress * size.height * 0.8); // %80 yukarı çıkar

      // Eğer kabarcık ekranın dışındaysa atla
      if (y < 0 || y > size.height) continue;

      // Kabarcık boyutu
      final bubbleSize = 3.0 + random.nextDouble() * 5.0;

      // Ana kabarcık
      canvas.drawCircle(Offset(x, y), bubbleSize, bubblePaint);

      // Küçük parlaklık (gözbebeği efekti)
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(x - bubbleSize * 0.3, y - bubbleSize * 0.3),
        bubbleSize * 0.3,
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(BubblePainter oldDelegate) {
    return oldDelegate.bubbleOffset != bubbleOffset ||
        oldDelegate.fillPercentage != fillPercentage;
  }
}
