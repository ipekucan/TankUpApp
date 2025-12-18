import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  static const String _userDataKey = 'user_data';
  static const String _lastResetDateKey = 'last_reset_date';
  static const String _consecutiveDaysKey = 'consecutive_days';
  
  UserModel _userData = UserModel.initial();
  DateTime? _lastResetDate;
  int _consecutiveDays = 0;

  UserModel get userData => _userData;
  int get consecutiveDays => _consecutiveDays;

  UserProvider() {
    _loadUserData();
  }

  // Kullanıcı verilerini yükle
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Kullanıcı verilerini yükle
      final userDataJson = prefs.getString(_userDataKey);
      if (userDataJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(userDataJson);
        _userData = UserModel.fromJson(decoded);
      }
      
      // Son sıfırlama tarihini yükle
      final lastResetDateString = prefs.getString(_lastResetDateKey);
      if (lastResetDateString != null) {
        _lastResetDate = DateTime.parse(lastResetDateString);
      }
      
      // Ardışık gün sayısını yükle
      _consecutiveDays = prefs.getInt(_consecutiveDaysKey) ?? 0;
      
      // Gün kontrolü yap
      _checkAndResetDay();
      
      notifyListeners();
    } catch (e) {
      // Hata durumunda varsayılan değerlerle devam et
      _userData = UserModel.initial();
      notifyListeners();
    }
  }

  // Gün kontrolü ve sıfırlama
  Future<void> _checkAndResetDay() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (_lastResetDate == null) {
      _lastResetDate = today;
      await _saveUserData();
      return;
    }
    
    final lastReset = DateTime(
      _lastResetDate!.year,
      _lastResetDate!.month,
      _lastResetDate!.day,
    );
    
    // Yeni gün başladıysa
    if (today.isAfter(lastReset)) {
      _lastResetDate = today;
      await _saveUserData();
    }
  }

  // Kullanıcı verilerini kaydet
  Future<void> _saveUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Kullanıcı verilerini kaydet
      final userDataJson = jsonEncode(_userData.toJson());
      await prefs.setString(_userDataKey, userDataJson);
      
      // Son sıfırlama tarihini kaydet
      if (_lastResetDate != null) {
        await prefs.setString(_lastResetDateKey, _lastResetDate!.toIso8601String());
      }
      
      // Ardışık gün sayısını kaydet
      await prefs.setInt(_consecutiveDaysKey, _consecutiveDays);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  // Kullanıcı adını güncelle
  Future<void> setName(String name) async {
    _userData = _userData.copyWith(name: name);
    await _saveUserData();
    notifyListeners();
  }
  
  // Kullanıcı adını güncelle (updateName alias)
  Future<void> updateName(String name) async {
    await setName(name);
  }
  
  // İsim var mı kontrolü
  bool get hasName => _userData.name.isNotEmpty;

  // Toplam su miktarını güncelle
  Future<void> addToTotalWater(double amount) async {
    _userData = _userData.copyWith(
      totalWaterConsumed: _userData.totalWaterConsumed + amount,
    );
    await _saveUserData();
    notifyListeners();
  }

  // Başarı ekle
  Future<void> addAchievement(String achievementId) async {
    if (!_userData.achievements.contains(achievementId)) {
      final newAchievements = List<String>.from(_userData.achievements)
        ..add(achievementId);
      _userData = _userData.copyWith(achievements: newAchievements);
      await _saveUserData();
      notifyListeners();
    }
  }

  // Ardışık gün sayısını güncelle
  Future<void> updateConsecutiveDays(bool goalReached) async {
    if (goalReached) {
      _consecutiveDays++;
    } else {
      _consecutiveDays = 0;
    }
    await _saveUserData();
    notifyListeners();
  }

  // Bugün yeni gün mü kontrolü
  bool get isNewDay {
    if (_lastResetDate == null) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastReset = DateTime(
      _lastResetDate!.year,
      _lastResetDate!.month,
      _lastResetDate!.day,
    );
    return today.isAfter(lastReset);
  }
}

