import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../utils/app_colors.dart';
import '../providers/water_provider.dart';
import '../providers/user_provider.dart';
import '../providers/drink_provider.dart';
import '../models/drink_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  double _dailyGoalSlider = 5000.0; // Günlük hedef slider değeri
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  
  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

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
          
          // Boy ve kilo değerlerini yükle
          if (_heightController.text.isEmpty && userProvider.userData.height != null) {
            _heightController.text = userProvider.userData.height!.toStringAsFixed(0);
          }
          if (_weightController.text.isEmpty && userProvider.userData.weight != null) {
            _weightController.text = userProvider.userData.weight!.toStringAsFixed(1);
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
                
                // Boy ve Kilo Girişi
                _buildHeightWeightInput(waterProvider, userProvider),
                const SizedBox(height: 30),
                
                // Günlük Hedef Ayarı
                _buildDailyGoalSlider(waterProvider),
                const SizedBox(height: 30),
                
                // İçecek Yönetimi
                _buildDrinkManagement(),
                const SizedBox(height: 30),
            
            // Test Butonları
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Kirliliği Simüle Et Butonu
                ElevatedButton.icon(
                  onPressed: () async {
                    await waterProvider.simulateDirtyTank();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tank kirliliği simüle edildi (25 saat öncesi)'),
                        backgroundColor: Colors.orange,
                      ),
                    );
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
                    if (!context.mounted) return;
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
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Veriler sıfırlandı')),
                      );
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
  
  // İstatistik kartları
  Widget _buildStatsCards(WaterProvider waterProvider, UserProvider userProvider) {
    return Column(
      children: [
        Row(
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
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Günlük Kalori',
                '${waterProvider.dailyCalories.toStringAsFixed(0)} kcal',
                Icons.local_fire_department,
                Colors.red,
              ),
            ),
          ],
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
  
  // Boy ve Kilo girişi
  Widget _buildHeightWeightInput(WaterProvider waterProvider, UserProvider userProvider) {
    final bmi = userProvider.bmi;
    final idealGoal = userProvider.calculateIdealWaterGoal();
    
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
            'Vücut Bilgileri',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _heightController,
                  decoration: InputDecoration(
                    labelText: 'Boy (cm)',
                    hintText: 'Örn: 170',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) async {
                    if (value.isNotEmpty) {
                      final height = double.tryParse(value);
                      final weight = _weightController.text.isNotEmpty
                          ? double.tryParse(_weightController.text)
                          : userProvider.userData.weight;
                      if (height != null && height > 0) {
                        await userProvider.updateHeightWeight(height, weight);
                        // İdeal hedefi güncelle
                        if (weight != null) {
                          final newIdealGoal = userProvider.calculateIdealWaterGoal();
                          await waterProvider.updateDailyGoal(newIdealGoal);
                        }
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _weightController,
                  decoration: InputDecoration(
                    labelText: 'Kilo (kg)',
                    hintText: 'Örn: 70',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) async {
                    if (value.isNotEmpty) {
                      final weight = double.tryParse(value);
                      final height = _heightController.text.isNotEmpty
                          ? double.tryParse(_heightController.text)
                          : userProvider.userData.height;
                      if (weight != null && weight > 0) {
                        await userProvider.updateHeightWeight(height, weight);
                        // İdeal hedefi güncelle
                        if (height != null) {
                          final newIdealGoal = userProvider.calculateIdealWaterGoal();
                          await waterProvider.updateDailyGoal(newIdealGoal);
                        }
                      }
                    }
                  },
                ),
              ),
            ],
          ),
          if (bmi != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'VKE: ${bmi.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A5568),
                  ),
                ),
                Text(
                  'İdeal Hedef: ${(idealGoal / 1000).toStringAsFixed(1)}L',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.softPinkButton,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
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

  // İçecek Yönetimi Bölümü
  Widget _buildDrinkManagement() {
    return Consumer<DrinkProvider>(
      builder: (context, drinkProvider, child) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'İçecekleri Yönet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddDrinkDialog(drinkProvider),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Yeni Ekle'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.softPinkButton,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Özel İçecekler Listesi
              if (drinkProvider.customDrinks.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Henüz özel içecek eklenmemiş',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                )
              else
                ...drinkProvider.customDrinks.map((drink) {
                  return _buildDrinkManagementItem(drink, drinkProvider);
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrinkManagementItem(Drink drink, DrinkProvider drinkProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drink.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A5568),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(drink.hydrationFactor * 100).toStringAsFixed(0)}% hidrasyon • ${drink.caloriePer100ml.toStringAsFixed(0)} kcal/100ml',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            color: AppColors.softPinkButton,
            onPressed: () => _showEditDrinkDialog(drink, drinkProvider),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            color: Colors.red,
            onPressed: () => _showDeleteDrinkDialog(drink, drinkProvider),
          ),
        ],
      ),
    );
  }

  void _showAddDrinkDialog(DrinkProvider drinkProvider) {
    final nameController = TextEditingController();
    final calorieController = TextEditingController();
    final hydrationController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Yeni İçecek Ekle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'İçecek Adı',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: calorieController,
                decoration: InputDecoration(
                  labelText: 'Kalori (100ml başına)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: hydrationController,
                decoration: InputDecoration(
                  labelText: 'Hidrasyon Faktörü (0.0-1.0)',
                  hintText: 'Örn: 0.8 (%80)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final calorie = double.tryParse(calorieController.text);
              final hydration = double.tryParse(hydrationController.text);
              
              if (name.isNotEmpty && calorie != null && hydration != null && 
                  hydration >= 0.0 && hydration <= 1.0) {
                final newDrink = Drink(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  caloriePer100ml: calorie,
                  hydrationFactor: hydration,
                );
                await drinkProvider.addCustomDrink(newDrink);
                if (!context.mounted) return;
                Navigator.pop(context);
              } else {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen tüm alanları doğru şekilde doldurun'),
                  ),
                );
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showEditDrinkDialog(Drink drink, DrinkProvider drinkProvider) {
    final nameController = TextEditingController(text: drink.name);
    final calorieController = TextEditingController(text: drink.caloriePer100ml.toString());
    final hydrationController = TextEditingController(text: drink.hydrationFactor.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('İçeceği Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'İçecek Adı',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: calorieController,
                decoration: InputDecoration(
                  labelText: 'Kalori (100ml başına)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: hydrationController,
                decoration: InputDecoration(
                  labelText: 'Hidrasyon Faktörü (0.0-1.0)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final calorie = double.tryParse(calorieController.text);
              final hydration = double.tryParse(hydrationController.text);
              
              if (name.isNotEmpty && calorie != null && hydration != null && 
                  hydration >= 0.0 && hydration <= 1.0) {
                final updatedDrink = Drink(
                  id: drink.id,
                  name: name,
                  caloriePer100ml: calorie,
                  hydrationFactor: hydration,
                );
                await drinkProvider.updateCustomDrink(drink.id, updatedDrink);
                if (!context.mounted) return;
                Navigator.pop(context);
              } else {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen tüm alanları doğru şekilde doldurun'),
                  ),
                );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDrinkDialog(Drink drink, DrinkProvider drinkProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('İçeceği Sil'),
        content: Text('${drink.name} içeceğini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              await drinkProvider.deleteCustomDrink(drink.id);
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

