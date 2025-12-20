import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/drink_model.dart';

class DrinkProvider extends ChangeNotifier {
  static const String _customDrinksKey = 'custom_drinks';
  
  List<Drink> _customDrinks = [];
  final List<Drink> _defaultDrinks = DrinkData.getDrinks();

  List<Drink> get allDrinks => [..._defaultDrinks, ..._customDrinks];
  List<Drink> get customDrinks => List.unmodifiable(_customDrinks);

  DrinkProvider() {
    _loadCustomDrinks();
  }

  Future<void> _loadCustomDrinks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customDrinksJson = prefs.getString(_customDrinksKey);
      
      if (customDrinksJson != null) {
        final List<dynamic> decoded = jsonDecode(customDrinksJson);
        _customDrinks = decoded
            .map((json) => Drink.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('İçecek verileri yüklenirken hata: $e');
      }
      _customDrinks = [];
    }
  }

  Future<void> _saveCustomDrinks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customDrinksJson = jsonEncode(
        _customDrinks.map((d) => d.toJson()).toList(),
      );
      await prefs.setString(_customDrinksKey, customDrinksJson);
    } catch (e) {
      if (kDebugMode) {
        print('İçecek verileri kaydedilirken hata: $e');
      }
    }
  }

  Future<void> addCustomDrink(Drink drink) async {
    // ID kontrolü - eğer varsayılan içeceklerde varsa ekleme
    if (_defaultDrinks.any((d) => d.id == drink.id)) {
      return;
    }
    
    _customDrinks.add(drink);
    await _saveCustomDrinks();
    notifyListeners();
  }

  Future<void> updateCustomDrink(String id, Drink updatedDrink) async {
    final index = _customDrinks.indexWhere((d) => d.id == id);
    if (index != -1) {
      _customDrinks[index] = updatedDrink;
      await _saveCustomDrinks();
      notifyListeners();
    }
  }

  Future<void> deleteCustomDrink(String id) async {
    _customDrinks.removeWhere((d) => d.id == id);
    await _saveCustomDrinks();
    notifyListeners();
  }

  Drink? getDrinkById(String id) {
    try {
      return allDrinks.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }
}

