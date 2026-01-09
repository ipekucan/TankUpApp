import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/daily_hydration_provider.dart';
import '../widgets/onboarding/onboarding_menu_button.dart';
import '../widgets/onboarding/onboarding_bottom_sheet.dart';
import '../widgets/onboarding/selection_button.dart';
import '../widgets/onboarding/weight_picker_bottom_sheet.dart';
import 'plan_loading_screen.dart';

/// Onboarding Dashboard - Single Page Design
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  // Clean & Bold color palette
  static const Color _backgroundOffWhite = Color(0xFFF7F7F7); // Off-white background
  static const Color _primaryMutedBlue = Color(0xFF85B7D2); // Muted blue for text
  
  // Animation controller for breathing effect
  late AnimationController _breathingController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  // State variables
  String? _selectedGender;
  int _selectedWeight = 80; // Default 80
  String _selectedWeightUnit = 'kg'; // Default unit
  bool _weightConfirmed = false; // Track if weight was explicitly confirmed
  String? _selectedActivityLevel;
  String? _selectedClimate;
  
  // Calculated water goal
  double get _calculatedWaterGoal {
    double baseGoal = 35.0 * _selectedWeight; // 35ml/kg
    
    // Activity bonus
    double activityBonus = 0.0;
    if (_selectedActivityLevel == 'high') {
      activityBonus = 500.0;
    } else if (_selectedActivityLevel == 'medium') {
      activityBonus = 250.0;
    }
    
    // Climate bonus
    double climateBonus = 0.0;
    if (_selectedClimate == 'very_hot') {
      climateBonus = 400.0;
    } else if (_selectedClimate == 'hot') {
      climateBonus = 300.0;
    } else if (_selectedClimate == 'warm') {
      climateBonus = 150.0;
    }
    
    return (baseGoal + activityBonus + climateBonus).clamp(1500.0, 5000.0);
  }
  
  @override
  void initState() {
    super.initState();
    
    // Initialize breathing animation
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start repeating animation
    _breathingController.repeat(reverse: true);
    
    // Set metric as default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setIsMetric(true);
      }
    });
  }
  
  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundOffWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            _buildTopBar(),
            
            const SizedBox(height: 40),
            
            // Header Section (Goal + Title)
            _buildHeader(),
            
            const SizedBox(height: 12),
            
            // Menu Buttons
            Expanded(
              child: _buildMenuButtons(),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Top bar with Skip button
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: _skipOnboarding,
            child: const Text(
              'Atla',
              style: TextStyle(
                color: _primaryMutedBlue,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Header with goal and title text
  Widget _buildHeader() {
    final goalValue = _calculatedWaterGoal > 0 
        ? '${_calculatedWaterGoal.toStringAsFixed(0)} ml' 
        : '.......... ml';
    
    return Column(
      children: [
        // Top Text: Calculated goal
        Text(
          goalValue,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _primaryMutedBlue,
            fontSize: 72,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        
        const SizedBox(height: 2),
        
        // Bottom Text: Title
        AnimatedBuilder(
          animation: _breathingController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: const Text(
                  'Hedefini Belirle',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _primaryMutedBlue,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  /// Menu buttons section
  Widget _buildMenuButtons() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OnboardingMenuButton(
              label: 'Cinsiyet',
              icon: Icons.person_outline,
              selectedValue: _getGenderDisplayValue(),
              selectedIcon: _getGenderIcon(),
              onTap: () => _handleButtonTap('Cinsiyet'),
            ),
            
            const SizedBox(height: 10),
            
            OnboardingMenuButton(
              label: 'Kilo',
              icon: Icons.monitor_weight_outlined,
              selectedValue: _weightConfirmed ? '$_selectedWeight $_selectedWeightUnit' : null,
              selectedIcon: _weightConfirmed ? Icons.monitor_weight : null,
              onTap: () => _handleButtonTap('Kilo'),
            ),
            
            const SizedBox(height: 10),
            
            OnboardingMenuButton(
              label: 'Aktivite',
              icon: Icons.directions_run_outlined,
              selectedValue: _getActivityDisplayValue(),
              selectedIcon: _getActivityIcon(),
              onTap: () => _handleButtonTap('Aktivite'),
            ),
            
            const SizedBox(height: 10),
            
            OnboardingMenuButton(
              label: 'İklim',
              icon: Icons.wb_sunny_outlined,
              selectedValue: _getClimateDisplayValue(),
              selectedIcon: _getClimateIcon(),
              onTap: () => _handleButtonTap('İklim'),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Get gender display value in Turkish
  String? _getGenderDisplayValue() {
    if (_selectedGender == null) return null;
    switch (_selectedGender) {
      case 'male':
        return 'Erkek';
      case 'female':
        return 'Kadın';
      case 'other':
        return 'Belirtilmedi';
      default:
        return null;
    }
  }
  
  /// Get gender icon
  IconData? _getGenderIcon() {
    if (_selectedGender == null) return null;
    switch (_selectedGender) {
      case 'male':
        return Icons.male;
      case 'female':
        return Icons.female;
      case 'other':
        return Icons.do_not_disturb;
      default:
        return null;
    }
  }
  
  /// Get activity display value in Turkish
  String? _getActivityDisplayValue() {
    if (_selectedActivityLevel == null) return null;
    switch (_selectedActivityLevel) {
      case 'low':
        return 'Düşük';
      case 'medium':
        return 'Orta';
      case 'high':
        return 'Yüksek';
      default:
        return null;
    }
  }
  
  /// Get activity icon
  IconData? _getActivityIcon() {
    if (_selectedActivityLevel == null) return null;
    switch (_selectedActivityLevel) {
      case 'low':
        return Icons.chair;
      case 'medium':
        return Icons.directions_walk;
      case 'high':
        return Icons.fitness_center;
      default:
        return null;
    }
  }
  
  /// Get climate display value in Turkish
  String? _getClimateDisplayValue() {
    if (_selectedClimate == null) return null;
    switch (_selectedClimate) {
      case 'very_hot':
        return 'Çok Sıcak';
      case 'hot':
        return 'Sıcak';
      case 'warm':
        return 'ılıman';
      case 'cold':
        return 'Soğuk';
      default:
        return null;
    }
  }
  
  /// Get climate icon
  IconData? _getClimateIcon() {
    if (_selectedClimate == null) return null;
    switch (_selectedClimate) {
      case 'very_hot':
        return Icons.wb_sunny;
      case 'hot':
        return Icons.wb_sunny_outlined;
      case 'warm':
        return Icons.wb_cloudy;
      case 'cold':
        return Icons.ac_unit;
      default:
        return null;
    }
  }
  
  /// Handle button tap - Show respective bottom sheet
  void _handleButtonTap(String buttonName) {
    switch (buttonName) {
      case 'Cinsiyet':
        _showGenderSheet();
        break;
      case 'Kilo':
        _showWeightSheet();
        break;
      case 'Aktivite':
        _showActivitySheet();
        break;
      case 'İklim':
        _showClimateSheet();
        break;
    }
  }
  
  /// Show gender selection sheet
  void _showGenderSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => OnboardingBottomSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cinsiyetinizi Seçin',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C5282),
              ),
            ),
            const SizedBox(height: 24),
            SelectionButton(
              label: 'Kadın',
              icon: Icons.female,
              isSelected: _selectedGender == 'female',
              onTap: () {
                setState(() => _selectedGender = 'female');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            SelectionButton(
              label: 'Erkek',
              icon: Icons.male,
              isSelected: _selectedGender == 'male',
              onTap: () {
                setState(() => _selectedGender = 'male');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            SelectionButton(
              label: 'Belirtmek İstemiyorum',
              icon: Icons.do_not_disturb_on_outlined,
              isSelected: _selectedGender == 'other',
              onTap: () {
                setState(() => _selectedGender = 'other');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  /// Show weight selection sheet
  void _showWeightSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => WeightPickerBottomSheet(
        initialWeight: _selectedWeight,
        initialUnit: _selectedWeightUnit,
        onConfirm: (weight, unit) {
          setState(() {
            _selectedWeight = weight;
            _selectedWeightUnit = unit;
            _weightConfirmed = true;
          });
        },
      ),
    );
  }
  
  /// Show activity selection sheet
  void _showActivitySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => OnboardingBottomSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Aktivite Seviyenizi Seçin',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C5282),
              ),
            ),
            const SizedBox(height: 24),
            SelectionButton(
              label: 'Düşük',
              icon: Icons.chair,
              isSelected: _selectedActivityLevel == 'low',
              onTap: () {
                setState(() => _selectedActivityLevel = 'low');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            SelectionButton(
              label: 'Orta',
              icon: Icons.directions_walk,
              isSelected: _selectedActivityLevel == 'medium',
              onTap: () {
                setState(() => _selectedActivityLevel = 'medium');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            SelectionButton(
              label: 'Yüksek',
              icon: Icons.fitness_center,
              isSelected: _selectedActivityLevel == 'high',
              onTap: () {
                setState(() => _selectedActivityLevel = 'high');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  /// Show climate selection sheet
  void _showClimateSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => OnboardingBottomSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'İklim Seçin',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C5282),
              ),
            ),
            const SizedBox(height: 24),
            SelectionButton(
              label: 'Çok Sıcak',
              icon: Icons.wb_sunny,
              isSelected: _selectedClimate == 'very_hot',
              onTap: () {
                setState(() => _selectedClimate = 'very_hot');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            SelectionButton(
              label: 'Sıcak',
              icon: Icons.wb_sunny_outlined,
              isSelected: _selectedClimate == 'hot',
              onTap: () {
                setState(() => _selectedClimate = 'hot');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            SelectionButton(
              label: 'ılıman',
              icon: Icons.wb_cloudy,
              isSelected: _selectedClimate == 'warm',
              onTap: () {
                setState(() => _selectedClimate = 'warm');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            SelectionButton(
              label: 'Soğuk',
              icon: Icons.ac_unit,
              isSelected: _selectedClimate == 'cold',
              onTap: () {
                setState(() => _selectedClimate = 'cold');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  /// Skip onboarding - Save data and navigate
  void _skipOnboarding() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final hydrationProvider = Provider.of<DailyHydrationProvider>(context, listen: false);
    
    // Save profile data
    await userProvider.updateProfile(
      gender: _selectedGender,
      weight: _selectedWeight.toDouble(),
      activityLevel: _selectedActivityLevel,
      climate: _selectedClimate,
    );
    
    // Save water goal
    await hydrationProvider.updateDailyGoal(_calculatedWaterGoal);
    
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const PlanLoadingScreen(customGoal: null),
      ),
    );
  }
}
