import 'package:flutter/material.dart';
import '../models/drink_model.dart';
import 'app_colors.dart';

/// Utility class for drink-related helper functions.
/// Centralizes drink emoji, color, icon, and name mappings to eliminate code duplication.
class DrinkHelpers {
  /// Returns the emoji representation for a given drink ID.
  /// 
  /// Example: 'water' -> '💧', 'coffee' -> '☕'
  static String getEmoji(String drinkId) {
    switch (drinkId) {
      case 'water':
      case 'mineral_water':
        return '💧';
      case 'coffee':
        return '☕';
      case 'tea':
      case 'herbal_tea':
      case 'green_tea':
        return '🍵';
      case 'soda':
        return '🥤';
      case 'juice':
      case 'fresh_juice':
        return '🧃';
      case 'milk':
        return '🥛';
      case 'smoothie':
        return '🥤';
      default:
        return '🥤';
    }
  }

  /// Returns the color representation for a given drink ID.
  /// 
  /// Example: 'water' -> Colors.blue, 'coffee' -> Colors.brown
  static Color getColor(String drinkId) {
    switch (drinkId) {
      // Temel İçecekler
      case 'water':
        return Colors.blue;
      case 'mineral_water':
        return const Color(0xFF4A9ED8);
      
      // Sıcak İçecekler
      case 'coffee':
        return Colors.brown;
      case 'tea':
        return Colors.green;
      case 'herbal_tea':
        return const Color(0xFF6B8E23);
      case 'green_tea':
        return const Color(0xFF228B22);
      
      // Soğuk İçecekler
      case 'cold_tea':
        return const Color(0xFF8B7355);
      case 'lemonade':
        return const Color(0xFFFFD700);
      case 'iced_coffee':
        return const Color(0xFF8B4513);
      
      // Süt Ürünleri
      case 'ayran':
        return const Color(0xFFF5F5DC);
      case 'kefir':
        return const Color(0xFFFFE4B5);
      case 'milk':
        return Colors.white70;
      
      // Meyve İçecekleri
      case 'juice':
        return Colors.orange;
      case 'smoothie':
        return const Color(0xFFFF6347);
      case 'fresh_juice':
        return const Color(0xFFFF8C00);
      
      // Spor ve Sağlık
      case 'sports':
        return Colors.cyan;
      case 'protein_shake':
        return const Color(0xFF9370DB);
      case 'coconut_water':
        return const Color(0xFFDEB887);
      
      // Diğer
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

  /// Returns the icon representation for a given drink ID.
  /// 
  /// Example: 'water' -> Icons.water_drop, 'coffee' -> Icons.local_cafe
  static IconData getIcon(String drinkId) {
    switch (drinkId) {
      // Temel İçecekler
      case 'water':
        return Icons.water_drop;
      case 'mineral_water':
        return Icons.water;
      
      // Sıcak İçecekler
      case 'coffee':
        return Icons.local_cafe;
      case 'tea':
        return Icons.emoji_food_beverage;
      case 'herbal_tea':
        return Icons.eco;
      case 'green_tea':
        return Icons.eco;
      
      // Soğuk İçecekler
      case 'cold_tea':
        return Icons.emoji_food_beverage;
      case 'lemonade':
        return Icons.local_drink;
      case 'iced_coffee':
        return Icons.local_cafe;
      
      // Süt Ürünleri
      case 'ayran':
        return Icons.liquor;
      case 'kefir':
        return Icons.liquor;
      case 'milk':
        return Icons.local_drink;
      
      // Meyve İçecekleri
      case 'juice':
        return Icons.local_drink;
      case 'smoothie':
        return Icons.blender;
      case 'fresh_juice':
        return Icons.local_drink;
      
      // Spor ve Sağlık
      case 'sports':
        return Icons.fitness_center;
      case 'protein_shake':
        return Icons.sports_gymnastics;
      case 'coconut_water':
        return Icons.water_drop;
      
      // Diğer
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

  /// Returns the display name for a given drink ID.
  /// 
  /// Looks up the drink in DrinkData.getDrinks() and returns its name.
  /// Returns 'Diğer' if the drink is not found.
  static String getName(String drinkId) {
    final allDrinks = DrinkData.getDrinks();
    return allDrinks.firstWhere(
      (drink) => drink.id == drinkId,
      orElse: () => Drink(
        id: 'other',
        name: 'Diğer',
        caloriePer100ml: 0,
        hydrationFactor: 0,
      ),
    ).name;
  }
}

