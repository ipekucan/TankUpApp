import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import '../providers/user_provider.dart';
import '../providers/daily_hydration_provider.dart';
import 'plan_loading_screen.dart';
import '../widgets/onboarding/onboarding_theme.dart';
import '../widgets/onboarding/steps/gender_step.dart';
import '../widgets/onboarding/steps/weight_step.dart';
import '../widgets/onboarding/steps/activity_step.dart';
import '../widgets/onboarding/steps/climate_step.dart';
import '../widgets/onboarding/steps/goal_step.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Sabitler - Hardcoded değerler yerine
  static const double _defaultGoalMl = 2500.0; // Varsayılan ml hedefi
  static const double _defaultGoalOz = 85.0; // Varsayılan oz hedefi
  
  // Form verileri - Başlangıçta boş
  String? _selectedGender;
  int _selectedWeight = 0; // kg veya lbs (birime göre) - Başlangıçta 0
  String? _selectedActivityLevel;
  String? _selectedClimate; // İklim seçimi
  int _weightUnit = 0; // 0 = Kg, 1 = Lbs (CupertinoSlidingSegmentedControl için)
  double _customGoal = 2500.0; // Özel hedef - Varsayılan: 2500 ml (direkt birimde tutulur)
  // _volumeUnit kaldırıldı - artık _weightUnit'e göre belirleniyor (kg = ml, lbs = oz)
  
  // PageView Controller
  late PageController _pageController;
  int _currentPage = 0; // 0-4 arası (5 adım)
  
  // Miktar TextField Controller
  late TextEditingController _amountController;
  
  // Showcase Key - Günlük Hedef tanıtımı için
  final GlobalKey _goalShowcaseKey = GlobalKey();
  
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
    _amountController = TextEditingController();
    
    // Varsayılan değerleri ayarla (ml ve 2500)
    _customGoal = _defaultGoalMl;
    _amountController.text = _customGoal.toStringAsFixed(0);
    
    // UserProvider'ı varsayılan olarak metric yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setIsMetric(true);
      }
    });
    
    // Controller'ı dinle ve sadece gerektiğinde setState çağır
    _weightController.addListener(_onWeightChanged);
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
    _amountController.dispose();
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
    final dailyHydrationProvider =
        Provider.of<DailyHydrationProvider>(context, listen: false);
    
    // Kilo dönüşümü (Lbs ise Kg'ye çevir)
    final weightInKg = _weightUnit == 1 
        ? _selectedWeight * 0.453592 
        : _selectedWeight.toDouble();
    
    // Profil verilerini kaydet
    await userProvider.updateProfile(
      gender: _selectedGender,
      weight: weightInKg,
      activityLevel: _selectedActivityLevel,
      climate: _selectedClimate,
    );
    
    // Birim sistemini kaydet (UserProvider'dan anlık birim bilgisini al)
    final isMetric = userProvider.isMetric;
    
    // Su hedefini kaydet (_customGoal seçili birimde tutuluyor, ml'ye çevirerek kaydet)
    double finalGoalMl;
    if (_customGoal > 0) {
      if (isMetric) {
        // Metric (ml) - direkt kullan
        finalGoalMl = _customGoal;
      } else {
        // Imperial (oz) - ml'ye çevir
        finalGoalMl = _customGoal / 0.033814;
      }
    } else {
      finalGoalMl = _calculatedWaterGoal;
    }
    await dailyHydrationProvider.updateDailyGoal(finalGoalMl);
    
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
          customGoal: _customGoal > 0 ? _customGoal : null,
        ),
      ),
    );
  }
  



  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      blurValue: 3.0,
      builder: (context) => Scaffold(
        backgroundColor: OnboardingTheme.background,
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
                    // 4. sayfaya (Günlük Hedef) geldiğinde showcase'i başlat
                    if (index == 4) {
                      _checkAndShowGoalTutorial();
                    }
                  },
                physics: const NeverScrollableScrollPhysics(), // Yatay kaydırmayı devre dışı bırak
                children: [
                  // 1. Adım: Cinsiyet Seçimi
                  GenderStep(
                    selectedGender: _selectedGender,
                    onGenderSelected: (gender) {
                      setState(() {
                        _selectedGender = gender;
                      });
                    },
                    onNext: _nextStep,
                  ),
                  // 2. Adım: Kilo Seçimi
                  WeightStep(
                    selectedWeight: _selectedWeight,
                    weightUnit: _weightUnit,
                    onWeightChanged: (weight) {
                      setState(() {
                        _selectedWeight = weight;
                      });
                    },
                    onWeightUnitChanged: (unit) {
                      setState(() {
                        _weightUnit = unit;
                        // Birim değiştiğinde hedef değerini güncelle
                        if (unit == 0) {
                          // kg'ye geçiş - ml moduna geç
                          _customGoal = _defaultGoalMl;
                        } else {
                          // lbs'ye geçiş - oz moduna geç
                          _customGoal = _defaultGoalOz;
                        }
                        _amountController.text = _customGoal.toStringAsFixed(unit == 0 ? 0 : 1);
                      });
                    },
                    onNext: _nextStep,
                    weightController: _weightController,
                  ),
                  // 3. Adım: Aktivite Seviyesi
                  ActivityStep(
                    selectedActivityLevel: _selectedActivityLevel,
                    onActivityLevelSelected: (activity) {
                      setState(() {
                        _selectedActivityLevel = activity;
                      });
                    },
                    onNext: _nextStep,
                  ),
                  // 4. Adım: İklim Seçimi
                  ClimateStep(
                    selectedClimate: _selectedClimate,
                    onClimateSelected: (climate) {
                      setState(() {
                        _selectedClimate = climate;
                      });
                    },
                    onNext: _nextStep,
                  ),
                  // 5. Adım: Günlük Hedef
                  GoalStep(
                    customGoal: _customGoal,
                    selectedWeight: _selectedWeight,
                    weightUnit: _weightUnit,
                    calculatedWaterGoal: _calculatedWaterGoal,
                    onGoalChanged: (goal) {
                      setState(() {
                        _customGoal = goal;
                      });
                    },
                    onComplete: _completeOnboarding,
                    showcaseKey: _goalShowcaseKey,
                    amountController: _amountController,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
  
  // Günlük Hedef tanıtımını kontrol et ve göster
  Future<void> _checkAndShowGoalTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenGoalTutorial = prefs.getBool('has_seen_goal_tutorial') ?? false;
    
    // Eğer daha önce görüldüyse hiç gösterme
    if (hasSeenGoalTutorial) {
      return;
    }
    
    // İlk seferinde göster
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted && _currentPage == 4) {
          ShowCaseWidget.of(context).startShowCase([_goalShowcaseKey]);
          // Hemen SharedPreferences'a kaydet (bir sonraki açılışta gösterme)
          await prefs.setBool('has_seen_goal_tutorial', true);
        }
      });
    }
  }
  
  // Üst Kontrol Paneli - Progress Bar + Atla Butonu
  Widget _buildTopControlPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: OnboardingTheme.pagePadding, vertical: 20),
      child: Row(
        children: [
          // Progress Bar - Animated with soft styling
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: OnboardingTheme.progressTrackColor,
                borderRadius: BorderRadius.circular(2.5),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        width: constraints.maxWidth * ((_currentPage + 1) * 0.20).clamp(0.0, 1.0),
                        decoration: BoxDecoration(
                          gradient: OnboardingTheme.progressGradient,
                          borderRadius: BorderRadius.circular(2.5),
                          boxShadow: [
                            BoxShadow(
                              color: OnboardingTheme.primaryAccent.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(width: 20),
          
          // Atla Butonu - Soft styling
          GestureDetector(
            onTap: _skipCurrentStep,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: OnboardingTheme.primaryAccentLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Atla',
                style: OnboardingTheme.subtitleStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: OnboardingTheme.primaryAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Step widgets moved to separate files in lib/widgets/onboarding/steps/
  // All _build*Step() methods have been extracted to individual widget files
  // Old build methods and modal sheet classes removed - they are no longer needed
}
