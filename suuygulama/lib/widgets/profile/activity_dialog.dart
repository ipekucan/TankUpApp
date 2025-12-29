import 'package:flutter/material.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_text_styles.dart';

/// Dialog for selecting activity level.
class ActivityDialog extends StatelessWidget {
  final UserProvider userProvider;
  final Function(String) onSuccess;

  const ActivityDialog({
    super.key,
    required this.userProvider,
    required this.onSuccess,
  });

  /// Shows the activity level selection dialog
  static Future<void> show(
    BuildContext context,
    UserProvider userProvider,
    Function(String) onSuccess,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => ActivityDialog(
        userProvider: userProvider,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Aktivite Seviyesi', style: AppTextStyles.heading3),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('Düşük', style: AppTextStyles.bodyLarge),
            onTap: () async {
              await userProvider.updateProfile(activityLevel: 'low');
              if (!context.mounted) return;
              Navigator.pop(context);
              onSuccess('Aktivite seviyeniz güncellendi!');
            },
          ),
          ListTile(
            title: Text('Orta', style: AppTextStyles.bodyLarge),
            onTap: () async {
              await userProvider.updateProfile(activityLevel: 'medium');
              if (!context.mounted) return;
              Navigator.pop(context);
              onSuccess('Aktivite seviyeniz güncellendi!');
            },
          ),
          ListTile(
            title: Text('Yüksek', style: AppTextStyles.bodyLarge),
            onTap: () async {
              await userProvider.updateProfile(activityLevel: 'high');
              if (!context.mounted) return;
              Navigator.pop(context);
              onSuccess('Aktivite seviyeniz güncellendi!');
            },
          ),
        ],
      ),
    );
  }
}

