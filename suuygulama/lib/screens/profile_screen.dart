import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../utils/unit_converter.dart';
import '../providers/water_provider.dart';
import '../providers/user_provider.dart';
import 'reset_time_screen.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/app_card.dart';
import '../widgets/profile/gender_dialog.dart';
import '../widgets/profile/weight_dialog.dart';
import '../widgets/profile/activity_dialog.dart';
import '../widgets/profile/climate_dialog.dart';
import '../core/constants/app_constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSubtle,
      resizeToAvoidBottomInset: true, // Klavye açıldığında ekranın yukarı kayması
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
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
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
                      onTap: () => GenderDialog.show(
                        context,
                        userProvider,
                        (message) => _showSuccessSnackBar(context, message),
                      ),
                    ),
                    _buildProfileButton(
                      icon: Icons.monitor_weight,
                      label: 'Kilo',
                      value: (userProvider.userData.weight != null && userProvider.userData.weight! > 0)
                          ? UnitConverter.formatWeight(userProvider.userData.weight!, userProvider.isMetric)
                          : 'Girilmemiş',
                      isPlaceholder: (userProvider.userData.weight == null || userProvider.userData.weight! <= 0),
                      onTap: () => WeightDialog.show(
                        context,
                        userProvider,
                        (message) => _showSuccessSnackBar(context, message),
                      ),
                    ),
                    _buildProfileButton(
                      icon: Icons.directions_run,
                      label: 'Aktivite',
                      value: _getActivityText(userProvider.userData.activityLevel),
                      isPlaceholder: userProvider.userData.activityLevel == null,
                      onTap: () => ActivityDialog.show(
                        context,
                        userProvider,
                        (message) => _showSuccessSnackBar(context, message),
                      ),
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
                    _buildProfileButton(
                      icon: Icons.wb_sunny,
                      label: 'İklim',
                      value: _getClimateText(userProvider.userData.climate),
                      isPlaceholder: userProvider.userData.climate == null,
                      onTap: () => ClimateDialog.show(
                        context,
                        userProvider,
                        (message) => _showSuccessSnackBar(context, message),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: AppConstants.largePadding),
                
                // Birim ve Hatırlatıcılar
                _buildSection(
                  title: 'Birim ve Hatırlatıcılar',
                  children: [
                    Consumer<UserProvider>(
                      builder: (context, userProvider, child) {
                        return _buildProfileButton(
                          icon: Icons.straighten,
                          label: 'Birim',
                          value: userProvider.isMetric ? 'ml' : 'oz',
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
                
                SizedBox(height: AppConstants.largePadding),
                
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
                
                SizedBox(height: AppConstants.largePadding),
                
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
                
                SizedBox(height: AppConstants.extraLargePadding),
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
          padding: const EdgeInsets.only(
          left: AppConstants.smallSpacing,
          bottom: AppConstants.defaultSpacing,
        ),
          child: Text(
            title,
            style: AppTextStyles.heading3,
          ),
        ),
        AppCardContainer(
          padding: EdgeInsets.zero,
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: AppConstants.mediumSpacing,
        ),
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
            SizedBox(width: AppConstants.mediumSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyLarge,
                  ),
                  if (value.isNotEmpty) ...[
                    SizedBox(height: AppConstants.smallSpacing),
                    Text(
                      value,
                      style: isPlaceholder 
                          ? AppTextStyles.placeholder
                          : AppTextStyles.bodyGrey,
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

  String _getClimateText(String? climate) {
    if (climate == null) {
      return 'Belirtilmemiş';
    }
    switch (climate) {
      case 'very_hot':
        return 'Çok Sıcak';
      case 'hot':
        return 'Sıcak';
      case 'warm':
        return 'Ilıman';
      case 'cold':
        return 'Soğuk';
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
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        margin: const EdgeInsets.all(AppConstants.mediumSpacing),
        duration: const Duration(seconds: 2),
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
        content: SingleChildScrollView(
          child: Column(
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
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) {
                controller.dispose();
                Navigator.pop(context);
              }
            },
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              if (!mounted) return;
              final goal = double.tryParse(controller.text);
              if (goal != null && goal > 0 && goal <= 10) {
                await waterProvider.updateDailyGoal(goal * 1000); // ml'ye çevir
                
                // Kullanıcı hedef belirledi olarak işaretle
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('custom_goal_set', true);
                
                if (!context.mounted) return;
                controller.dispose();
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
    ).then((_) {
      // Dialog kapandığında controller'ı temizle (güvenli dispose)
      if (mounted) {
        controller.dispose();
      }
    });
  }

  void _showUnitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Dialog içinde de Provider'dan güncel değeri al (watch ile)
          final currentUserProvider = context.watch<UserProvider>();
          final currentIsMetric = currentUserProvider.isMetric;
          
          return AlertDialog(
            title: const Text('Birim Seç'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('ml (Mililitre)'),
                  leading: Icon(
                    currentIsMetric ? Icons.check_circle : Icons.circle_outlined,
                    color: currentIsMetric ? AppColors.softPinkButton : Colors.grey,
                  ),
                  onTap: () async {
                    if (!context.mounted) return;
                    await currentUserProvider.setIsMetric(true); // Metric (ml)
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _showSuccessSnackBar(context, 'Birim başarıyla ml olarak güncellendi.');
                  },
                ),
                ListTile(
                  title: const Text('oz (Ons)'),
                  leading: Icon(
                    !currentIsMetric ? Icons.check_circle : Icons.circle_outlined,
                    color: !currentIsMetric ? AppColors.softPinkButton : Colors.grey,
                  ),
                  onTap: () async {
                    if (!context.mounted) return;
                    await currentUserProvider.setIsMetric(false); // Imperial (oz)
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _showSuccessSnackBar(context, 'Birim başarıyla oz olarak güncellendi.');
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
