import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/app_colors.dart';
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
  String _preferredUnit = 'ml';
  bool _isLoading = true;
  List<double> _favoriteAmounts = []; // Favori miktarlar (ml cinsinden)
  double? _selectedTemplateMax; // Seçili şablonun maksimum kapasitesi
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  final ScrollController _templateScrollController = ScrollController();
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  bool _isUpdatingFromDrag = false; // Drag'dan gelen güncellemeleri işaretle
  
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
    
    _loadPreferredUnit();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _templateScrollController.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPreferredUnit() async {
    final prefs = await SharedPreferences.getInstance();
    final unit = prefs.getString('preferred_unit') ?? 'ml';
    final favoritesJson = prefs.getString('favorite_amounts');
    List<double> favorites = [];
    if (favoritesJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(favoritesJson);
        favorites = decoded.map((e) => (e as num).toDouble()).toList();
      } catch (e) {
        favorites = [];
      }
    }
    setState(() {
      _preferredUnit = unit;
      _favoriteAmounts = favorites;
      _currentAmount = 250.0; // 250 ile başla
      _amountController.text = _convertToDisplay(_currentAmount).toStringAsFixed(unit == 'oz' ? 1 : 0);
      _isLoading = false;
    });
    
    // İlk yüklemede şablon slider'ı merkeze getir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedTemplate();
    });
    
    // TextField değişikliklerini dinle
    _amountController.addListener(_onAmountTextChanged);
  }
  
  void _onAmountTextChanged() {
    // Eğer drag'dan gelen bir güncelleme ise, listener'ı atla
    if (_isUpdatingFromDrag) return;
    
    final text = _amountController.text;
    if (text.isEmpty) {
      setState(() {
        _currentAmount = 0.0;
      });
      return;
    }
    
    final value = double.tryParse(text);
    if (value != null && value >= 0) {
      // Display değerinden ml'ye çevir
      double newAmount;
      if (_preferredUnit == 'oz') {
        newAmount = value * 29.5735;
      } else {
        newAmount = value;
      }
      
      // Maksimum sınırı kontrol et
      final maxMl = _selectedTemplateMax ?? 1000.0;
      newAmount = newAmount.clamp(0.0, maxMl);
      
      if ((_currentAmount - newAmount).abs() > 0.1) {
        setState(() {
          _currentAmount = newAmount;
        });
      }
    }
  }

  Future<void> _saveFavoriteAmounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorite_amounts', jsonEncode(_favoriteAmounts));
  }

  bool get _isFavorite {
    if (_currentAmount <= 0) return false;
    return _favoriteAmounts.contains(_currentAmount);
  }

  void _toggleFavorite() {
    setState(() {
      if (_isFavorite) {
        _favoriteAmounts.remove(_currentAmount);
      } else {
        if (_currentAmount > 0) {
          _favoriteAmounts.add(_currentAmount);
          _favoriteAmounts.sort();
        }
      }
      _saveFavoriteAmounts();
    });
  }

  void _selectTemplateAmount(double amount) {
    setState(() {
      _selectedTemplateMax = amount; // Maksimum kapasiteyi şablon miktarına ayarla
      _currentAmount = amount.clamp(0.0, amount);
      // TextField'ı güncelle (listener'ı atlamak için flag kullan)
      final displayValue = _convertToDisplay(_currentAmount);
      _isUpdatingFromDrag = true;
      _amountController.text = displayValue.toStringAsFixed(_preferredUnit == 'oz' ? 1 : 0);
      _isUpdatingFromDrag = false;
    });
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

  // Birim dönüşümü
  double _convertToDisplay(double ml) {
    if (_preferredUnit == 'oz') {
      return ml / 29.5735; // ml'den oz'ye çevir
    }
    return ml;
  }

  // Maksimum sınır - Seçili şablon miktarına göre
  double get _maxAmount {
    // Eğer şablon seçildiyse, o miktarı kullan
    if (_selectedTemplateMax != null) {
      return _preferredUnit == 'oz' 
          ? _selectedTemplateMax! / 29.5735 
          : _selectedTemplateMax!;
    }
    // Varsayılan maksimum
    return _preferredUnit == 'oz' ? 34.0 : 1000.0;
  }

  // Drag işlemi - Artırılmış hassasiyet
  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      // Yukarı kaydırma = artır, aşağı kaydırma = azalt
      // Hassasiyeti artırmak için delta'yı 2.5 ile çarp
      final delta = -details.delta.dy * 2.5; // 2.5x hassasiyet çarpanı
      
      // 10'ar 10'ar artış için hassasiyet ayarı
      double stepSize;
      if (_preferredUnit == 'oz') {
        stepSize = 0.3; // oz için yaklaşık 10ml karşılığı
      } else {
        stepSize = 10.0; // ml için 10'ar 10'ar
      }
      
      // Delta'yı step size'a göre yuvarla (daha az hareketle tepki vermek için)
      final steps = (delta / 15.0).round(); // Her 15px drag = 1 step (daha hassas)
      final deltaAmount = steps * stepSize;
      
      // Display değerini güncelle
      final currentDisplay = _convertToDisplay(_currentAmount);
      final newDisplay = (currentDisplay + deltaAmount).clamp(0.0, _maxAmount);
      
      // ml'ye geri çevir ve 10'un katına yuvarla
      if (_preferredUnit == 'oz') {
        _currentAmount = (newDisplay * 29.5735).roundToDouble();
      } else {
        _currentAmount = newDisplay.roundToDouble();
      }
      
      // 10'un katına yuvarla (240, 250, 260 gibi)
      _currentAmount = (_currentAmount / 10).round() * 10.0;
      
      // Maksimum ml sınırını kontrol et - Seçili şablon miktarına göre
      final maxMl = _selectedTemplateMax ?? 1000.0;
      _currentAmount = _currentAmount.clamp(0.0, maxMl);
      
      // TextField'ı güncelle (listener'ı atlamak için flag kullan)
      final displayValue = _convertToDisplay(_currentAmount);
      final newText = displayValue.toStringAsFixed(_preferredUnit == 'oz' ? 1 : 0);
      if (_amountController.text != newText) {
        _isUpdatingFromDrag = true;
        _amountController.text = newText;
        _isUpdatingFromDrag = false;
      }
    });
    
    // Şablon slider'ı güncelle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedTemplate();
    });
  }

  // Su seviyesi yüzdesi - Seçili şablon miktarına göre
  double get _fillPercentage {
    final maxMl = _selectedTemplateMax ?? 1000.0;
    if (maxMl <= 0) return 0.0;
    return _currentAmount / maxMl;
  }

  // Su ekleme işlemi
  Future<void> _addDrink() async {
    if (_currentAmount <= 0) return;

    final waterProvider = Provider.of<WaterProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final achievementProvider = Provider.of<AchievementProvider>(context, listen: false);

    final water = DrinkData.getDrinks().firstWhere((d) => d.id == 'water');
    final result = await waterProvider.drink(water, _currentAmount);

    if (!mounted) return;

    if (result.success) {
      await userProvider.addToTotalWater(_currentAmount * water.hydrationFactor);

      if (!mounted) return;

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
      
      // Son eklenen miktarı ve birimi kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_added_amount', _currentAmount);
      await prefs.setString('preferred_unit', _preferredUnit);
      
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

    return Container(
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

          // Görsel Bardak - Sürükle-Doldur
          Expanded(
            child: Center(
              child: GestureDetector(
                onVerticalDragUpdate: _onVerticalDragUpdate,
                child: _buildCupWidget(),
              ),
            ),
          ),

          // Şablon Slider - Yatay Kaydırılabilir
          _buildTemplateSlider(),

          const SizedBox(height: 16),

          // Miktar Paneli - Yanıp Sönen İmleç ve Birim
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildAmountPanel(),
          ),

          const SizedBox(height: 16),

          // +Su Butonu
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: ElevatedButton(
              onPressed: _currentAmount > 0 ? _addDrink : null,
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
    );
  }

  // Görsel Bardak Widget'ı - Gerçekçi form ve taşma önleme
  Widget _buildCupWidget() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 200,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppColors.softPinkButton.withValues(alpha: 0.3),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Su seviyesi (dalgalı ve animasyonlu) - ClipRRect ile taşma önleme
            if (_fillPercentage > 0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _waveAnimation,
                  builder: (context, child) {
                    final waterHeight = 300 * _fillPercentage;
                    return ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(27),
                        bottomRight: Radius.circular(27),
                      ),
                      child: CustomPaint(
                        size: Size(200, waterHeight),
                        painter: CupWavePainter(
                          waveOffset: _waveAnimation.value,
                          fillPercentage: _fillPercentage,
                        ),
                        child: Container(
                          height: waterHeight,
                          decoration: BoxDecoration(
                            color: AppColors.waterColor.withValues(alpha: 0.85),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.waterColor.withValues(alpha: 0.9),
                                AppColors.waterColor.withValues(alpha: 0.7),
                              ],
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
      ),
    );
  }

  // Şablon Slider Widget'ı
  Widget _buildTemplateSlider() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        controller: _templateScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _templateAmounts.length,
        itemBuilder: (context, index) {
          final amount = _templateAmounts[index];
          final displayAmount = _convertToDisplay(amount);
          // Seçili öğe kontrolü - daha hassas tolerans
          final isSelected = (_currentAmount - amount).abs() < 10.0; // 10ml tolerans

          return GestureDetector(
            onTap: () => _selectTemplateAmount(amount),
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
                  '${displayAmount.toStringAsFixed(_preferredUnit == 'oz' ? 1 : 0)} $_preferredUnit',
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
    );
  }

  // Miktar Paneli Widget'ı - TextField ile
  Widget _buildAmountPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Miktar TextField - Ortalanmış
          Expanded(
            child: TextField(
              controller: _amountController,
              focusNode: _amountFocusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4A5568),
                letterSpacing: 0.5,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 20,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: (value) {
                // TextField değişikliği _onAmountTextChanged'da işleniyor
              },
            ),
          ),
          // Birim Göstergesi
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              _preferredUnit,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4A5568),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Favori Yıldızı
          GestureDetector(
            onTap: _toggleFavorite,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isFavorite ? Icons.star : Icons.star_border,
                key: ValueKey(_isFavorite),
                color: _isFavorite
                    ? Colors.amber
                    : Colors.grey[400],
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Bardak dalga animasyonu için CustomPainter - Gerçekçi form
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

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Yumuşak dalga çizgisi (üst kısım) - Gerçekçi dalga efekti
    final path = Path();
    final waveHeight = 6.0;
    final waveFrequency = 2.0; // Dalga sıklığı

    path.moveTo(0, size.height - 5);

    for (double x = 0; x <= size.width; x += 1.0) {
      final y = size.height - 5 +
          waveHeight * math.sin((x / size.width * waveFrequency * 2 * math.pi) + waveOffset);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CupWavePainter oldDelegate) {
    return oldDelegate.waveOffset != waveOffset ||
        oldDelegate.fillPercentage != fillPercentage;
  }
}
