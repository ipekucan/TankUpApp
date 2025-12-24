import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../utils/unit_converter.dart';
import '../providers/water_provider.dart';
import '../providers/user_provider.dart';
import 'reset_time_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.verySoftBlue,
      appBar: AppBar(
        title: const Text(
          'Ayarlar',
          style: TextStyle(
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Consumer2<WaterProvider, UserProvider>(
          builder: (context, waterProvider, userProvider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profil Bölümü
                _buildSection(
                  title: 'Profil',
                  children: [
                    _buildProfileButton(
                      icon: Icons.person,
                      label: 'Cinsiyet',
                      value: _getGenderText(userProvider.userData.gender),
                      isPlaceholder: userProvider.userData.gender == null,
                      onTap: () => _showGenderDialog(context, userProvider),
                    ),
                    _buildProfileButton(
                      icon: Icons.monitor_weight,
                      label: 'Kilo',
                      value: (userProvider.userData.weight != null && userProvider.userData.weight! > 0)
                          ? UnitConverter.formatWeight(userProvider.userData.weight!, userProvider.isMetric)
                          : 'Girilmemiş',
                      isPlaceholder: (userProvider.userData.weight == null || userProvider.userData.weight! <= 0),
                      onTap: () => _showWeightDialog(context, userProvider),
                    ),
                    _buildProfileButton(
                      icon: Icons.directions_run,
                      label: 'Aktivite',
                      value: _getActivityText(userProvider.userData.activityLevel),
                      isPlaceholder: userProvider.userData.activityLevel == null,
                      onTap: () => _showActivityDialog(context, userProvider),
                    ),
                    Consumer<UserProvider>(
                      builder: (context, userProvider, child) {
                        return FutureBuilder<bool>(
                          future: _isGoalCustomSet(waterProvider),
                          builder: (context, snapshot) {
                            final isCustomGoal = snapshot.data ?? false;
                            String goalValue = 'Belirtilmemiş';
                            if (isCustomGoal) {
                              goalValue = UnitConverter.formatVolume(waterProvider.dailyGoal, userProvider.isMetric);
                            }
                            return _buildProfileButton(
                              icon: Icons.flag,
                              label: 'Hedef',
                              value: goalValue,
                              isPlaceholder: !isCustomGoal,
                              onTap: () => _showCustomGoalDialog(context, waterProvider),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Birim ve Hatırlatıcılar
                _buildSection(
                  title: 'Birim ve Hatırlatıcılar',
                  children: [
                    FutureBuilder<String>(
                      future: _getPreferredUnitAsync(),
                      builder: (context, snapshot) {
                        return _buildProfileButton(
                          icon: Icons.straighten,
                          label: 'Birim',
                          value: snapshot.data ?? 'ml',
                          onTap: () => _showUnitDialog(context),
                        );
                      },
                    ),
                    _buildProfileButton(
                      icon: Icons.notifications,
                      label: 'Hatırlatma Programı',
                      value: 'Bildirim saatleri',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Hatırlatma Programı - Yakında'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    _buildProfileButton(
                      icon: Icons.volume_up,
                      label: 'Hatırlatma Sesi',
                      value: 'Varsayılan',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Hatırlatma Sesi - Yakında'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Gün Sıfırlama Saati
                _buildSection(
                  title: 'Gün Ayarları',
                  children: [
                    FutureBuilder<String>(
                      future: _getResetTimeAsync(),
                      builder: (context, snapshot) {
                        return _buildProfileButton(
                          icon: Icons.refresh,
                          label: 'Gün Sıfırlama Saati',
                          value: snapshot.data ?? '00:00',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ResetTimeScreen(),
                              ),
                            ).then((_) {
                              setState(() {}); // Geri dönünce güncelle
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Geliştirici Bölümü
                _buildSection(
                  title: 'Geliştirici',
                  children: [
                    _buildProfileButton(
                      icon: Icons.feedback,
                      label: 'Geri Bildirim',
                      value: '',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Geri Bildirim - Yakında'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    _buildProfileButton(
                      icon: Icons.star,
                      label: 'Uygulamayı Değerlendir',
                      value: '',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Uygulamayı Değerlendir - Yakında'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    _buildProfileButton(
                      icon: Icons.share,
                      label: 'Uygulamayı Paylaş',
                      value: '',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Uygulamayı Paylaş - Yakında'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A5568),
            ),
          ),
        ),
        Container(
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
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileButton({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool isPlaceholder = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.softPinkButton.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.softPinkButton,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                  if (value.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        color: isPlaceholder 
                            ? Colors.grey[400] 
                            : Colors.grey[600],
                        fontStyle: isPlaceholder 
                            ? FontStyle.italic 
                            : FontStyle.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _getGenderText(String? gender) {
    switch (gender) {
      case 'male':
        return 'Erkek';
      case 'female':
        return 'Kadın';
      case 'other':
        return 'Belirtmek İstemiyorum';
      default:
        return 'Belirtilmemiş';
    }
  }

  String _getActivityText(String? activityLevel) {
    if (activityLevel == null) {
      return 'Belirtilmemiş';
    }
    switch (activityLevel) {
      case 'low':
        return 'Düşük';
      case 'medium':
        return 'Orta';
      case 'high':
        return 'Yüksek';
      default:
        return 'Belirtilmemiş';
    }
  }

  // Hedefin kullanıcı tarafından özelleştirilip özelleştirilmediğini kontrol et
  Future<bool> _isGoalCustomSet(WaterProvider waterProvider) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Eğer 'custom_goal_set' flag'i varsa, kullanıcı manuel olarak ayarlamıştır
      final isCustomSet = prefs.getBool('custom_goal_set') ?? false;
      
      // Eğer flag yoksa, dailyGoal'un varsayılan değerlerden farklı olup olmadığını kontrol et
      if (!isCustomSet) {
        // Varsayılan değerler: 5000.0 (5L) veya 2000.0 (2L - skip onboarding)
        final currentGoal = waterProvider.dailyGoal;
        // Eğer varsayılan değerlerden biri değilse, kullanıcı ayarlamış olabilir
        return currentGoal != 5000.0 && currentGoal != 2000.0;
      }
      
      return isCustomSet;
    } catch (e) {
      return false;
    }
  }

  Future<String> _getPreferredUnitAsync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('preferred_unit') ?? 'ml';
  }

  Future<String> _getResetTimeAsync() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('reset_time_hour') ?? 0;
    final minute = prefs.getInt('reset_time_minute') ?? 0;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  // Pembe tonlarında, yuvarlatılmış köşeli ve modern SnackBar göster
  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
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
  }

  void _showGenderDialog(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cinsiyet Seç'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Kadın'),
              onTap: () async {
                await userProvider.updateProfile(gender: 'female');
                if (!context.mounted) return;
                Navigator.pop(context);
                _showSuccessSnackBar(context, 'Cinsiyet bilginiz güncellendi!');
              },
            ),
            ListTile(
              title: const Text('Erkek'),
              onTap: () async {
                await userProvider.updateProfile(gender: 'male');
                if (!context.mounted) return;
                Navigator.pop(context);
                _showSuccessSnackBar(context, 'Cinsiyet bilginiz güncellendi!');
              },
            ),
            ListTile(
              title: const Text('Belirtmek İstemiyorum'),
              onTap: () async {
                await userProvider.updateProfile(gender: 'other');
                if (!context.mounted) return;
                Navigator.pop(context);
                _showSuccessSnackBar(context, 'Cinsiyet bilginiz güncellendi!');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showWeightDialog(BuildContext context, UserProvider userProvider) {
    // Birim seçimi için state - mevcut isMetric değerini kullan
    bool isKg = userProvider.isMetric;
    
    // Mevcut kiloyu kg olarak al
    final currentWeightKg = userProvider.userData.weight ?? 0.0;
    
    // TextField için controller
    final TextEditingController textController = TextEditingController();
    
    // Mevcut değeri birime göre göster
    if (currentWeightKg > 0) {
      if (isKg) {
        textController.text = currentWeightKg.toStringAsFixed(1);
      } else {
        textController.text = (currentWeightKg * 2.20462).toStringAsFixed(1);
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Birim değiştiğinde değeri güncelle
          void updateUnit(bool newIsKg) {
            setState(() {
              if (textController.text.isNotEmpty) {
                final currentValue = double.tryParse(textController.text) ?? 0.0;
                // Mevcut değeri kg cinsine çevir
                final valueInKg = isKg ? currentValue : currentValue / 2.20462;
                // Yeni birime göre göster
                final newValue = newIsKg ? valueInKg : valueInKg * 2.20462;
                textController.text = newValue.toStringAsFixed(1);
              }
              isKg = newIsKg;
            });
          }
          
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Kilo Seçiniz',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A5568),
              ),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  
                  // Modern Pill Toggle (Birim Seçici)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // kg Seçeneği
                        GestureDetector(
                          onTap: () => updateUnit(true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: isKg ? AppColors.softPinkButton : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Text(
                              'kg',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isKg ? Colors.white : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        // lbs Seçeneği
                        GestureDetector(
                          onTap: () => updateUnit(false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: !isKg ? AppColors.softPinkButton : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Text(
                              'lbs',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: !isKg ? Colors.white : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Büyük TextField (Manuel Giriş)
                  Center(
                    child: SizedBox(
                      width: 200,
                      child: TextField(
                        controller: textController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4A5568),
                        ),
                        decoration: InputDecoration(
                          hintText: '0.0',
                          hintStyle: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            color: Colors.grey[300],
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: AppColors.softPinkButton,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: AppColors.softPinkButton,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: AppColors.softPinkButton,
                              width: 3,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final textValue = textController.text.trim();
                  if (textValue.isNotEmpty) {
                    final enteredValue = double.tryParse(textValue) ?? 0.0;
                    if (enteredValue > 0) {
                      // Girilen değeri kg'ye çevir
                      final weightInKg = isKg ? enteredValue : enteredValue / 2.20462;
                      await userProvider.updateProfile(weight: weightInKg);
                      // Birim sistemini güncelle (kg = metric, lbs = imperial)
                      await userProvider.setIsMetric(isKg);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _showSuccessSnackBar(context, 'Kilonuz başarıyla kaydedildi!');
                    }
                  } else {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.softPinkButton,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'Tamam',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      // Dialog kapandığında controller'ı temizle
      textController.dispose();
    });
  }

  void _showActivityDialog(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aktivite Seviyesi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Düşük'),
              onTap: () async {
                await userProvider.updateProfile(activityLevel: 'low');
                if (!context.mounted) return;
                Navigator.pop(context);
                _showSuccessSnackBar(context, 'Aktivite seviyeniz güncellendi!');
              },
            ),
            ListTile(
              title: const Text('Orta'),
              onTap: () async {
                await userProvider.updateProfile(activityLevel: 'medium');
                if (!context.mounted) return;
                Navigator.pop(context);
                _showSuccessSnackBar(context, 'Aktivite seviyeniz güncellendi!');
              },
            ),
            ListTile(
              title: const Text('Yüksek'),
              onTap: () async {
                await userProvider.updateProfile(activityLevel: 'high');
                if (!context.mounted) return;
                Navigator.pop(context);
                _showSuccessSnackBar(context, 'Aktivite seviyeniz güncellendi!');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomGoalDialog(BuildContext context, WaterProvider waterProvider) {
    final controller = TextEditingController(
      text: (waterProvider.dailyGoal / 1000).toStringAsFixed(1),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Günlük Su Hedefi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Hedef (Litre)',
                hintText: 'Örn: 2.4',
                suffixText: 'L',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Lütfen günlük su hedefinizi litre cinsinden girin',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF4A5568),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              final goal = double.tryParse(controller.text);
              if (goal != null && goal > 0 && goal <= 10) {
                await waterProvider.updateDailyGoal(goal * 1000); // ml'ye çevir
                
                // Kullanıcı hedef belirledi olarak işaretle
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('custom_goal_set', true);
                
                if (!context.mounted) return;
                Navigator.pop(context);
                _showSuccessSnackBar(context, 'Günlük su hedefiniz yenilendi!');
              } else {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Lütfen 0 ile 10 litre arası bir değer girin'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    margin: const EdgeInsets.all(16),
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

  void _showUnitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Birim Seç'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('ml (Mililitre)'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('preferred_unit', 'ml');
                if (!context.mounted) return;
                Navigator.pop(context);
                setState(() {}); // UI'ı güncelle
              },
            ),
            ListTile(
              title: const Text('oz (Ons)'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('preferred_unit', 'oz');
                if (!context.mounted) return;
                Navigator.pop(context);
                if (mounted) {
                  setState(() {}); // UI'ı güncelle
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
