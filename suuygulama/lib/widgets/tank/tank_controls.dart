import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../providers/drink_provider.dart';
import '../../providers/water_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../screens/drink_gallery_screen.dart';
import '../../core/constants/app_constants.dart';
import '../../utils/drink_helpers.dart';

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
      bottom: MediaQuery.of(context).size.height * AppConstants.controlPanelBottomPosition + 30,
      left: 0,
      right: 0,
      child: Consumer4<DrinkProvider, WaterProvider, UserProvider, AchievementProvider>(
        builder: (context, drinkProvider, waterProvider, userProvider, achievementProvider, child) {
          final quickAccessDrinks = drinkProvider.quickAccessDrinks;
          
          // Ana butonların toplam genişliğini hesapla
          final screenWidth = MediaQuery.of(context).size.width;
          final mainButtonWidth = (AppConstants.controlButtonRadius * 2) + 
                                  AppConstants.buttonSpacing + 
                                  (AppConstants.mainControlButtonRadius * 2) + 
                                  AppConstants.buttonSpacing + 
                                  (AppConstants.controlButtonRadius * 2);
          final leftSpacing = (screenWidth - mainButtonWidth) / 2;
          
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Sol tarafta boşluk - Ana butonları merkeze almak için
                SizedBox(width: leftSpacing > 0 ? leftSpacing - 16 : 0),
                
                // Ana Butonlar (Merkezde)
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
                
                SizedBox(width: AppConstants.buttonSpacing),
                
                // Quick Access İçecekler (Ana butonların sağında)
                ...quickAccessDrinks.map((drink) {
                  final amount = drinkProvider.getQuickAccessAmount(drink.id);
                  final drinkColor = DrinkHelpers.getColor(drink.id);
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () async {
                        // Quick access içeceği direkt ekle
                        await waterProvider.drink(drink, amount);
                        
                        if (!context.mounted) return;
                        
                        // Başarı mesajı göster
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(DrinkHelpers.getEmoji(drink.id)),
                                const SizedBox(width: 8),
                                Text(
                                  '${DrinkHelpers.getName(drink.id)} eklendi!',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            backgroundColor: drinkColor,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: AppConstants.controlButtonRadius,
                        backgroundColor: drinkColor.withValues(alpha: 0.2),
                        child: Text(
                          DrinkHelpers.getEmoji(drink.id),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

