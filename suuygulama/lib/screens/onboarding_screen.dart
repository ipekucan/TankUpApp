import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../utils/unit_converter.dart';
import '../providers/user_provider.dart';
import '../providers/water_provider.dart';
import 'plan_loading_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Form verileri - Başlangıçta boş
  String? _selectedGender;
  int _selectedWeight = 0; // kg veya lbs (birime göre) - Başlangıçta 0
  String? _selectedActivityLevel;
  String? _selectedClimate; // İklim seçimi
  int _weightUnit = 0; // 0 = Kg, 1 = Lbs (CupertinoSlidingSegmentedControl için)
  double? _customGoal; // Özel hedef (ml cinsinden)
  final TextEditingController _goalController = TextEditingController();
  final FocusNode _goalFocusNode = FocusNode();
  
  // PageView Controller
  late PageController _pageController;
  int _currentPage = 0; // 0-4 arası (5 adım)
  
  // Canlı hesaplanan su hedefi
  double get _calculatedWaterGoal {
    // Kilo girilene kadar 0 döndür
    if (_selectedWeight == 0) return 0.0;
    
    // Kilo dönüşümü (Lbs ise Kg'ye çevir) - Varsayılan değerlerle
    final weightInKg = _weightUnit == 1 
        ? (_selectedWeight == 0 ? 70.0 : _selectedWeight * 0.453592)
        : (_selectedWeight == 0 ? 70.0 : _selectedWeight.toDouble());
    
    // Temel formül: 35ml/kg
    double baseGoal = 35.0 * weightInKg;
    
    // Aktivite faktörü
    double activityBonus = 0.0;
    if (_selectedActivityLevel == 'high') {
      activityBonus = 500.0; // Yüksek aktivite için +500ml
    } else if (_selectedActivityLevel == 'medium') {
      activityBonus = 250.0; // Orta aktivite için +250ml
    }
    
    // İklim faktörü
    double climateBonus = 0.0;
    if (_selectedClimate == 'very_hot') {
      climateBonus = 400.0; // Çok sıcak iklim için +400ml
    } else if (_selectedClimate == 'hot') {
      climateBonus = 300.0; // Sıcak iklim için +300ml
    } else if (_selectedClimate == 'warm') {
      climateBonus = 150.0; // Ilıman iklim için +150ml
    }
    // Soğuk iklim için bonus yok
    
    // Toplam hedef
    final idealGoal = baseGoal + activityBonus + climateBonus;
    
    // Minimum 1500ml, maksimum 5000ml
    return idealGoal.clamp(1500.0, 5000.0);
  }
  
  // Picker controller'ları
  late FixedExtentScrollController _weightController;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _weightController = FixedExtentScrollController(initialItem: 0); // Başlangıçta 0 (30 kg)
    
    // Controller'ı dinle ve sadece gerektiğinde setState çağır
    _weightController.addListener(_onWeightChanged);
    
    // Goal focus node listener - focus kaybedildiğinde formatlanmış metni göster
    _goalFocusNode.addListener(() {
      if (!_goalFocusNode.hasFocus && _customGoal != null) {
        setState(() {}); // Formatlanmış metni göstermek için
      }
    });
  }
  
  void _onWeightChanged() {
    if (_weightController.hasClients) {
      final index = _weightController.selectedItem;
      final maxIndex = _weightUnit == 0 ? 170 : 375;
      if (index >= 0 && index <= maxIndex) {
        final newWeight = _weightUnit == 0 
            ? 30 + index
            : 66 + index;
        if (newWeight != _selectedWeight) {
          setState(() {
            _selectedWeight = newWeight;
          });
        }
      }
    }
  }
  
  @override
  void dispose() {
    _weightController.removeListener(_onWeightChanged);
    _weightController.dispose();
    _pageController.dispose();
    _goalController.dispose();
    _goalFocusNode.dispose();
    super.dispose();
  }
  
  // Otomatik Geçiş Fonksiyonu - Seçimi kaydet, sonraki sayfaya geç, progress bar'ı güncelle
  void _nextStep() {
    // Son sayfa değilse bir sonraki sayfaya geç (0-4 = 5 adım)
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      // Progress bar otomatik güncellenir (onPageChanged callback'i sayesinde)
    } else {
      // Son sayfadaysa onboarding'i tamamla
      _completeOnboarding();
    }
  }
  
  // Atla butonu mantığı - Veri doğrulaması yapmadan direkt sonraki sayfaya geç
  void _skipCurrentStep() {
    // Veri doğrulaması yapmadan direkt sonraki sayfaya geç (0-4 = 5 adım)
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Son sayfadaysa onboarding'i tamamla
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    if (!mounted) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final waterProvider = Provider.of<WaterProvider>(context, listen: false);
    
    // Kilo dönüşümü (Lbs ise Kg'ye çevir)
    final weightInKg = _weightUnit == 1 
        ? _selectedWeight * 0.453592 
        : _selectedWeight.toDouble();
    
    // Profil verilerini kaydet
    await userProvider.updateProfile(
      gender: _selectedGender,
      weight: weightInKg,
      activityLevel: _selectedActivityLevel,
    );
    
    // Su hedefini kaydet
    final finalGoal = _customGoal ?? _calculatedWaterGoal;
    await waterProvider.updateDailyGoal(finalGoal);
    
    // Onboarding tamamlandı olarak işaretle
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    if (!mounted) return;
    
    // Progress bar'ı tam doldur (son sayfaya geç)
    setState(() {
      _currentPage = 4; // Son sayfa (0-4 = 5 adım)
    });
    
    // Kısa bir gecikme ile plan loading ekranına yönlendir
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    // Plan Loading ekranına yönlendir
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PlanLoadingScreen(
          customGoal: _customGoal,
        ),
      ),
    );
  }
  



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.verySoftBlue,
      body: SafeArea(
        child: Column(
          children: [
            // Üst Kontrol Paneli - Sabit (Progress Bar + Atla Butonu)
            _buildTopControlPanel(),
            
            // PageView - 5 Adımlı Akış
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                physics: const NeverScrollableScrollPhysics(), // Yatay kaydırmayı devre dışı bırak
                children: [
                  // 1. Adım: Cinsiyet Seçimi
                  _buildGenderStep(),
                  // 2. Adım: Kilo Seçimi
                  _buildWeightStep(),
                  // 3. Adım: Aktivite Seviyesi
                  _buildActivityStep(),
                  // 4. Adım: İklim Seçimi
                  _buildClimateStep(),
                  // 5. Adım: Günlük Hedef
                  _buildGoalStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Üst Kontrol Paneli - Progress Bar + Atla Butonu
  Widget _buildTopControlPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Progress Bar
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ((_currentPage + 1) * 0.20).clamp(0.0, 1.0), // Her adımda %20 artış
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.softPinkButton,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Atla Butonu
          TextButton(
            onPressed: _skipCurrentStep,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Atla',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF4A5568).withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 1. Adım: Cinsiyet Seçimi
  Widget _buildGenderStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Cinsiyet Seçiniz',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: Color(0xFF4A5568),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Kişisel hidrasyon planınızı oluşturmak için cinsiyetinizi seçin',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF4A5568).withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          
          // Yan yana iki dairesel buton
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Erkek Butonu
              _buildGenderButton(
                isSelected: _selectedGender == 'male',
                icon: Icons.person,
                label: 'Erkek',
                onTap: () {
                  setState(() {
                    _selectedGender = 'male';
                  });
                },
              ),
              
              const SizedBox(width: 32),
              
              // Kadın Butonu
              _buildGenderButton(
                isSelected: _selectedGender == 'female',
                icon: Icons.person_outline,
                label: 'Kadın',
                onTap: () {
                  setState(() {
                    _selectedGender = 'female';
                  });
                },
              ),
            ],
          ),
          
          const SizedBox(height: 60),
          
          // İleri Butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedGender != null ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.softPinkButton,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[500],
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 22,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(35),
                ),
                elevation: 0,
              ),
              child: const Text(
                'İleri',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Cinsiyet Butonu Widget'ı
  Widget _buildGenderButton({
    required bool isSelected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected 
              ? AppColors.softPinkButton 
              : Colors.white,
          border: Border.all(
            color: isSelected 
                ? AppColors.softPinkButton 
                : Colors.grey[300]!,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.softPinkButton.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 60,
              color: isSelected 
                  ? Colors.white 
                  : AppColors.softPinkButton,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? Colors.white 
                    : const Color(0xFF4A5568),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 2. Adım: Kilo Seçimi
  Widget _buildWeightStep() {
    // WheelPicker için değerler (30-200 arası)
    final weightValues = List.generate(171, (index) => 30 + index);
    final initialWeightIndex = _selectedWeight > 0 && _selectedWeight >= 30 && _selectedWeight <= 200
        ? _selectedWeight - 30
        : 40; // Varsayılan 70kg
    
    // Controller'ı state'te tutmak yerine, her build'de güncelle
    if (!_weightController.hasClients || _weightController.selectedItem != initialWeightIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_weightController.hasClients && _weightController.selectedItem != initialWeightIndex) {
          _weightController.animateToItem(
            initialWeightIndex,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Kilonuzu Seçiniz',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: Color(0xFF4A5568),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Hidrasyon hedefinizi hesaplamak için kilonuzu girin',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF4A5568).withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          
          // Sol: WheelPicker, Sağ: Birim Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Sol: WheelPicker
              SizedBox(
                width: 120,
                height: 200,
                child: CupertinoPicker(
                  scrollController: _weightController,
                  itemExtent: 50,
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedWeight = weightValues[index];
                    });
                  },
                  children: weightValues.map((weight) {
                    return Center(
                      child: Text(
                        weight.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(width: 32),
              
              // Sağ: Birim Toggle (kg/lb)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // kg Seçeneği
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _weightUnit = 0;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: _weightUnit == 0 ? AppColors.softPinkButton : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Text(
                              'kg',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _weightUnit == 0 ? Colors.white : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // lbs Seçeneği
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _weightUnit = 1;
                              // lbs'ye çevir
                              if (_selectedWeight > 0) {
                                _selectedWeight = (_selectedWeight * 2.20462).round();
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: _weightUnit == 1 ? AppColors.softPinkButton : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Text(
                              'lbs',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _weightUnit == 1 ? Colors.white : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Seçilen değer gösterimi
          Text(
            _selectedWeight > 0 
                ? '$_selectedWeight ${_weightUnit == 0 ? 'kg' : 'lbs'}'
                : 'Seçiniz',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _selectedWeight > 0 
                  ? AppColors.softPinkButton 
                  : Colors.grey[400],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // İleri Butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedWeight > 0 ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.softPinkButton,
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
              child: const Text(
                'İleri',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  // 3. Adım: Aktivite Seviyesi
  Widget _buildActivityStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Aktivite Seviyeniz',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: Color(0xFF4A5568),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Günlük aktivite seviyenizi seçin',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF4A5568).withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          
          // 3 Yatay Dikdörtgen Buton
          Column(
            children: [
              // Düşük Aktivite
              _buildActivityButton(
                title: 'Düşük',
                icon: Icons.directions_walk,
                isSelected: _selectedActivityLevel == 'low',
                onTap: () {
                  setState(() {
                    _selectedActivityLevel = 'low';
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Orta Aktivite
              _buildActivityButton(
                title: 'Orta',
                icon: Icons.directions_run,
                isSelected: _selectedActivityLevel == 'medium',
                onTap: () {
                  setState(() {
                    _selectedActivityLevel = 'medium';
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Yüksek Aktivite
              _buildActivityButton(
                title: 'Yüksek',
                icon: Icons.sports_gymnastics,
                isSelected: _selectedActivityLevel == 'high',
                onTap: () {
                  setState(() {
                    _selectedActivityLevel = 'high';
                  });
                },
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // İleri Butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedActivityLevel != null
                  ? () async {
                      // Provider'a kaydet
                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                      await userProvider.updateProfile(activityLevel: _selectedActivityLevel);
                      // Sonraki sayfaya geç
                      if (mounted) {
                        _nextStep();
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.softPinkButton,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[500],
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 22,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(35),
                ),
                elevation: 0,
              ),
              child: const Text(
                'İleri',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  // Aktivite Butonu Widget'ı
  Widget _buildActivityButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.softPinkButton.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected 
                ? AppColors.softPinkButton 
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.softPinkButton.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Sol: Metin
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? AppColors.softPinkButton 
                    : const Color(0xFF4A5568),
              ),
            ),
            
            // Sağ: İkon
            Icon(
              icon,
              size: 32,
              color: isSelected 
                  ? AppColors.softPinkButton 
                  : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
  
  // 4. Adım: İklim Seçimi
  Widget _buildClimateStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'İklim Seçiniz',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: Color(0xFF4A5568),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Yaşadığınız bölgenin iklim tipini seçin',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF4A5568).withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          
          // 4 Yatay Dikdörtgen Buton
          Column(
            children: [
              // Çok Sıcak
              _buildClimateButton(
                title: 'Çok Sıcak',
                icon: Icons.wb_sunny,
                isSelected: _selectedClimate == 'very_hot',
                onTap: () {
                  setState(() {
                    _selectedClimate = 'very_hot';
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Sıcak
              _buildClimateButton(
                title: 'Sıcak',
                icon: Icons.wb_twilight,
                isSelected: _selectedClimate == 'hot',
                onTap: () {
                  setState(() {
                    _selectedClimate = 'hot';
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Ilıman
              _buildClimateButton(
                title: 'Ilıman',
                icon: Icons.wb_cloudy,
                isSelected: _selectedClimate == 'warm',
                onTap: () {
                  setState(() {
                    _selectedClimate = 'warm';
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Soğuk
              _buildClimateButton(
                title: 'Soğuk',
                icon: Icons.ac_unit,
                isSelected: _selectedClimate == 'cold',
                onTap: () {
                  setState(() {
                    _selectedClimate = 'cold';
                  });
                },
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // İleri Butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedClimate != null ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.softPinkButton,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[500],
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 22,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(35),
                ),
                elevation: 0,
              ),
              child: const Text(
                'İleri',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  // İklim Butonu Widget'ı
  Widget _buildClimateButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.softPinkButton.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected 
                ? AppColors.softPinkButton 
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.softPinkButton.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Sol: Metin
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? AppColors.softPinkButton 
                    : const Color(0xFF4A5568),
              ),
            ),
            
            // Sağ: İkon
            Icon(
              icon,
              size: 32,
              color: isSelected 
                  ? AppColors.softPinkButton 
                  : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
  

  // 5. Adım: Günlük Hedef
  Widget _buildGoalStep() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Bardak sayısını hesapla (_customGoal ml cinsinden)
        int calculateCups() {
          if (_customGoal == null) return 0;
          return (_customGoal! / 200).round();
        }
        
        // Mevcut hedefi birime göre göster (_customGoal her zaman ml cinsinden)
        String getDisplayText() {
          if (_customGoal == null) return '';
          final displayValue = userProvider.isMetric
              ? _customGoal!.toStringAsFixed(0)
              : UnitConverter.mlToFlOz(_customGoal!).toStringAsFixed(1);
          final unit = userProvider.isMetric ? 'ml' : 'oz';
          final cups = calculateCups();
          return ' $displayValue $unit / $cups bardak';
        }
        
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık ve açıklama (en üstte)
              const Text(
                'Günlük Hedef',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF4A5568),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Günlük su hedefinizi girin',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF4A5568).withValues(alpha: 0.7),
                ),
              ),
              
              const Spacer(),
              
              // Ortada geniş, oval TextField (pembe buton gibi) - Dinamik format gösterimi
              GestureDetector(
                onTap: () {
                  _goalFocusNode.requestFocus();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Formatlanmış metin gösterimi (TextField focus'ta değilse veya boşsa)
                      if (!_goalFocusNode.hasFocus || _goalController.text.isEmpty)
                        Text(
                          getDisplayText().isEmpty ? 'Hedefinizi girin' : getDisplayText(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: _customGoal != null ? const Color(0xFF4A5568) : Colors.grey[400],
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      // TextField (sadece sayı girişi için, görünmez veya saydam)
                      Opacity(
                        opacity: _goalFocusNode.hasFocus ? 1.0 : 0.0,
                        child: TextField(
                          controller: _goalController,
                          focusNode: _goalFocusNode,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4A5568),
                            letterSpacing: 0.5,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            hintText: '',
                          ),
                          onChanged: (value) {
                            if (value.isEmpty) {
                              setState(() {
                                _customGoal = null;
                              });
                              return;
                            }
                            
                            // Sadece sayıları al (birim ve bardak metnini temizle)
                            final cleanValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
                            final numValue = double.tryParse(cleanValue);
                            
                            if (numValue != null && numValue >= 0) {
                              // Display değerinden ml'ye çevir (global birim ayarına göre)
                              double newGoal;
                              if (userProvider.isMetric) {
                                newGoal = numValue;
                              } else {
                                newGoal = UnitConverter.flOzToMl(numValue);
                              }
                              
                              setState(() {
                                _customGoal = newGoal;
                              });
                              
                              // TextField'ı temiz tut (sadece sayı)
                              if (_goalController.text != cleanValue) {
                                _goalController.value = TextEditingValue(
                                  text: cleanValue,
                                  selection: TextSelection.collapsed(offset: cleanValue.length),
                                );
                              }
                            }
                          },
                          onSubmitted: (value) {
                            _goalFocusNode.unfocus();
                            setState(() {}); // Formatlanmış metni göstermek için
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              const SizedBox(height: 40),
              
              // Planı Oluştur Butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _completeOnboarding();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.softPinkButton,
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
                  child: const Text(
                    'Planı Oluştur',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Modern Kart Sistemi - Tıklanabilir Buton
  // Modal Bottom Sheet Fonksiyonları - Modüler Widget'lara yönlendirme
  
}

// Modüler Modal Sheet Widget'ları - Performans İyileştirmesi

class GenderModalSheet extends StatelessWidget {
  final String? selectedGender;
  final Function(String) onGenderSelected;

  const GenderModalSheet({
    super.key,
    required this.selectedGender,
    required this.onGenderSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                _buildModalOption(
                  context,
                  'Erkek',
                  Icons.male,
                  selectedGender == 'male',
                  () => onGenderSelected('male'),
                ),
                const SizedBox(height: 12),
                _buildModalOption(
                  context,
                  'Kadın',
                  Icons.female,
                  selectedGender == 'female',
                  () => onGenderSelected('female'),
                ),
                const SizedBox(height: 12),
                _buildModalOption(
                  context,
                  'Belirtmek İstemiyorum',
                  Icons.person_outline,
                  selectedGender == 'prefer_not_to_say',
                  () => onGenderSelected('prefer_not_to_say'),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildModalOption(
    BuildContext context,
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.softPinkButton.withValues(alpha: 0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.softPinkButton
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.softPinkButton
                  : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.softPinkButton
                      : const Color(0xFF4A5568),
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.softPinkButton,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

class WeightModalSheet extends StatefulWidget {
  final FixedExtentScrollController weightController;
  final int weightUnit;
  final List<Widget> weightPickerChildrenKg;
  final List<Widget> weightPickerChildrenLbs;
  final Function(int, int) onWeightUnitChanged;

  const WeightModalSheet({
    super.key,
    required this.weightController,
    required this.weightUnit,
    required this.weightPickerChildrenKg,
    required this.weightPickerChildrenLbs,
    required this.onWeightUnitChanged,
  });

  @override
  State<WeightModalSheet> createState() => _WeightModalSheetState();
}

class _WeightModalSheetState extends State<WeightModalSheet> {
  late int _currentWeightUnit;

  @override
  void initState() {
    super.initState();
    _currentWeightUnit = widget.weightUnit;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
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
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Kilo Seçiniz',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A5568),
              ),
            ),
          ),
          
          // Kg/Lbs Seçici - Picker'ın üstüne, geniş ve okunaklı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Center(
              child: SizedBox(
                width: 140,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _currentWeightUnit,
                backgroundColor: Colors.grey[200]!,
                thumbColor: AppColors.softPinkButton,
                onValueChanged: (value) {
                  if (value != null) {
                    final currentIndex = widget.weightController.selectedItem;
                    int newWeight = 0;
                    
                    if (value == 1 && _currentWeightUnit == 0) {
                      // Kg'den Lbs'e çevir
                      final weightKg = 30 + currentIndex;
                      newWeight = (weightKg * 2.20462).round().clamp(66, 441);
                      widget.weightController.jumpToItem((newWeight - 66).clamp(0, 375));
                    } else if (value == 0 && _currentWeightUnit == 1) {
                      // Lbs'den Kg'ye çevir
                      final weightLbs = 66 + currentIndex;
                      newWeight = (weightLbs * 0.453592).round().clamp(30, 200);
                      widget.weightController.jumpToItem((newWeight - 30).clamp(0, 170));
                    }
                    
                    setState(() {
                      _currentWeightUnit = value;
                    });
                    
                    widget.onWeightUnitChanged(value, newWeight);
                  }
                },
                children: {
                  0: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'Kilogram (Kg)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _currentWeightUnit == 0 
                            ? Colors.white 
                            : const Color(0xFF4A5568),
                      ),
                    ),
                  ),
                  1: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'Pound (Lbs)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _currentWeightUnit == 1 
                            ? Colors.white 
                            : const Color(0xFF4A5568),
                      ),
                    ),
                  ),
                },
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Kilo Picker - Tam genişlik
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: CupertinoPicker(
                  scrollController: widget.weightController,
                  itemExtent: 50,
                  onSelectedItemChanged: (index) {
                    // Listener otomatik olarak setState çağıracak
                  },
                  children: _currentWeightUnit == 0 
                      ? widget.weightPickerChildrenKg 
                      : widget.weightPickerChildrenLbs,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.softPinkButton,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Tamam',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityModalSheet extends StatelessWidget {
  final String? selectedActivity;
  final Function(String) onActivitySelected;

  const ActivityModalSheet({
    super.key,
    required this.selectedActivity,
    required this.onActivitySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                _buildModalOption(
                  context,
                  'Düşük',
                  selectedActivity == 'low',
                  () => onActivitySelected('low'),
                  subtitle: 'Günlük aktivite az',
                ),
                const SizedBox(height: 12),
                _buildModalOption(
                  context,
                  'Orta',
                  selectedActivity == 'medium',
                  () => onActivitySelected('medium'),
                  subtitle: 'Haftada 3-4 kez egzersiz',
                ),
                const SizedBox(height: 12),
                _buildModalOption(
                  context,
                  'Yüksek',
                  selectedActivity == 'high',
                  () => onActivitySelected('high'),
                  subtitle: 'Günlük yoğun egzersiz',
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildModalOption(
    BuildContext context,
    String title,
    bool isSelected,
    VoidCallback onTap, {
    String? subtitle,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.softPinkButton.withValues(alpha: 0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.softPinkButton
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.softPinkButton
                          : const Color(0xFF4A5568),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.softPinkButton,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

class ClimateModalSheet extends StatelessWidget {
  final String? selectedClimate;
  final Function(String) onClimateSelected;

  const ClimateModalSheet({
    super.key,
    required this.selectedClimate,
    required this.onClimateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                _buildModalOption(
                  context,
                  'Soğuk',
                  selectedClimate == 'cold',
                  () => onClimateSelected('cold'),
                  subtitle: 'Kış ayları, soğuk bölgeler',
                ),
                const SizedBox(height: 12),
                _buildModalOption(
                  context,
                  'Ilıman',
                  selectedClimate == 'warm',
                  () => onClimateSelected('warm'),
                  subtitle: 'Mevsimsel değişimler',
                ),
                const SizedBox(height: 12),
                _buildModalOption(
                  context,
                  'Sıcak',
                  selectedClimate == 'hot',
                  () => onClimateSelected('hot'),
                  subtitle: 'Yaz ayları, sıcak bölgeler',
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildModalOption(
    BuildContext context,
    String title,
    bool isSelected,
    VoidCallback onTap, {
    String? subtitle,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.softPinkButton.withValues(alpha: 0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.softPinkButton
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.softPinkButton
                          : const Color(0xFF4A5568),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.softPinkButton,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

