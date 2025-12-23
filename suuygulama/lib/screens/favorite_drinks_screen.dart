import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../providers/drink_provider.dart';
import 'drink_gallery_screen.dart';

class FavoriteDrinksScreen extends StatefulWidget {
  const FavoriteDrinksScreen({super.key});

  @override
  State<FavoriteDrinksScreen> createState() => _FavoriteDrinksScreenState();
}

class _FavoriteDrinksScreenState extends State<FavoriteDrinksScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.verySoftBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A5568)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Favori İçecekler',
          style: TextStyle(
            color: Color(0xFF4A5568),
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Consumer<DrinkProvider>(
        builder: (context, drinkProvider, child) {
          final favoriteDrinks = drinkProvider.favoriteDrinks;
          
          return Column(
            children: [
              // İçecek Menüsü Butonu
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DrinkGalleryScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('İçecek Menüsü'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.softPinkButton,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
              
              // Favori İçecekler Listesi
              Expanded(
                child: favoriteDrinks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz favori içecek eklenmedi',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'İçecek menüsünden favori ekleyebilirsiniz',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: favoriteDrinks.length,
                        itemBuilder: (context, index) {
                          final drink = favoriteDrinks[index];
                          final amount = drinkProvider.getFavoriteAmount(drink.id);
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _getDrinkColor(drink.id).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getDrinkIcon(drink.id),
                                  color: _getDrinkColor(drink.id),
                                  size: 28,
                                ),
                              ),
                              title: Text(
                                drink.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4A5568),
                                ),
                              ),
                              subtitle: Text(
                                'Varsayılan miktar: ${amount.toStringAsFixed(0)}ml',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.favorite,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  await drinkProvider.removeFavorite(drink.id);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${drink.name} favorilerden çıkarıldı'),
                                      backgroundColor: AppColors.softPinkButton,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getDrinkColor(String drinkId) {
    switch (drinkId) {
      case 'water':
        return Colors.blue;
      case 'mineral_water':
        return const Color(0xFF4A9ED8);
      case 'coffee':
        return Colors.brown;
      case 'tea':
        return Colors.green;
      case 'herbal_tea':
        return const Color(0xFF6B8E23);
      case 'green_tea':
        return const Color(0xFF228B22);
      case 'cold_tea':
        return const Color(0xFF8B7355);
      case 'lemonade':
        return const Color(0xFFFFD700);
      case 'iced_coffee':
        return const Color(0xFF8B4513);
      case 'ayran':
        return const Color(0xFFF5F5DC);
      case 'kefir':
        return const Color(0xFFFFE4B5);
      case 'milk':
        return Colors.white70;
      case 'juice':
        return Colors.orange;
      case 'smoothie':
        return const Color(0xFFFF6347);
      case 'fresh_juice':
        return const Color(0xFFFF8C00);
      case 'sports':
        return Colors.cyan;
      case 'protein_shake':
        return const Color(0xFF9370DB);
      case 'coconut_water':
        return const Color(0xFFDEB887);
      case 'soda':
        return Colors.red;
      case 'energy_drink':
        return const Color(0xFFFF1493);
      case 'detox_water':
        return const Color(0xFF98D8C8);
      default:
        return AppColors.softPinkButton;
    }
  }

  IconData _getDrinkIcon(String drinkId) {
    switch (drinkId) {
      case 'water':
        return Icons.water_drop;
      case 'mineral_water':
        return Icons.water;
      case 'coffee':
        return Icons.local_cafe;
      case 'tea':
        return Icons.emoji_food_beverage;
      case 'herbal_tea':
      case 'green_tea':
        return Icons.eco;
      case 'cold_tea':
        return Icons.emoji_food_beverage;
      case 'lemonade':
        return Icons.local_drink;
      case 'iced_coffee':
        return Icons.local_cafe;
      case 'ayran':
      case 'kefir':
        return Icons.liquor;
      case 'milk':
        return Icons.local_drink;
      case 'juice':
      case 'fresh_juice':
        return Icons.local_drink;
      case 'smoothie':
        return Icons.blender;
      case 'sports':
        return Icons.fitness_center;
      case 'protein_shake':
        return Icons.sports_gymnastics;
      case 'coconut_water':
        return Icons.water_drop;
      case 'soda':
        return Icons.sports_bar;
      case 'energy_drink':
        return Icons.bolt;
      case 'detox_water':
        return Icons.spa;
      default:
        return Icons.local_drink;
    }
  }
}

