import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../providers/drink_provider.dart';
import '../../providers/water_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../screens/drink_gallery_screen.dart';
import '../../core/constants/app_constants.dart';

/// Widget that displays the control buttons (menu, water, add drink) at the bottom of the tank screen.
class TankControls extends StatelessWidget {
  final VoidCallback onShowDrinkSelector;
  final Function(BuildContext, WaterProvider, UserProvider, AchievementProvider)
      onShowInteractiveCupModal;

  const TankControls({
    super.key,
    required this.onShowDrinkSelector,
    required this.onShowInteractiveCupModal,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).size.height * AppConstants.controlPanelBottomPosition,
      left: 0,
      right: 0,
      child: Consumer4<DrinkProvider, WaterProvider, UserProvider, AchievementProvider>(
        builder: (context, drinkProvider, waterProvider, userProvider, achievementProvider, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // En Sol: Menü Butonu (Kare/Izgara ikonu)
              GestureDetector(
                onTap: () {
                  if (!context.mounted) return;
                  onShowDrinkSelector();
                },
                child: CircleAvatar(
                  radius: AppConstants.controlButtonRadius,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.grid_view,
                    color: AppColors.softPinkButton,
                    size: AppConstants.controlButtonIconSize,
                  ),
                ),
              ),

              SizedBox(width: AppConstants.buttonSpacing),

              // Merkez: Su İçme Butonu (Bardak ikonu, Mavi, En Büyük)
              GestureDetector(
                onTap: () {
                  if (!context.mounted) return;
                  onShowInteractiveCupModal(
                    context,
                    waterProvider,
                    userProvider,
                    achievementProvider,
                  );
                },
                child: CircleAvatar(
                  radius: AppConstants.mainControlButtonRadius,
                  backgroundColor: AppColors.waterColor,
                  child: const Icon(
                    Icons.local_drink,
                    color: Colors.white,
                    size: AppConstants.mainControlButtonIconSize,
                  ),
                ),
              ),

              SizedBox(width: AppConstants.buttonSpacing),

              // Sağ: İçecek Ekleme Butonu (Artılı Bardak ikonu)
              GestureDetector(
                onTap: () {
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DrinkGalleryScreen(),
                    ),
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: AppConstants.controlButtonRadius,
                      backgroundColor: AppColors.softPinkButton,
                      child: const Icon(
                        Icons.local_drink,
                        color: Colors.white,
                        size: AppConstants.smallControlButtonIconSize,
                      ),
                    ),
                    // Sağ üst köşede küçük + işareti
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: AppConstants.addButtonBadgeSize,
                        height: AppConstants.addButtonBadgeSize,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: AppColors.softPinkButton,
                          size: AppConstants.addButtonBadgeIconSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

