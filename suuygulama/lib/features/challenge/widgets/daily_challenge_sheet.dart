import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../models/challenge_level_model.dart';

class DailyChallengeSheet extends StatelessWidget {
  final ChallengeLevelModel level;

  const DailyChallengeSheet({
    super.key,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final hasChallengeContent = level.challengeTitle != null && level.challengeDescription != null;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppConstants.largeBorderRadius),
          topRight: Radius.circular(AppConstants.largeBorderRadius),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gün ${level.dayNumber}',
                  style: AppTextStyles.heading2,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Challenge Icon/Emoji (Large)
                  if (hasChallengeContent)
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.water_drop,
                          color: AppColors.primaryBlue,
                          size: 48,
                        ),
                      ),
                    ),
                  
                  if (hasChallengeContent)
                    const SizedBox(height: AppConstants.largePadding),
                  
                  // Challenge Title (Bold, Large)
                  if (hasChallengeContent && level.challengeTitle != null)
                    Text(
                      level.challengeTitle!,
                      style: AppTextStyles.heading1.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  
                  if (hasChallengeContent)
                    const SizedBox(height: AppConstants.defaultPadding),
                  
                  // Challenge Description (Readable body text)
                  if (hasChallengeContent && level.challengeDescription != null)
                    Text(
                      level.challengeDescription!,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  
                  if (hasChallengeContent)
                    const SizedBox(height: AppConstants.extraLargePadding),
                  
                  // Progress Section
                  if (hasChallengeContent) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'İlerleme',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '2/5 Tamamlandı',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.smallSpacing),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppConstants.circularBorderRadius),
                      child: LinearProgressIndicator(
                        value: 0.4, // 2/5 = 0.4
                        minHeight: 8,
                        backgroundColor: AppColors.cardBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.softPinkButton,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.largePadding),
                  ],
                  
                  // Task List (Secondary)
                  Text(
                    'Görevler',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  _buildTaskItem(
                    icon: Icons.water_drop,
                    title: '2 Litre Su İç',
                    isCompleted: true,
                  ),
                  const SizedBox(height: AppConstants.mediumPadding),
                  _buildTaskItem(
                    icon: Icons.fitness_center,
                    title: 'Günlük Hedefini Tamamla',
                    isCompleted: true,
                  ),
                  const SizedBox(height: AppConstants.mediumPadding),
                  _buildTaskItem(
                    icon: Icons.local_fire_department,
                    title: 'Seri Devam Ettir',
                    isCompleted: false,
                  ),
                  const SizedBox(height: AppConstants.mediumPadding),
                  _buildTaskItem(
                    icon: Icons.check_circle_outline,
                    title: '3 Farklı İçecek Türü Kullan',
                    isCompleted: false,
                  ),
                  const SizedBox(height: AppConstants.mediumPadding),
                  _buildTaskItem(
                    icon: Icons.emoji_events,
                    title: 'Günlük Mücadeleyi Tamamla',
                    isCompleted: false,
                  ),
                  const SizedBox(height: AppConstants.largePadding),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem({
    required IconData icon,
    required String title,
    required bool isCompleted,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.successGreen.withValues(alpha: 0.1)
            : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppConstants.circularBorderRadius),
        border: Border.all(
          color: isCompleted
              ? AppColors.successGreen.withValues(alpha: 0.3)
              : AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.successGreen
                  : AppColors.cardBorder,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isCompleted ? Colors.white : AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppConstants.defaultPadding),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
