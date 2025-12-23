import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../providers/water_provider.dart';
import '../providers/aquarium_provider.dart';
import '../providers/user_provider.dart';
import '../providers/achievement_provider.dart';
import '../models/achievement_model.dart';
import '../models/decoration_item.dart';
import '../widgets/interactive_cup_modal.dart';
import '../widgets/challenge_card.dart';
import '../providers/drink_provider.dart';
import '../models/drink_model.dart';
import 'drink_gallery_screen.dart';
import 'success_screen.dart';

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
  late DraggableScrollableController _challengeSheetController;
  
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
    _challengeSheetController.dispose();
    super.dispose();
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
        
        return Stack(
          children: [
            // Ana içerik - ScrollView
            SingleChildScrollView(
            child: Column(
              children: [
              // Üst Bar: Sol - Günlük Seri Butonu, Sağ - Coin Butonu (spaceBetween ile hizalı)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Sol: Günlük Seri Butonu (Dairesel + Progress Ring)
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SuccessScreen(),
                          ),
                        );
                        
                        // Eğer 'open_challenges_panel' döndüyse, mücadele panelini aç
                        if (result == 'open_challenges_panel' && mounted) {
                          _challengeSheetController.animateTo(
                            0.85,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Progress Ring (Günlük hedefe göre dolan)
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                value: progressPercentage / 100,
                                strokeWidth: 4,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.softPinkButton,
                                ),
                              ),
                            ),
                            // İçerideki Dairesel Buton
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
                          ],
                        ),
                      ),
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
              
              // Merkezi Metin: Akvaryumun üstünde ortalanmış
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    '${consumedAmount.toStringAsFixed(0)} ml İçildi',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: AppColors.softPinkButton,
                      letterSpacing: 0.3,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Fanus ve Yan Bilgileri (Row içinde)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Sol Taraf: Yüzde Göstergesi
                  SizedBox(
                    width: 60,
                    child: Text(
                      '%${progressPercentage.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Yuvarlak Fanus Tank Tasarımı - Büyütülmüş Boyut, RepaintBoundary ile Optimize
                  RepaintBoundary(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.65,
                      height: MediaQuery.of(context).size.width * 0.65, // Ekranın %65'i (büyütüldü)
                      child: Stack(
                    alignment: Alignment.center,
                    children: [
                    // Dış Çerçeve - Kalın Border ile Yuvarlak Fanus
                Container(
                      width: MediaQuery.of(context).size.width * 0.65,
                      height: MediaQuery.of(context).size.width * 0.65,
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
                      
                      // Su Seviyesi - ClipOval ile Taşma Önleme, RepaintBoundary ile Optimize
                      RepaintBoundary(
                        child: ClipOval(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.65,
                            height: MediaQuery.of(context).size.width * 0.65,
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
                                        final waterHeight = MediaQuery.of(context).size.width * 0.65 * fillPercentage;
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
                                              MediaQuery.of(context).size.width * 0.65,
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
                      ),
                      
                      // Modüler dekorasyonlar - Yuvarlak tank için optimize edilmiş
                      ...decorations.map((decoration) {
                        return _buildCircularDecoration(
                          decoration,
                          MediaQuery.of(context).size.width * 0.65,
                        );
                      }),
                    ],
                  ),
                ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Sağ Taraf: Birim Göstergesi
                  FutureBuilder<String>(
                    future: SharedPreferences.getInstance().then((prefs) => prefs.getString('preferred_unit') ?? 'ml'),
                    builder: (context, snapshot) {
                      final unit = snapshot.data ?? 'ml';
                      return SizedBox(
                        width: 60,
                        child: Text(
                          unit.toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
            ),
          );
        },
      ),
                ],
              ),
              
              // Fanus Altı: Günlük Hedef (Ortalanmış)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Günlük Hedef: ${(dailyGoal / 1000.0).toStringAsFixed(1)} L',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 2), // Tanka daha yakın
              
              // Dinamik Hızlı Erişim Barı - Yatayda Kaydırılabilir
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Consumer<DrinkProvider>(
                  builder: (context, drinkProvider, child) {
                    final quickAccessDrinks = drinkProvider.quickAccessDrinks;
                    
                    // Ana Üçlü Grup Widget'ı (Merkezde) - Yeni Sıralama: Menü (Sol) | Su (Merkez, Mavi, Büyük) | İçecek Ekle (Sağ, Çikolatalı Süt +)
                    final mainButtonGroup = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // En Sol: Menü Butonu (Izgara/Dalga ikonu)
                        GestureDetector(
                          onTap: () {
                            if (!mounted) return;
                            _showDrinkSelector(context, waterProvider, userProvider, achievementProvider);
                          },
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.grid_view, // Izgara ikonu
                              color: AppColors.softPinkButton,
                              size: 30,
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 20),
                        
                        // Merkez: Su İçme Butonu (Mavi, En Büyük)
                        Stack(
                          alignment: Alignment.center,
                          children: [
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
                            // Üstte geçici etiket (sadece su eklendikten sonra görünür)
                            Positioned(
                              top: -20,
                              child: FutureBuilder<Map<String, dynamic>>(
                                future: _getLastAddedAmountWithUnit(),
                                builder: (context, snapshot) {
                                  final data = snapshot.data;
                                  if (data != null) {
                                    final amount = data['amount'];
                                    final unit = data['unit'] as String;
                                    final hasAmount = amount != null && (amount as num) > 0;
                                    
                                    if (hasAmount) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.waterColor.withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '+${(amount as double).toStringAsFixed(unit == 'oz' ? 1 : 0)} $unit',
                                          style: const TextStyle(
                                            fontSize: 11,
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
                            ),
                          ],
                        ),
                        
                        const SizedBox(width: 20),
                        
                        // Sağ: İçecek Ekleme Butonu (Çikolatalı Süt Kutusu + Küçük + İşareti)
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
                                child: Icon(
                                  Icons.local_drink, // Çikolatalı süt kutusu için uygun ikon
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
                                  decoration: BoxDecoration(
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
                    
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = constraints.maxWidth;
                        // Ana üçlü grubun genişliği: Menü(60) + 20 + Su(72) + 20 + Ekle(60) = 232
                        final mainGroupWidth = 60.0 + 20.0 + 72.0 + 20.0 + 60.0;
                        
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: false,
                          child: Row(
                            children: [
                              // Sol boşluk - Ana üçlü grubu merkeze hizalamak için
                              SizedBox(
                                width: (screenWidth - mainGroupWidth) / 2,
                              ),
                              
                              // Ana Üçlü Grup (Merkezde - Ana Üs)
                              mainButtonGroup,
                              
                              // Hızlı Erişim İçecekleri (Ana üçlü grubun sağından başlar)
                              if (quickAccessDrinks.isNotEmpty) const SizedBox(width: 12),
                              
                              ...quickAccessDrinks.map((drink) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: GestureDetector(
                                    onTap: () {
                                      if (!mounted) return;
                                      // Modal açılmadan varsayılan miktarı ekle
                                      _addQuickAccessDrink(drink, waterProvider, userProvider, achievementProvider);
                                    },
                                    child: CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        _getDrinkIcon(drink.id),
                                        color: _getDrinkColor(drink.id),
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              
                              // Sağ boşluk - Ana üçlü grubu merkeze hizalamak için
                              SizedBox(
                                width: (screenWidth - mainGroupWidth) / 2,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Scroll Göstergesi (Animasyonlu)
              _buildScrollIndicator(),
              
              // Alt boşluk - DraggableScrollableSheet için yer
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            ],
          ),
        ),
        
        // DraggableScrollableSheet - Mücadele Kartları (Peek Height)
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
                      child: _buildDailyChallengesContent(
                        waterProvider,
                        userProvider,
                        achievementProvider,
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
    // İlk su içiş kontrolü için önceki değeri kaydet
    final previousConsumedAmount = waterProvider.consumedAmount;
    
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
      
      // İlk Bardak başarısı kontrolü
      final currentConsumedAmount = waterProvider.consumedAmount;
      
      // Eğer önceki değer 0 idi ve şimdi > 0 ise, ilk su içildi
      if (previousConsumedAmount == 0.0 && currentConsumedAmount > 0.0) {
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
                    if (mounted) {
                      setState(() {}); // UI'ı güncelle (coin miktarı için)
                    }
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
    return Column(
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
        
        // Pokemon Kartı Tarzı Mücadeleler
        ...ChallengeData.getChallenges().where((challenge) => challenge.id != 'first_cup').map((challenge) {
          // Mücadele durumunu hesapla
          Challenge updatedChallenge = challenge;
          
          // İlk Bardak artık başarı olarak işleniyor, mücadeleler listesinde yok
          
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
              progressText: '${(waterProvider.consumedAmount / 1000.0).toStringAsFixed(1)}/${(waterProvider.dailyGoal / 1000.0).toStringAsFixed(1)}L',
            );
          }
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ChallengeCard(
              challenge: updatedChallenge,
            ),
          );
        }),
        
        const SizedBox(height: 20),
      ],
    );
  }


  // Hızlı erişim içecek ekleme fonksiyonu (kaydedilmiş miktar ile)
  Future<void> _addQuickAccessDrink(
    Drink drink,
    WaterProvider waterProvider,
    UserProvider userProvider,
    AchievementProvider achievementProvider,
  ) async {
    // Hızlı erişim içecek için kaydedilmiş miktarı al (varsayılan: 200ml)
    final drinkProvider = Provider.of<DrinkProvider>(context, listen: false);
    final amount = drinkProvider.getQuickAccessAmount(drink.id);
    
    final result = await waterProvider.drink(drink, amount);
    
    if (!mounted) return;
    
    if (result.success) {
      // Hidrasyon faktörüne göre efektif miktarı ekle
      final effectiveAmount = amount * drink.hydrationFactor;
      await userProvider.addToTotalWater(effectiveAmount);
      
      if (!mounted) return;
      
      // Başarı kontrolü
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
      
      // Başarı mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${drink.name} eklendi! (${amount.toStringAsFixed(0)}ml)',
          ),
          backgroundColor: AppColors.softPinkButton,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // İçecek ikonu getir
  IconData _getDrinkIcon(String drinkId) {
    switch (drinkId) {
      case 'water':
        return Icons.water_drop;
      case 'mineral_water':
        return Icons.water;
      case 'coffee':
        return Icons.local_cafe;
      case 'tea':
        return Icons.emoji_food_beverage;
      case 'herbal_tea':
      case 'green_tea':
        return Icons.eco;
      case 'cold_tea':
        return Icons.emoji_food_beverage;
      case 'lemonade':
        return Icons.local_drink;
      case 'iced_coffee':
        return Icons.local_cafe;
      case 'ayran':
      case 'kefir':
        return Icons.liquor;
      case 'milk':
        return Icons.local_drink;
      case 'juice':
      case 'fresh_juice':
        return Icons.local_drink;
      case 'smoothie':
        return Icons.blender;
      case 'sports':
        return Icons.fitness_center;
      case 'protein_shake':
        return Icons.sports_gymnastics;
      case 'coconut_water':
        return Icons.water_drop;
      case 'soda':
        return Icons.sports_bar;
      case 'energy_drink':
        return Icons.bolt;
      case 'detox_water':
        return Icons.spa;
      default:
        return Icons.local_drink;
    }
  }

  // İçecek rengi getir
  Color _getDrinkColor(String drinkId) {
    switch (drinkId) {
      case 'water':
        return Colors.blue;
      case 'mineral_water':
        return const Color(0xFF4A9ED8);
      case 'coffee':
        return Colors.brown;
      case 'tea':
        return Colors.green;
      case 'herbal_tea':
        return const Color(0xFF6B8E23);
      case 'green_tea':
        return const Color(0xFF228B22);
      case 'cold_tea':
        return const Color(0xFF8B7355);
      case 'lemonade':
        return const Color(0xFFFFD700);
      case 'iced_coffee':
        return const Color(0xFF8B4513);
      case 'ayran':
        return const Color(0xFFF5F5DC);
      case 'kefir':
        return const Color(0xFFFFE4B5);
      case 'milk':
        return Colors.white70;
      case 'juice':
        return Colors.orange;
      case 'smoothie':
        return const Color(0xFFFF6347);
      case 'fresh_juice':
        return const Color(0xFFFF8C00);
      case 'sports':
        return Colors.cyan;
      case 'protein_shake':
        return const Color(0xFF9370DB);
      case 'coconut_water':
        return const Color(0xFFDEB887);
      case 'soda':
        return Colors.red;
      case 'energy_drink':
        return const Color(0xFFFF1493);
      case 'detox_water':
        return const Color(0xFF98D8C8);
      default:
        return AppColors.softPinkButton;
    }
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
