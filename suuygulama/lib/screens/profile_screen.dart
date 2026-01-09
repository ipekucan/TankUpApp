import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../utils/unit_converter.dart';
import '../providers/daily_hydration_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/app_card.dart';
import '../widgets/profile/gender_dialog.dart';
import '../widgets/profile/weight_dialog.dart';
import '../widgets/profile/activity_dialog.dart';
import '../widgets/profile/climate_dialog.dart';
import '../core/constants/app_constants.dart';
import '../core/services/logger_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Color palette constants
  static const Color _profileCream = Color(0xFFFFF4E2);
  static const Color _profileGold = Color(0xFFD0C6A4);
  static const Color _unitsRemindersPink = Color(0xFFF7E1DE);
  static const Color _unitsRemindersRose = Color(0xFFD19589);
  static const Color _developerBlue = Color(0xFFD2ECF9);
  static const Color _developerBlueGrey = Color(0xFF7595A7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F9), // Clean off-white
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
            vertical: 16,
          ),
          child: Consumer2<DailyHydrationProvider, UserProvider>(
            builder: (context, dailyHydrationProvider, userProvider, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  _buildSection(
                    title: 'Profil',
                    children: [
                      _buildProfileButton(
                        icon: Icons.person,
                        label: 'Cinsiyet',
                        value: _getGenderText(userProvider.userData.gender),
                        isPlaceholder: userProvider.userData.gender == null,
                        backgroundColor: _profileCream,
                        iconColor: _profileGold,
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
                        backgroundColor: _profileCream,
                        iconColor: _profileGold,
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
                        backgroundColor: _profileCream,
                        iconColor: _profileGold,
                        onTap: () => ActivityDialog.show(
                          context,
                          userProvider,
                          (message) => _showSuccessSnackBar(context, message),
                        ),
                      ),
                      Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                          return FutureBuilder<bool>(
                            future: _isGoalCustomSet(dailyHydrationProvider),
                            builder: (context, snapshot) {
                              final isCustomGoal = snapshot.data ?? false;
                              String goalValue = 'Belirtilmemiş';
                              if (isCustomGoal) {
                                goalValue = UnitConverter.formatVolume(
                                  dailyHydrationProvider.dailyGoal,
                                  userProvider.isMetric,
                                );
                              }
                              return _buildProfileButton(
                                icon: Icons.flag,
                                label: 'Hedef',
                                value: goalValue,
                                isPlaceholder: !isCustomGoal,
                                backgroundColor: _profileCream,
                                iconColor: _profileGold,
                                onTap: () => _showCustomGoalDialog(context, dailyHydrationProvider),
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
                        backgroundColor: _profileCream,
                        iconColor: _profileGold,
                        onTap: () => ClimateDialog.show(
                          context,
                          userProvider,
                          (message) => _showSuccessSnackBar(context, message),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Units & Reminders Section
                  _buildSection(
                    title: 'Birim ve Hatırlatıcılar',
                    children: [
                      Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                          return _buildProfileButton(
                            icon: Icons.straighten,
                            label: 'Birim',
                            value: userProvider.isMetric ? 'ml' : 'oz',
                            backgroundColor: _unitsRemindersPink,
                            iconColor: _unitsRemindersRose,
                            onTap: () => _showUnitDialog(context),
                          );
                        },
                      ),
                      _buildProfileButton(
                        icon: Icons.notifications,
                        label: 'Hatırlatma Programı',
                        value: 'Bildirim saatleri',
                        backgroundColor: _unitsRemindersPink,
                        iconColor: _unitsRemindersRose,
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
                        backgroundColor: _unitsRemindersPink,
                        iconColor: _unitsRemindersRose,
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
                  
                  const SizedBox(height: 20),
                  
                  // Developer Section
                  _buildSection(
                    title: 'Geliştirici',
                    children: [
                      _buildProfileButton(
                        icon: Icons.feedback,
                        label: 'Geri Bildirim',
                        value: '',
                        backgroundColor: _developerBlue,
                        iconColor: _developerBlueGrey,
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
                        backgroundColor: _developerBlue,
                        iconColor: _developerBlueGrey,
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
                        backgroundColor: _developerBlue,
                        iconColor: _developerBlueGrey,
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
                  
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
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
    required Color backgroundColor,
    required Color iconColor,
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
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20), // Softer corners
              ),
              child: Icon(
                icon,
                color: iconColor,
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
  Future<bool> _isGoalCustomSet(DailyHydrationProvider dailyHydrationProvider) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Eğer 'custom_goal_set' flag'i varsa, kullanıcı manuel olarak ayarlamıştır
      final isCustomSet = prefs.getBool('custom_goal_set') ?? false;
      
      // Eğer flag yoksa, dailyGoal'un varsayılan değerlerden farklı olup olmadığını kontrol et
      if (!isCustomSet) {
        // Varsayılan değerler: 5000.0 (5L) veya 2000.0 (2L - skip onboarding)
        final currentGoal = dailyHydrationProvider.dailyGoal;
        // Eğer varsayılan değerlerden biri değilse, kullanıcı ayarlamış olabilir
        return currentGoal != 5000.0 && currentGoal != 2000.0;
      }
      
      return isCustomSet;
    } catch (e, stackTrace) {
      LoggerService.logError('Failed to check if daily goal is custom set', e, stackTrace);
      return false;
    }
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


  void _showCustomGoalDialog(BuildContext context, DailyHydrationProvider dailyHydrationProvider) {
    showDialog(
      context: context,
      builder: (context) => _GoalUpdateDialog(
        currentGoal: dailyHydrationProvider.dailyGoal,
        dailyHydrationProvider: dailyHydrationProvider,
      ),
    );
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

/// Goal Update Dialog Widget - Fixes TextEditingController disposal bug
/// 
/// This StatefulWidget ensures the controller is only disposed when the widget
/// is permanently removed from the tree, not during dialog exit animation.
class _GoalUpdateDialog extends StatefulWidget {
  final double currentGoal; // in ml
  final DailyHydrationProvider dailyHydrationProvider;

  const _GoalUpdateDialog({
    required this.currentGoal,
    required this.dailyHydrationProvider,
  });

  @override
  State<_GoalUpdateDialog> createState() => _GoalUpdateDialogState();
}

class _GoalUpdateDialogState extends State<_GoalUpdateDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller with current goal (convert ml to liters)
    _controller = TextEditingController(
      text: (widget.currentGoal / 1000).toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    // Safe disposal: only happens when widget is permanently removed
    _controller.dispose();
    super.dispose();
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!mounted) return;
    
    final goal = double.tryParse(_controller.text);
    
    if (goal != null && goal > 0 && goal <= 10) {
      // Valid goal: update provider
      await widget.dailyHydrationProvider.updateDailyGoal(goal * 1000); // Convert to ml
      
      // Mark that user has set custom goal
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('custom_goal_set', true);
      
      if (!mounted) return;
      Navigator.pop(context);
      _showSuccessSnackBar(context, 'Günlük su hedefiniz yenilendi!');
    } else {
      // Invalid goal: show error
      if (!mounted) return;
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
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Günlük Su Hedefi'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Hedef (Litre)',
                hintText: 'Örn: 2.4',
                suffixText: 'L',
              ),
              autofocus: true,
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
            Navigator.pop(context);
          },
          child: const Text('İptal'),
        ),
        TextButton(
          onPressed: _handleSave,
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
