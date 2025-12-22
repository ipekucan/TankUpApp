import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../providers/user_provider.dart';
import '../providers/water_provider.dart';
import 'plan_loading_screen.dart';
import 'main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Form verileri - Başlangıçta boş
  String? _selectedGender;
  int _selectedHeight = 0; // cm (100-250 arası) - Başlangıçta 0
  int _selectedWeight = 0; // kg veya lbs (birime göre) - Başlangıçta 0
  String? _selectedActivityLevel;
  String? _selectedClimate; // İklim seçimi
  int _weightUnit = 0; // 0 = Kg, 1 = Lbs (CupertinoSlidingSegmentedControl için)
  double? _customGoal; // Özel hedef
  
  
  // Canlı hesaplanan su hedefi
  double get _calculatedWaterGoal {
    // En az bir veri (Boy veya Kilo) girilene kadar 0 döndür
    if (_selectedWeight == 0 && _selectedHeight == 0) return 0.0;
    
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
    if (_selectedClimate == 'hot') {
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
  late FixedExtentScrollController _heightController;
  late FixedExtentScrollController _weightController;
  
  // Cache'lenmiş picker children'ları (performans için)
  late final List<Widget> _heightPickerChildren;
  late final List<Widget> _weightPickerChildrenKg;
  late final List<Widget> _weightPickerChildrenLbs;
  
  @override
  void initState() {
    super.initState();
    _heightController = FixedExtentScrollController(initialItem: 0); // Başlangıçta 0 (100 cm)
    _weightController = FixedExtentScrollController(initialItem: 0); // Başlangıçta 0 (30 kg)
    
    // Picker children'larını önceden oluştur (performans için) - Kompakt ve zarif tasarım
    _heightPickerChildren = List.generate(151, (index) {
      final height = 100 + index;
      return Center(
        child: Text(
          '$height cm',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.grey,
          ),
        ),
      );
    });
    
    _weightPickerChildrenKg = List.generate(171, (index) {
      final weight = 30 + index;
      return Center(
        child: Text(
          '$weight',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.grey,
          ),
        ),
      );
    });
    
    _weightPickerChildrenLbs = List.generate(376, (index) {
      final weight = 66 + index;
      return Center(
        child: Text(
          '$weight',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.grey,
          ),
        ),
      );
    });
    
    // Controller'ları dinle ve sadece gerektiğinde setState çağır
    _heightController.addListener(_onHeightChanged);
    _weightController.addListener(_onWeightChanged);
  }
  
  void _onHeightChanged() {
    if (_heightController.hasClients) {
      final index = _heightController.selectedItem;
      if (index >= 0 && index < 151) {
        final newHeight = 100 + index;
        if (newHeight != _selectedHeight) {
          setState(() {
            _selectedHeight = newHeight;
          });
        }
      }
    }
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
    _heightController.removeListener(_onHeightChanged);
    _weightController.removeListener(_onWeightChanged);
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
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
      height: _selectedHeight.toDouble(),
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
    
    // Plan Loading ekranına yönlendir
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlanLoadingScreen(
          customGoal: _customGoal,
        ),
      ),
    );
  }
  
  Future<void> _skipOnboarding() async {
    if (!mounted) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final waterProvider = Provider.of<WaterProvider>(context, listen: false);
    
    // Varsayılan değerlerle profil oluştur
    await userProvider.updateProfile(
      gender: null,
      height: 170.0,
      weight: 70.0,
      activityLevel: 'medium',
    );
    
    // Varsayılan 2000ml hedefi ayarla
    await waterProvider.updateDailyGoal(2000.0);
    
    // Coin'i sıfırla
    await waterProvider.resetCoins();
    
    // Onboarding tamamlandı olarak işaretle
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    if (!mounted) return;
    
    // Ana sayfaya yönlendir
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const MainNavigationScreen(),
      ),
      (route) => false,
    );
  }

  bool _canProceed() {
    final weightValid = _weightUnit == 0
        ? _selectedWeight >= 30 && _selectedWeight <= 200
        : _selectedWeight >= 66 && _selectedWeight <= 441;
    return _selectedGender != null &&
        _selectedHeight >= 100 &&
        _selectedHeight <= 250 &&
        weightValid &&
        _selectedActivityLevel != null;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.verySoftBlue,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Atla Butonu - Sol Üst Köşe
              Align(
                alignment: Alignment.topLeft,
                child: TextButton(
                  onPressed: () => _skipOnboarding(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Atla',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF4A5568).withValues(alpha: 0.6),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Başlık
              const Text(
                'Sağlık Profili',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF4A5568),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Kişisel hidrasyon planınızı oluşturmak için bilgilerinizi girin',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF4A5568).withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 40),
              
              // Dinamik Üst Banner - Bilimsel Hidrasyon İhtiyacı
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Günlük Hidrasyon İhtiyacı: ${_calculatedWaterGoal.toStringAsFixed(0)} ml',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.softPinkButton,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Modern Kart Sistemi - Tıklanabilir Butonlar
              _buildSelectableButton(
                title: 'Cinsiyet',
                value: _selectedGender == null 
                    ? null 
                    : _selectedGender == 'male' 
                        ? 'Erkek' 
                        : _selectedGender == 'female' 
                            ? 'Kadın' 
                            : 'Belirtmek İstemiyorum',
                onTap: () => _showGenderModal(),
              ),
              
              const SizedBox(height: 12),
              
              _buildSelectableButton(
                title: 'Boy',
                value: _selectedHeight == 0 ? null : '$_selectedHeight cm',
                onTap: () => _showHeightModal(),
              ),
              
              const SizedBox(height: 12),
              
              _buildSelectableButton(
                title: 'Kilo',
                value: _selectedWeight == 0 ? null : '$_selectedWeight ${_weightUnit == 0 ? 'kg' : 'lbs'}',
                onTap: () => _showWeightModal(),
              ),
              
              const SizedBox(height: 12),
              
              _buildSelectableButton(
                title: 'Aktivite Seviyesi',
                value: _selectedActivityLevel == null
                    ? null
                    : _selectedActivityLevel == 'low'
                        ? 'Düşük'
                        : _selectedActivityLevel == 'medium'
                            ? 'Orta'
                            : 'Yüksek',
                onTap: () => _showActivityModal(),
              ),
              
              const SizedBox(height: 12),
              
              _buildSelectableButton(
                title: 'İklim',
                value: _selectedClimate == null
                    ? null
                    : _selectedClimate == 'cold'
                        ? 'Soğuk'
                        : _selectedClimate == 'warm'
                            ? 'Ilıman'
                            : 'Sıcak',
                onTap: () => _showClimateModal(),
              ),
              
              const SizedBox(height: 20),
              
              // Özel Hedef Butonu (Minimalist)
              TextButton(
                onPressed: () => _showCustomGoalDialog(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Özel Hedef Belirle',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF4A5568).withValues(alpha: 0.6),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // İleri Butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canProceed() ? _completeOnboarding : null,
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
        ),
      ),
    );
  }

  // Modern Kart Sistemi - Tıklanabilir Buton
  Widget _buildSelectableButton({
    required String title,
    required String? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value != null 
                ? AppColors.softPinkButton.withValues(alpha: 0.3)
                : Colors.grey[300]!,
            width: value != null ? 2 : 1,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.softPinkButton,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    'Seçiniz',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ],
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.softPinkButton,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
  
  // Modal Bottom Sheet Fonksiyonları - Modüler Widget'lara yönlendirme
  
  void _showGenderModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      isScrollControlled: true,
      builder: (context) => GenderModalSheet(
        selectedGender: _selectedGender,
        onGenderSelected: (gender) {
          setState(() => _selectedGender = gender);
          Navigator.pop(context);
        },
      ),
    );
  }
  
  void _showHeightModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      isScrollControlled: true,
      builder: (context) => HeightModalSheet(
        heightController: _heightController,
        heightPickerChildren: _heightPickerChildren,
      ),
    );
  }
  
  void _showWeightModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      isScrollControlled: true,
      builder: (context) => WeightModalSheet(
        weightController: _weightController,
        weightUnit: _weightUnit,
        weightPickerChildrenKg: _weightPickerChildrenKg,
        weightPickerChildrenLbs: _weightPickerChildrenLbs,
        onWeightUnitChanged: (unit, newWeight) {
          setState(() {
            _weightUnit = unit;
            _selectedWeight = newWeight;
          });
        },
      ),
    );
  }
  
  void _showActivityModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      isScrollControlled: true,
      builder: (context) => ActivityModalSheet(
        selectedActivity: _selectedActivityLevel,
        onActivitySelected: (activity) {
          setState(() => _selectedActivityLevel = activity);
          Navigator.pop(context);
        },
      ),
    );
  }
  
  void _showClimateModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      isScrollControlled: true,
      builder: (context) => ClimateModalSheet(
        selectedClimate: _selectedClimate,
        onClimateSelected: (climate) {
          setState(() => _selectedClimate = climate);
          Navigator.pop(context);
        },
      ),
    );
  }
  
  void _showCustomGoalDialog() {
    final TextEditingController goalController = TextEditingController(
      text: _customGoal != null ? (_customGoal! / 1000.0).toStringAsFixed(1) : '',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Özel Hedef Belirle'),
        content: TextField(
          controller: goalController,
          decoration: InputDecoration(
            labelText: 'Günlük Hedef (L)',
            hintText: 'Örn: 3.5',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              final goal = double.tryParse(goalController.text);
              if (goal != null && goal > 0) {
                setState(() {
                  _customGoal = goal * 1000.0; // L'den ml'ye çevir
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
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

class HeightModalSheet extends StatelessWidget {
  final FixedExtentScrollController heightController;
  final List<Widget> heightPickerChildren;

  const HeightModalSheet({
    super.key,
    required this.heightController,
    required this.heightPickerChildren,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
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
            padding: EdgeInsets.all(16),
            child: Text(
              'Boy Seçiniz',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A5568),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: CupertinoPicker(
                scrollController: heightController,
                itemExtent: 50,
                onSelectedItemChanged: (index) {
                  // Listener otomatik olarak setState çağıracak
                },
                children: heightPickerChildren,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.softPinkButton,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tamam'),
            ),
          ),
        ],
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

