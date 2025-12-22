import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
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
                      onTap: () => _showGenderDialog(context, userProvider),
                    ),
                    _buildProfileButton(
                      icon: Icons.height,
                      label: 'Boy',
                      value: userProvider.userData.height != null
                          ? '${userProvider.userData.height!.toStringAsFixed(0)} cm'
                          : 'Belirtilmemiş',
                      onTap: () => _showHeightDialog(context, userProvider),
                    ),
                    _buildProfileButton(
                      icon: Icons.monitor_weight,
                      label: 'Kilo',
                      value: userProvider.userData.weight != null
                          ? '${userProvider.userData.weight!.toStringAsFixed(1)} kg'
                          : 'Belirtilmemiş',
                      onTap: () => _showWeightDialog(context, userProvider),
                    ),
                    _buildProfileButton(
                      icon: Icons.directions_run,
                      label: 'Aktivite',
                      value: _getActivityText(userProvider.userData.activityLevel),
                      onTap: () => _showActivityDialog(context, userProvider),
                    ),
                    _buildProfileButton(
                      icon: Icons.flag,
                      label: 'Hedef',
                      value: '${(waterProvider.dailyGoal / 1000).toStringAsFixed(1)}L',
                      onTap: () => _showCustomGoalDialog(context, waterProvider),
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
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
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
              },
            ),
            ListTile(
              title: const Text('Erkek'),
              onTap: () async {
                await userProvider.updateProfile(gender: 'male');
                if (!context.mounted) return;
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Belirtmek İstemiyorum'),
              onTap: () async {
                await userProvider.updateProfile(gender: 'other');
                if (!context.mounted) return;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHeightDialog(BuildContext context, UserProvider userProvider) {
    final controller = TextEditingController(
      text: userProvider.userData.height?.toStringAsFixed(0) ?? '',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Boy (cm)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Örn: 170',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              final height = double.tryParse(controller.text);
              if (height != null && height > 0) {
                await userProvider.updateProfile(height: height);
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showWeightDialog(BuildContext context, UserProvider userProvider) {
    final controller = TextEditingController(
      text: userProvider.userData.weight?.toStringAsFixed(1) ?? '',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kilo (kg)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Örn: 70',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              final weight = double.tryParse(controller.text);
              if (weight != null && weight > 0) {
                await userProvider.updateProfile(weight: weight);
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
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
              },
            ),
            ListTile(
              title: const Text('Orta'),
              onTap: () async {
                await userProvider.updateProfile(activityLevel: 'medium');
                if (!context.mounted) return;
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Yüksek'),
              onTap: () async {
                await userProvider.updateProfile(activityLevel: 'high');
                if (!context.mounted) return;
                Navigator.pop(context);
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
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Günlük hedef ${goal.toStringAsFixed(1)}L olarak ayarlandı'),
                    backgroundColor: AppColors.softPinkButton,
                  ),
                );
              } else {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen 0 ile 10 litre arası bir değer girin'),
                    backgroundColor: Colors.red,
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
