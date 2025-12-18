import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../utils/app_colors.dart';
import '../models/axolotl_model.dart';
import '../providers/water_provider.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  AxolotlPreset? _selectedPreset; // Sadece profil avatar'ı için seçili preset
  double _dailyGoalSlider = 5000.0; // Günlük hedef slider değeri

  // Niş Aksolot Taslakları - Profil 1, Profil 2, vb.
  final List<AxolotlPreset> _presets = [
    AxolotlPreset(
      name: 'Profil 1',
      description: 'Yazlık Gözlüklü',
      skinColor: 'Pink',
      eyeColor: 'Black',
      accessories: [
        Accessory(type: 'glasses', name: 'Güneş Gözlüğü', color: 'Gray'),
      ],
    ),
    AxolotlPreset(
      name: 'Profil 2',
      description: 'Kışlık Atkılı',
      skinColor: 'Blue',
      eyeColor: 'Brown',
      accessories: [
        Accessory(type: 'scarf', name: 'Kırmızı Atkı', color: 'Red'),
      ],
    ),
    AxolotlPreset(
      name: 'Profil 3',
      description: 'Şapkalı Şık',
      skinColor: 'Pink',
      eyeColor: 'Blue',
      accessories: [
        Accessory(type: 'hat', name: 'Şık Şapka', color: 'Gold'),
      ],
    ),
    AxolotlPreset(
      name: 'Profil 4',
      description: 'Minimalist',
      skinColor: 'Pink',
      eyeColor: 'Black',
      accessories: [],
    ),
  ];

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  void _selectPreset(AxolotlPreset preset) {
    setState(() {
      _selectedPreset = preset;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.verySoftBlue,
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer2<WaterProvider, UserProvider>(
        builder: (context, waterProvider, userProvider, child) {
          // Slider değerini güncelle
          if (_dailyGoalSlider != waterProvider.dailyGoal) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _dailyGoalSlider = waterProvider.dailyGoal;
                });
              }
            });
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profil Avatar - Seçili preset'e göre gösterilecek
                _buildProfileAvatar(),
                const SizedBox(height: 20),
                const Text(
                  'Fotoğrafınızı ekleyin',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF4A5568),
                  ),
                ),
                const SizedBox(height: 40),
                
                // İstatistik Kartları
                _buildStatsCards(waterProvider, userProvider),
                const SizedBox(height: 30),
                
                // Haftalık Grafik
                _buildWeeklyChart(),
                const SizedBox(height: 30),
                
                // Günlük Hedef Ayarı
                _buildDailyGoalSlider(waterProvider),
                const SizedBox(height: 30),
                
                // Niş Aksolot Taslakları başlığı
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Niş Aksolot Taslakları',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A5568),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Yatay kaydırma çubuğu - Taslaklar
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _presets.length,
                itemBuilder: (context, index) {
                  final preset = _presets[index];
                  final isSelected = _selectedPreset == preset;
                  
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 16),
                    child: InkWell(
                      onTap: () => _selectPreset(preset),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.softPinkButton
                                : Colors.grey.withValues(alpha: 0.2),
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Mini aksolot önizleme
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: _getSkinColor(preset.skinColor).withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _getSkinColor(preset.skinColor),
                                  width: 2,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Gövde
                                  Container(
                                    width: 50,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _getSkinColor(preset.skinColor),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  // Gözler
                                  Positioned(
                                    left: 12,
                                    top: 10,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _getEyeColor(preset.eyeColor),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 12,
                                    top: 10,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _getEyeColor(preset.eyeColor),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  // Aksesuarlar
                                  if (preset.accessories.any((a) => a.type == 'hat'))
                                    Positioned(
                                      top: -5,
                                      child: Container(
                                        width: 40,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: AppColors.hatColor,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  if (preset.accessories.any((a) => a.type == 'glasses'))
                                    Positioned(
                                      top: 8,
                                      child: Container(
                                        width: 35,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: AppColors.glassesColor.withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  if (preset.accessories.any((a) => a.type == 'scarf'))
                                    Positioned(
                                      bottom: 0,
                                      child: Container(
                                        width: 45,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: AppColors.scarfColor,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              preset.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected
                                    ? AppColors.softPinkButton
                                    : const Color(0xFF4A5568),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.softPinkButton,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            
            // Test Butonları
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Kirliliği Simüle Et Butonu
                ElevatedButton.icon(
                  onPressed: () async {
                    await waterProvider.simulateDirtyTank();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tank kirliliği simüle edildi (25 saat öncesi)'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.water_drop, size: 18),
                  label: const Text('Kirliliği Simüle Et'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.withValues(alpha: 0.8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                
                // Verileri Sıfırla Butonu (uzun basışla)
                GestureDetector(
                  onLongPress: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Verileri Sıfırla'),
                        content: const Text('Tüm verileri sıfırlamak istediğinizden emin misiniz?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('İptal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Sıfırla'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await waterProvider.resetData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Veriler sıfırlandı')),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, size: 18, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          'Uzun bas: Sıfırla',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
        },
      ),
    );
  }

  Widget _buildProfileAvatar() {
    // Eğer profil fotoğrafı varsa onu göster
    if (_profileImage != null) {
      return GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.softPinkButton.withValues(alpha: 0.3),
              width: 3,
            ),
          ),
          child: ClipOval(
            child: Image.file(
              _profileImage!,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }
    
    // Eğer preset seçildiyse, preset'e göre aksolot avatar'ı göster
    if (_selectedPreset != null) {
      return GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.softPinkButton.withValues(alpha: 0.3),
              width: 3,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Gövde
              Container(
                width: 80,
                height: 65,
                decoration: BoxDecoration(
                  color: _getSkinColor(_selectedPreset!.skinColor),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: _getSkinColor(_selectedPreset!.skinColor).withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
              // Sol yanak
              Positioned(
                left: 20,
                top: 25,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _getSkinColor(_selectedPreset!.skinColor).withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Sağ yanak
              Positioned(
                right: 20,
                top: 25,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _getSkinColor(_selectedPreset!.skinColor).withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Sol göz
              Positioned(
                left: 25,
                top: 20,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getEyeColor(_selectedPreset!.eyeColor),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Sağ göz
              Positioned(
                right: 25,
                top: 20,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getEyeColor(_selectedPreset!.eyeColor),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Gülümseme
              Positioned(
                bottom: 20,
                child: Container(
                  width: 30,
                  height: 15,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _getEyeColor(_selectedPreset!.eyeColor).withValues(alpha: 0.8),
                        width: 2,
                      ),
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                ),
              ),
              // Şapka (varsa)
              if (_selectedPreset!.accessories.any((a) => a.type == 'hat'))
                Positioned(
                  top: -10,
                  child: Container(
                    width: 55,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.hatColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              // Gözlük (varsa)
              if (_selectedPreset!.accessories.any((a) => a.type == 'glasses'))
                Positioned(
                  top: 15,
                  child: Container(
                    width: 50,
                    height: 15,
                    decoration: BoxDecoration(
                      color: AppColors.glassesColor.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.glassesColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              // Atkı (varsa)
              if (_selectedPreset!.accessories.any((a) => a.type == 'scarf'))
                Positioned(
                  bottom: -5,
                  child: Container(
                    width: 65,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.scarfColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    
    // Varsayılan avatar
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.softPinkButton.withValues(alpha: 0.3),
            width: 3,
          ),
        ),
        child: Icon(
          Icons.add_a_photo,
          size: 50,
          color: AppColors.softPinkButton.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Color _getSkinColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'pink':
        return AppColors.pinkSkin;
      case 'blue':
        return AppColors.blueSkin;
      case 'yellow':
        return AppColors.yellowSkin;
      case 'green':
        return AppColors.greenSkin;
      default:
        return AppColors.pinkSkin;
    }
  }

  Color _getEyeColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'black':
        return AppColors.blackEye;
      case 'brown':
        return AppColors.brownEye;
      case 'blue':
        return AppColors.blueEye;
      default:
        return AppColors.blackEye;
    }
  }
  
  // İstatistik kartları
  Widget _buildStatsCards(WaterProvider waterProvider, UserProvider userProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Toplam İçilen',
            '${(userProvider.userData.totalWaterConsumed / 1000).toStringAsFixed(1)}L',
            Icons.water_drop,
            AppColors.waterColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Seri',
            '${userProvider.consecutiveDays} gün',
            Icons.local_fire_department,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Coin',
            '${waterProvider.tankCoins}',
            Icons.monetization_on,
            AppColors.goldCoin,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
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
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4A5568),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // Haftalık grafik
  Widget _buildWeeklyChart() {
    // Basit haftalık grafik (örnek veriler)
    final weeklyData = [0.3, 0.5, 0.7, 0.4, 0.6, 0.8, 0.9]; // Son 7 gün
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
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
            'Son 7 Gün',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeklyData.asMap().entries.map((entry) {
                final index = entry.key;
                final value = entry.value;
                final dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 30,
                      height: value * 100,
                      decoration: BoxDecoration(
                        color: AppColors.waterColor.withValues(alpha: 0.7),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dayNames[index],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  // Günlük hedef slider
  Widget _buildDailyGoalSlider(WaterProvider waterProvider) {
    // Slider değerini güncelle
    if (_dailyGoalSlider != waterProvider.dailyGoal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _dailyGoalSlider = waterProvider.dailyGoal;
          });
        }
      });
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Günlük Hedef',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A5568),
                ),
              ),
              Text(
                '${(_dailyGoalSlider / 1000).toStringAsFixed(1)}L',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.softPinkButton,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: _dailyGoalSlider,
            min: 1500.0,
            max: 5000.0,
            divisions: 35, // 0.1L adımlarla
            label: '${(_dailyGoalSlider / 1000).toStringAsFixed(1)}L',
            activeColor: AppColors.softPinkButton,
            inactiveColor: AppColors.softPinkButton.withValues(alpha: 0.3),
            onChanged: (value) {
              setState(() {
                _dailyGoalSlider = value;
              });
            },
            onChangeEnd: (value) {
              waterProvider.updateDailyGoal(value);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '1.5L',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4A5568),
                ),
              ),
              Text(
                '5L',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4A5568),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Aksolot preset modeli
class AxolotlPreset {
  final String name;
  final String description;
  final String skinColor;
  final String eyeColor;
  final List<Accessory> accessories;

  AxolotlPreset({
    required this.name,
    required this.description,
    required this.skinColor,
    required this.eyeColor,
    required this.accessories,
  });
}
