import 'package:flutter/material.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Dialog for selecting climate.
class ClimateDialog extends StatelessWidget {
  final UserProvider userProvider;
  final Function(String) onSuccess;

  const ClimateDialog({
    super.key,
    required this.userProvider,
    required this.onSuccess,
  });

  /// Shows the climate selection dialog
  static Future<void> show(
    BuildContext context,
    UserProvider userProvider,
    Function(String) onSuccess,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => ClimateDialog(
        userProvider: userProvider,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentClimate = userProvider.userData.climate;

    return AlertDialog(
      title: Text('İklim Seçimi', style: AppTextStyles.heading3),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildClimateOption(
            context,
            icon: Icons.wb_sunny,
            title: 'Çok Sıcak',
            value: 'very_hot',
            currentClimate: currentClimate,
            onTap: () async {
              await userProvider.updateProfile(climate: 'very_hot');
              if (!context.mounted) return;
              Navigator.pop(context);
              onSuccess('İklim başarıyla güncellendi!');
            },
          ),
          _buildClimateOption(
            context,
            icon: Icons.wb_twilight,
            title: 'Sıcak',
            value: 'hot',
            currentClimate: currentClimate,
            onTap: () async {
              await userProvider.updateProfile(climate: 'hot');
              if (!context.mounted) return;
              Navigator.pop(context);
              onSuccess('İklim başarıyla güncellendi!');
            },
          ),
          _buildClimateOption(
            context,
            icon: Icons.wb_cloudy,
            title: 'Ilıman',
            value: 'warm',
            currentClimate: currentClimate,
            onTap: () async {
              await userProvider.updateProfile(climate: 'warm');
              if (!context.mounted) return;
              Navigator.pop(context);
              onSuccess('İklim başarıyla güncellendi!');
            },
          ),
          _buildClimateOption(
            context,
            icon: Icons.ac_unit,
            title: 'Soğuk',
            value: 'cold',
            currentClimate: currentClimate,
            onTap: () async {
              await userProvider.updateProfile(climate: 'cold');
              if (!context.mounted) return;
              Navigator.pop(context);
              onSuccess('İklim başarıyla güncellendi!');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClimateOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String? currentClimate,
    required VoidCallback onTap,
  }) {
    final isSelected = currentClimate == value;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.softPinkButton : Colors.grey[400],
      ),
      title: Text(title, style: AppTextStyles.bodyLarge),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppColors.softPinkButton)
          : null,
      onTap: onTap,
    );
  }
}

