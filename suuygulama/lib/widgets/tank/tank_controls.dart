import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../providers/drink_provider.dart';
import '../../providers/water_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../utils/drink_helpers.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_card.dart';
import '../../models/drink_model.dart';

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
          
          // Calculate the height needed for the controls (based on the largest button)
          final controlHeight = AppConstants.mainControlButtonRadius * 2;
          
          final screenWidth = MediaQuery.of(context).size.width;
          final menuButtonWidth = AppConstants.menuButtonWidth;
          final waterButtonRadius = AppConstants.mainControlButtonRadius;
          
          // Calculate initial padding to center the Water Button (index 0)
          // Formula: (ScreenWidth / 2) - MenuWidth - WaterButtonRadius
          final initialPadding = (screenWidth / 2) - menuButtonWidth - waterButtonRadius;
          
          return SizedBox(
            height: controlHeight,
            child: Padding(
              padding: EdgeInsets.only(
                right: AppConstants.defaultPadding,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left: Fixed Menu Button
                  _buildDShapedMenuButton(context),
                  
                  // Right: Unified Scrollable List (Water Button + Drinks)
                  Expanded(
                    child: _buildUnifiedScrollableList(
                      context,
                      quickAccessDrinks,
                      drinkProvider,
                      waterProvider,
                      userProvider,
                      achievementProvider,
                      initialPadding,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the unified scrollable list with Water Button as first item and double-sided fade effect.
  /// The Water Button (index 0) is initially centered, and drinks follow as subsequent items.
  Widget _buildUnifiedScrollableList(
    BuildContext context,
    List<Drink> quickAccessDrinks,
    DrinkProvider drinkProvider,
    WaterProvider waterProvider,
    UserProvider userProvider,
    AchievementProvider achievementProvider,
    double initialPadding,
  ) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: const [0.0, 0.1, 0.9, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(left: initialPadding),
        itemCount: 1 + quickAccessDrinks.length, // Water Button + Drinks
        itemBuilder: (context, index) {
          // Index 0: Water Button
          if (index == 0) {
            return Padding(
              padding: EdgeInsets.only(
                right: AppConstants.buttonSpacing,
              ),
              child: GestureDetector(
                onTap: () {
                  if (!context.mounted) return;
                  onShowInteractiveCupModal(
                    context,
                    waterProvider,
                    userProvider,
                    achievementProvider,
                  );
                },
                behavior: HitTestBehavior.opaque,
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
            );
          }
          
          // Index 1+: Quick Access Drinks
          final drinkIndex = index - 1;
          final drink = quickAccessDrinks[drinkIndex];
          final amount = drinkProvider.getQuickAccessAmount(drink.id);
          final drinkColor = DrinkHelpers.getColor(drink.id);
          
          return Padding(
            padding: EdgeInsets.only(
              right: drinkIndex < quickAccessDrinks.length - 1 
                  ? AppConstants.mediumSpacing 
                  : 0,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Ana içecek butonu
                GestureDetector(
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
                  behavior: HitTestBehavior.opaque,
                  child: CircleAvatar(
                    radius: AppConstants.mainControlButtonRadius,
                    backgroundColor: drinkColor.withValues(alpha: 0.2),
                    child: Text(
                      DrinkHelpers.getEmoji(drink.id),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                // Sade eksi rozeti (sağ üst köşe)
                Positioned(
                  top: -2,
                  right: -2,
                  child: GestureDetector(
                    onTap: () => _showRemoveConfirmationDialog(
                      context,
                      drink,
                      drinkProvider,
                    ),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: AppConstants.addButtonBadgeSize,
                      height: AppConstants.addButtonBadgeSize,
                      decoration: BoxDecoration(
                        color: AppColors.subtleBadgeBackground,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.0,
                        ),
                      ),
                      child: const Icon(
                        Icons.remove,
                        color: Colors.white,
                        size: AppConstants.addButtonBadgeIconSize,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds the D-shaped menu button (half-capsule shape with flat left side).
  /// Height matches the Water Button for visual consistency.
  Widget _buildDShapedMenuButton(BuildContext context) {
    // Match the Water Button height for visual consistency
    final buttonHeight = AppConstants.mainControlButtonRadius * 2;
    final borderRadius = AppConstants.mainControlButtonRadius;
    
    return GestureDetector(
      onTap: () {
        if (!context.mounted) return;
        // Debug: Menü butonunun çalıştığını doğrula
        debugPrint('Menu button tapped - opening drink selector');
        onShowDrinkSelector();
      },
      behavior: HitTestBehavior.opaque, // Tüm alanı dokunmatik yap
      child: Container(
        width: AppConstants.menuButtonWidth,
        height: buttonHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(borderRadius),
            bottomRight: Radius.circular(borderRadius),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.grid_view_rounded,
          color: AppColors.softPinkButton,
          size: AppConstants.controlButtonIconSize,
        ),
      ),
    );
  }

  /// Shows a confirmation dialog before removing a drink from the home screen.
  void _showRemoveConfirmationDialog(
    BuildContext context,
    Drink drink,
    DrinkProvider drinkProvider,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => Center(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.defaultPadding),
          child: AppCard(
            padding: EdgeInsets.all(AppConstants.largePadding),
            borderRadius: AppConstants.defaultBorderRadius,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başlık
                Text(
                  'Kaldır?',
                  style: AppTextStyles.heading3,
                ),
                SizedBox(height: AppConstants.mediumSpacing),
                // Mesaj
                Text(
                  'Bu içeceği ana ekrandan kaldırmak istediğine emin misin?',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppConstants.largeSpacing),
                // Butonlar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Vazgeç butonu
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppConstants.defaultPadding,
                          vertical: AppConstants.mediumSpacing,
                        ),
                      ),
                      child: Text(
                        'Vazgeç',
                        style: AppTextStyles.buttonText.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    // Kaldır butonu
                    ElevatedButton(
                      onPressed: () async {
                        await drinkProvider.removeDrinkFromHome(drink.id);
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop();
                        
                        // Başarı mesajı göster
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(DrinkHelpers.getEmoji(drink.id)),
                                const SizedBox(width: AppConstants.smallSpacing),
                                Text(
                                  '${DrinkHelpers.getName(drink.id)} ana ekrandan kaldırıldı',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            backgroundColor: AppColors.errorRed,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorRed,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppConstants.defaultPadding,
                          vertical: AppConstants.mediumSpacing,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.smallBorderRadius,
                          ),
                        ),
                      ),
                      child: Text(
                        'Kaldır',
                        style: AppTextStyles.buttonText.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

