import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../providers/user_provider.dart';
import 'plan_loading_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Form verileri
  String? _selectedGender;
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String? _selectedActivityLevel;
  bool _isWeightInLbs = false; // Kg/Lbs toggle
  double? _customGoal; // Özel hedef

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (!mounted) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Kilo dönüşümü (Lbs ise Kg'ye çevir)
    double? weightInKg;
    if (_weightController.text.isNotEmpty) {
      final weight = double.tryParse(_weightController.text);
      if (weight != null) {
        weightInKg = _isWeightInLbs ? weight * 0.453592 : weight;
      }
    }
    
    // Profil verilerini kaydet
    await userProvider.updateProfile(
      gender: _selectedGender,
      height: _heightController.text.isNotEmpty ? double.tryParse(_heightController.text) : null,
      weight: weightInKg,
      activityLevel: _selectedActivityLevel,
    );
    
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

  bool _canProceed() {
    return _selectedGender != null &&
        _heightController.text.isNotEmpty &&
        _weightController.text.isNotEmpty &&
        double.tryParse(_heightController.text) != null &&
        double.tryParse(_weightController.text) != null &&
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
              
              // Cinsiyet Kartı
              _buildCard(
                title: 'Cinsiyet',
                child: Column(
                  children: [
                    _buildGenderOption('male', 'Erkek', Icons.male),
                    const SizedBox(height: 12),
                    _buildGenderOption('female', 'Kadın', Icons.female),
                    const SizedBox(height: 12),
                    _buildGenderOption('prefer_not_to_say', 'Belirtmek İstemiyorum', Icons.person_outline),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Boy ve Kilo Kartı
              _buildCard(
                title: 'Boy ve Kilo',
                child: Column(
                  children: [
                    TextField(
                      controller: _heightController,
                      decoration: InputDecoration(
                        labelText: 'Boy (cm)',
                        hintText: 'Örn: 170',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      style: const TextStyle(fontSize: 16),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _weightController,
                            decoration: InputDecoration(
                              labelText: _isWeightInLbs ? 'Kilo (lbs)' : 'Kilo (kg)',
                              hintText: _isWeightInLbs ? 'Örn: 154' : 'Örn: 70',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            style: const TextStyle(fontSize: 16),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Kg/Lbs Toggle
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _isWeightInLbs = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !_isWeightInLbs
                                        ? AppColors.softPinkButton
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    'Kg',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: !_isWeightInLbs
                                          ? Colors.white
                                          : const Color(0xFF4A5568),
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _isWeightInLbs = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _isWeightInLbs
                                        ? AppColors.softPinkButton
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    'Lbs',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _isWeightInLbs
                                          ? Colors.white
                                          : const Color(0xFF4A5568),
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
              ),
              
              const SizedBox(height: 20),
              
              // Aktivite Seviyesi Kartı
              _buildCard(
                title: 'Aktivite Seviyesi',
                child: Column(
                  children: [
                    _buildActivityOption('low', 'Düşük', 'Günlük aktivite az'),
                    const SizedBox(height: 12),
                    _buildActivityOption('medium', 'Orta', 'Haftada 3-4 kez egzersiz'),
                    const SizedBox(height: 12),
                    _buildActivityOption('high', 'Yüksek', 'Günlük yoğun egzersiz'),
                  ],
                ),
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

  Widget _buildCard({required String title, required Widget child}) {
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildGenderOption(String value, String label, IconData icon) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.softPinkButton
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
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
              color: isSelected ? Colors.white : AppColors.softPinkButton,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF4A5568),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityOption(String value, String label, String description) {
    final isSelected = _selectedActivityLevel == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedActivityLevel = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.softPinkButton
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? AppColors.softPinkButton
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF4A5568),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
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
