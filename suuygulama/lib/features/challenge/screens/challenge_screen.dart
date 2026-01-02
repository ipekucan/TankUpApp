import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/daily_hydration_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../screens/shop_screen.dart';
import '../models/challenge_level_model.dart';
import '../widgets/challenge_path_widget.dart';
import '../widgets/daily_challenge_sheet.dart';

/// Challenge Screen - Gamification main page
/// Features:
/// - AppBar with coin balance indicator
/// - Floating Action Button for Market (ShopScreen)
/// - Challenge map with zig-zag path
class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  /// Generate mock data for 30 days
  /// First 5 days: completed
  /// Day 6: active (unlocked but not completed)
  /// Rest: locked
  List<ChallengeLevelModel> _generateMockLevels() {
    final List<ChallengeLevelModel> levels = [];
    
    for (int i = 1; i <= 30; i++) {
      if (i <= 5) {
        // First 5 days: completed
        levels.add(ChallengeLevelModel(
          id: i,
          dayNumber: i,
          isCompleted: true,
          isLocked: false,
          isActive: false,
        ));
      } else if (i == 6) {
        // Day 6: active - Kahve Detoksu
        levels.add(ChallengeLevelModel(
          id: i,
          dayNumber: i,
          isCompleted: false,
          isLocked: false,
          isActive: true,
          challengeTitle: 'Kahve Detoksu',
          challengeDescription: 'Bugün kahve veya çay içmek yok! Sadece su ile vücudunu arındır.',
        ));
      } else {
        // Rest: locked
        levels.add(ChallengeLevelModel(
          id: i,
          dayNumber: i,
          isCompleted: false,
          isLocked: true,
          isActive: false,
        ));
      }
    }
    
    return levels;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Mücadele',
          style: AppTextStyles.appBarTitle.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<DailyHydrationProvider>(
            builder: (context, dailyHydrationProvider, _) {
              return Padding(
                padding: EdgeInsets.only(right: AppConstants.defaultPadding),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: AppColors.goldCoin,
                          size: 32,
                        ),
                        SizedBox(width: AppConstants.mediumPadding),
                        Text(
                          '${dailyHydrationProvider.tankCoins}',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF6ABBD9), // Soft, muted azure blue
              const Color(0xFF005C97), // Medium-deep, calm ocean blue
            ],
          ),
        ),
        child: Builder(
          builder: (context) {
            final levels = _generateMockLevels();
            if (levels.isEmpty) {
              return Center(
                child: Text(
                  'Harita ve Görevler Buraya Gelecek',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              );
            }
            return SafeArea(
              child: ChallengePathWidget(
                levels: levels,
                onLevelTap: (level) {
                  _showDailyChallengeSheet(context, level);
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'challenge_market_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ShopScreen(),
            ),
          );
        },
        backgroundColor: AppColors.softPinkButton,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.shopping_bag,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  void _showDailyChallengeSheet(BuildContext context, ChallengeLevelModel level) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DailyChallengeSheet(level: level),
    );
  }
}
