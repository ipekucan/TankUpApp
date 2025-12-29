import 'package:flutter/material.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_text_styles.dart';

/// Dialog for selecting gender.
class GenderDialog extends StatelessWidget {
  final UserProvider userProvider;
  final Function(String) onSuccess;

  const GenderDialog({
    super.key,
    required this.userProvider,
    required this.onSuccess,
  });

  /// Shows the gender selection dialog
  static Future<void> show(
    BuildContext context,
    UserProvider userProvider,
    Function(String) onSuccess,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => GenderDialog(
        userProvider: userProvider,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Cinsiyet Seç',
        style: AppTextStyles.heading3,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('Kadın', style: AppTextStyles.bodyLarge),
            onTap: () async {
              await userProvider.updateProfile(gender: 'female');
              if (!context.mounted) return;
              Navigator.pop(context);
              onSuccess('Cinsiyet bilginiz güncellendi!');
            },
          ),
          ListTile(
            title: Text('Erkek', style: AppTextStyles.bodyLarge),
            onTap: () async {
              await userProvider.updateProfile(gender: 'male');
              if (!context.mounted) return;
              Navigator.pop(context);
              onSuccess('Cinsiyet bilginiz güncellendi!');
            },
          ),
          ListTile(
            title: Text('Belirtmek İstemiyorum', style: AppTextStyles.bodyLarge),
            onTap: () async {
              await userProvider.updateProfile(gender: 'other');
              if (!context.mounted) return;
              Navigator.pop(context);
              onSuccess('Cinsiyet bilginiz güncellendi!');
            },
          ),
        ],
      ),
    );
  }
}

