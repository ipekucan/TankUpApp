import 'package:flutter/material.dart';
import '../../models/achievement_model.dart';
import '../../core/constants/app_constants.dart';
import '../../theme/app_text_styles.dart';

/// Widget that displays an achievement celebration dialog with confetti effect.
class AchievementDialog extends StatelessWidget {
  final Achievement achievement;
  final Color cardColor;
  final String badgeEmoji;

  const AchievementDialog({
    super.key,
    required this.achievement,
    required this.cardColor,
    required this.badgeEmoji,
  });

  /// Shows the achievement dialog
  static void show(
    BuildContext context,
    Achievement achievement, {
    Color? cardColor,
    String? badgeEmoji,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AchievementDialog(
        achievement: achievement,
        cardColor: cardColor ?? AppConstants.firstCupAchievementColor,
        badgeEmoji: badgeEmoji ?? '💧',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor,
              cardColor.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: AppConstants.achievementBorderAlpha),
            width: AppConstants.achievementDialogBorderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withValues(alpha: AppConstants.achievementShadowAlpha1),
              blurRadius: AppConstants.achievementDialogShadowBlur,
              spreadRadius: AppConstants.achievementDialogShadowSpread,
              offset: Offset.zero,
            ),
            BoxShadow(
              color: cardColor.withValues(alpha: AppConstants.achievementShadowAlpha2),
              blurRadius: AppConstants.achievementDialogSecondaryShadowBlur,
              offset: AppConstants.achievementDialogSecondaryShadowOffset,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.achievementDialogPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rozet emoji (büyük)
              Text(
                badgeEmoji,
                style: const TextStyle(fontSize: AppConstants.achievementBadgeEmojiSize),
              ),
              const SizedBox(height: AppConstants.extraLargeSpacing),

              // Başlık
              Text(
                'Yeni Bir Başarı Kazandın!',
                style: AppTextStyles.heading1.copyWith(
                  fontSize: AppConstants.achievementTitleFontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.defaultSpacing),

              // Başarı adı
              Text(
                achievement.name,
                style: AppTextStyles.heading3.copyWith(
                  fontSize: AppConstants.achievementNameFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.mediumSpacing),

              // Ödül bilgisi
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.extraLargeSpacing,
                  vertical: AppConstants.defaultSpacing,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: AppConstants.achievementRewardBackgroundAlpha,
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: AppConstants.achievementRewardIconSize,
                    ),
                    const SizedBox(width: AppConstants.mediumSpacing),
                    Text(
                      '${achievement.coinReward} Coin Kazandınız!',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontSize: AppConstants.achievementRewardFontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.largePadding),

              // Tamam butonu
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: cardColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.achievementButtonHorizontalPadding,
                    vertical: AppConstants.achievementButtonVerticalPadding,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.mediumBorderRadius),
                  ),
                  elevation: AppConstants.achievementButtonElevation,
                ),
                child: Text(
                  'Harika!',
                  style: AppTextStyles.buttonText.copyWith(
                    fontSize: AppConstants.achievementButtonFontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

