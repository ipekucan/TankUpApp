import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/drink_model.dart';

class DrinkProvider extends ChangeNotifier {
  static const String _customDrinksKey = 'custom_drinks';
  static const String _favoriteDrinksKey = 'favorite_drinks';
  static const String _quickAccessDrinksKey = 'quick_access_drinks';
  
  List<Drink> _customDrinks = [];
  List<String> _favoriteDrinkIds = []; // Favori içecek ID'leri
  Map<String, double> _favoriteDrinkAmounts = {}; // Favori içecek miktarları (ID -> miktar)
  List<String> _quickAccessDrinkIds = []; // Hızlı erişim içecek ID'leri
  Map<String, double> _quickAccessDrinkAmounts = {}; // Hızlı erişim içecek miktarları
  final List<Drink> _defaultDrinks = DrinkData.getDrinks();

  List<Drink> get allDrinks => [..._defaultDrinks, ..._customDrinks];
  List<Drink> get customDrinks => List.unmodifiable(_customDrinks);
  List<Drink> get favoriteDrinks {
    return _favoriteDrinkIds
        .map((id) => allDrinks.firstWhere(
              (d) => d.id == id,
              orElse: () => _defaultDrinks.first,
            ))
        .where((drink) => allDrinks.any((d) => d.id == drink.id))
        .toList();
  }

  List<Drink> get quickAccessDrinks {
    return _quickAccessDrinkIds
        .map((id) => allDrinks.firstWhere(
              (d) => d.id == id,
              orElse: () => _defaultDrinks.first,
            ))
        .where((drink) => allDrinks.any((d) => d.id == drink.id))
        .toList();
  }

  // Favori içecek miktarını getir (varsayılan: 200ml)
  double getFavoriteAmount(String drinkId) {
    return _favoriteDrinkAmounts[drinkId] ?? 200.0;
  }

  // Hızlı erişim içecek miktarını getir (varsayılan: 200ml)
  double getQuickAccessAmount(String drinkId) {
    return _quickAccessDrinkAmounts[drinkId] ?? 200.0;
  }

  bool isQuickAccess(String drinkId) {
    return _quickAccessDrinkIds.contains(drinkId);
  }

  DrinkProvider() {
    _loadCustomDrinks();
    _loadFavoriteDrinks();
    _loadQuickAccessDrinks();
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
      _customDrinks = [];
    }
  }

  Future<void> _loadFavoriteDrinks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteIdsJson = prefs.getString(_favoriteDrinksKey);
      final favoriteAmountsJson = prefs.getString('${_favoriteDrinksKey}_amounts');
      
      if (favoriteIdsJson != null) {
        final List<dynamic> decoded = jsonDecode(favoriteIdsJson);
        _favoriteDrinkIds = decoded.map((e) => e as String).toList();
      }
      
      if (favoriteAmountsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(favoriteAmountsJson);
        _favoriteDrinkAmounts = decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
      }
      
      notifyListeners();
    } catch (e) {
      _favoriteDrinkIds = [];
      _favoriteDrinkAmounts = {};
    }
  }

  Future<void> _saveFavoriteDrinks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteIdsJson = jsonEncode(_favoriteDrinkIds);
      final favoriteAmountsJson = jsonEncode(_favoriteDrinkAmounts);
      await prefs.setString(_favoriteDrinksKey, favoriteIdsJson);
      await prefs.setString('${_favoriteDrinksKey}_amounts', favoriteAmountsJson);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  bool isFavorite(String drinkId) {
    return _favoriteDrinkIds.contains(drinkId);
  }

  Future<void> toggleFavorite(String drinkId, {double? amount}) async {
    if (_favoriteDrinkIds.contains(drinkId)) {
      _favoriteDrinkIds.remove(drinkId);
      _favoriteDrinkAmounts.remove(drinkId);
    } else {
      _favoriteDrinkIds.add(drinkId);
      _favoriteDrinkAmounts[drinkId] = amount ?? 200.0; // Varsayılan: 200ml
    }
    await _saveFavoriteDrinks();
    notifyListeners();
  }

  Future<void> addFavorite(String drinkId, {double? amount}) async {
    if (!_favoriteDrinkIds.contains(drinkId)) {
      _favoriteDrinkIds.add(drinkId);
      _favoriteDrinkAmounts[drinkId] = amount ?? 200.0; // Varsayılan: 200ml
      await _saveFavoriteDrinks();
      notifyListeners();
    }
  }

  Future<void> removeFavorite(String drinkId) async {
    if (_favoriteDrinkIds.contains(drinkId)) {
      _favoriteDrinkIds.remove(drinkId);
      _favoriteDrinkAmounts.remove(drinkId);
      await _saveFavoriteDrinks();
      notifyListeners();
    }
  }

  Future<void> updateFavoriteAmount(String drinkId, double amount) async {
    if (_favoriteDrinkIds.contains(drinkId)) {
      _favoriteDrinkAmounts[drinkId] = amount;
      await _saveFavoriteDrinks();
      notifyListeners();
    }
  }

  // Quick Access Fonksiyonları
  Future<void> _loadQuickAccessDrinks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final quickAccessIdsJson = prefs.getString(_quickAccessDrinksKey);
      final quickAccessAmountsJson = prefs.getString('${_quickAccessDrinksKey}_amounts');
      
      if (quickAccessIdsJson != null) {
        final List<dynamic> decoded = jsonDecode(quickAccessIdsJson);
        _quickAccessDrinkIds = decoded.map((e) => e as String).toList();
      }
      
      if (quickAccessAmountsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(quickAccessAmountsJson);
        _quickAccessDrinkAmounts = decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
      }
      
      notifyListeners();
    } catch (e) {
      _quickAccessDrinkIds = [];
      _quickAccessDrinkAmounts = {};
    }
  }

  Future<void> _saveQuickAccessDrinks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final quickAccessIdsJson = jsonEncode(_quickAccessDrinkIds);
      final quickAccessAmountsJson = jsonEncode(_quickAccessDrinkAmounts);
      await prefs.setString(_quickAccessDrinksKey, quickAccessIdsJson);
      await prefs.setString('${_quickAccessDrinksKey}_amounts', quickAccessAmountsJson);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  Future<void> toggleQuickAccess(String drinkId, {double? amount}) async {
    if (_quickAccessDrinkIds.contains(drinkId)) {
      _quickAccessDrinkIds.remove(drinkId);
      _quickAccessDrinkAmounts.remove(drinkId);
    } else {
      _quickAccessDrinkIds.add(drinkId);
      _quickAccessDrinkAmounts[drinkId] = amount ?? 200.0; // Varsayılan: 200ml
    }
    await _saveQuickAccessDrinks();
    notifyListeners();
  }

  Future<void> addQuickAccess(String drinkId, {double? amount}) async {
    if (!_quickAccessDrinkIds.contains(drinkId)) {
      _quickAccessDrinkIds.add(drinkId);
      _quickAccessDrinkAmounts[drinkId] = amount ?? 200.0; // Varsayılan: 200ml
      await _saveQuickAccessDrinks();
      notifyListeners();
    }
  }

  Future<void> removeQuickAccess(String drinkId) async {
    if (_quickAccessDrinkIds.contains(drinkId)) {
      _quickAccessDrinkIds.remove(drinkId);
      _quickAccessDrinkAmounts.remove(drinkId);
      await _saveQuickAccessDrinks();
      notifyListeners();
    }
  }

  /// Removes a drink from the home screen (quick access list).
  /// This is an alias for removeQuickAccess for better semantic clarity.
  Future<void> removeDrinkFromHome(String drinkId) async {
    await removeQuickAccess(drinkId);
  }

  Future<void> updateQuickAccessAmount(String drinkId, double amount) async {
    if (_quickAccessDrinkIds.contains(drinkId)) {
      _quickAccessDrinkAmounts[drinkId] = amount;
      await _saveQuickAccessDrinks();
      notifyListeners();
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
      // Hata durumunda sessizce devam et
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

