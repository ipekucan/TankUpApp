import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  static const String _userDataKey = 'user_data';
  static const String _lastResetDateKey = 'last_reset_date';
  static const String _consecutiveDaysKey = 'consecutive_days';
  static const String _isMetricKey = 'is_metric'; // Birim sistemi (true = Metric, false = Imperial)
  static const String _lastStreakIncrementDateKey = 'last_streak_increment_date'; // Son streak artış tarihi
  
  UserModel _userData = UserModel.initial();
  DateTime? _lastResetDate;
  int _consecutiveDays = 0;
  bool _isMetric = true; // Varsayılan olarak Metric (kg, L, ml)
  DateTime? _lastStreakIncrementDate; // Bugün streak artırıldı mı kontrolü için

  UserModel get userData => _userData;
  int get consecutiveDays => _consecutiveDays;
  bool get isMetric => _isMetric;

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
      
      // Son streak artış tarihini yükle
      final lastStreakIncrementDateString = prefs.getString(_lastStreakIncrementDateKey);
      if (lastStreakIncrementDateString != null) {
        try {
          _lastStreakIncrementDate = DateTime.parse(lastStreakIncrementDateString);
        } catch (e) {
          _lastStreakIncrementDate = null;
        }
      } else {
        _lastStreakIncrementDate = null;
      }
      
      // Birim sistemini yükle (varsayılan: Metric)
      _isMetric = prefs.getBool(_isMetricKey) ?? true;
      
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
      // Yeni gün başladığında streak artış tarihini sıfırla
      _lastStreakIncrementDate = null;
      await _saveUserData();
    }
  }

  // Kullanıcı verilerini kaydet
  Future<void> _saveUserData() async {
    try {
      // SharedPreferences işlemini optimize et
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
      
      // Son streak artış tarihini kaydet
      if (_lastStreakIncrementDate != null) {
        await prefs.setString(_lastStreakIncrementDateKey, _lastStreakIncrementDate!.toIso8601String());
      } else {
        await prefs.remove(_lastStreakIncrementDateKey);
      }
      
      // Birim sistemini kaydet
      await prefs.setBool(_isMetricKey, _isMetric);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  // Birim sistemini güncelle (true = Metric, false = Imperial)
  Future<void> setIsMetric(bool isMetric) async {
    _isMetric = isMetric;
    await _saveUserData();
    notifyListeners();
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
  
  // Boy ve kilo güncelle
  Future<void> updateHeightWeight(double? height, double? weight) async {
    _userData = _userData.copyWith(height: height, weight: weight);
    await _saveUserData();
    notifyListeners();
  }
  
  // Vücut Kitle Endeksi (VKE/BMI) hesapla
  double? get bmi {
    if (_userData.height == null || _userData.weight == null) return null;
    if (_userData.height! <= 0 || _userData.weight! <= 0) return null;
    
    // BMI = kilo / (boy/100)²
    final heightInMeters = _userData.height! / 100.0;
    return _userData.weight! / (heightInMeters * heightInMeters);
  }
  
  // Gelişmiş su hedefi hesapla (kilo, aktivite, yaş faktörleri)
  double calculateIdealWaterGoal() {
    if (_userData.weight == null) {
      return 5000.0; // Varsayılan 5L
    }
    
    // Temel formül: 35ml/kg
    double baseGoal = 35.0 * _userData.weight!;
    
    // Aktivite faktörü
    double activityBonus = 0.0;
    if (_userData.activityLevel == 'high') {
      activityBonus = 500.0; // Yüksek aktivite için +500ml
    } else if (_userData.activityLevel == 'medium') {
      activityBonus = 250.0; // Orta aktivite için +250ml
    }
    // Düşük aktivite için bonus yok
    
    // Yaş faktörü
    double ageAdjustment = 0.0;
    if (_userData.age != null) {
      if (_userData.age! < 18) {
        // Gençler için hafif artış
        ageAdjustment = baseGoal * 0.05; // %5 artış
      } else if (_userData.age! > 65) {
        // Yaşlılar için hafif azalış (doktor kontrolü önerilir)
        ageAdjustment = -baseGoal * 0.05; // %5 azalış
      }
    }
    
    // Toplam hedef
    final idealGoal = baseGoal + activityBonus + ageAdjustment;
    
    // Minimum 1500ml, maksimum 5000ml
    return idealGoal.clamp(1500.0, 5000.0);
  }
  
  // Profil verilerini güncelle
  Future<void> updateProfile({
    String? name,
    double? height,
    double? weight,
    String? gender,
    int? age,
    String? activityLevel,
    String? climate,
    String? wakeUpTime,
    String? sleepTime,
  }) async {
    // Önce state'i güncelle (name opsiyonel, eğer null ise mevcut değeri koru)
    _userData = _userData.copyWith(
      name: name ?? _userData.name,
      height: height,
      weight: weight,
      gender: gender,
      age: age,
      activityLevel: activityLevel,
      climate: climate,
      wakeUpTime: wakeUpTime,
      sleepTime: sleepTime,
    );
    
    // UI'ı hemen güncelle
    notifyListeners();
    
    // Kayıt işlemini arka planda yap
    await _saveUserData();
  }
  
  // Profil tamamlanmış mı kontrolü (sadece temel bilgiler)
  bool get isProfileComplete {
    return _userData.height != null &&
        _userData.weight != null &&
        _userData.gender != null &&
        _userData.activityLevel != null;
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

  // Ardışık gün sayısını güncelle (Calendar-based, strict day integrity)
  Future<void> updateConsecutiveDays(bool goalReached) async {
    if (goalReached) {
      // Bugünün tarihini al (calendar day, not 24-hour window)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Bugün streak zaten artırıldı mı kontrol et (strict calendar day comparison)
      bool alreadyIncrementedToday = false;
      if (_lastStreakIncrementDate != null) {
        final lastIncrement = DateTime(
          _lastStreakIncrementDate!.year,
          _lastStreakIncrementDate!.month,
          _lastStreakIncrementDate!.day,
        );
        // Calendar day comparison: same year, month, and day
        if (today.year == lastIncrement.year &&
            today.month == lastIncrement.month &&
            today.day == lastIncrement.day) {
          alreadyIncrementedToday = true;
        }
      }
      
      // Eğer bugün henüz artırılmadıysa, artır ve tarihi kaydet
      if (!alreadyIncrementedToday) {
        _consecutiveDays++;
        _lastStreakIncrementDate = today; // Store only the date, not the time
        await _saveUserData();
        notifyListeners();
      }
      // Eğer zaten artırıldıysa, hiçbir şey yapma (sessizce çık)
    } else {
      // Goal not reached: reset streak only if we're checking a new day
      // Don't reset if we're still on the same day
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Only reset if we haven't incremented today (meaning goal was never met today)
      bool shouldReset = true;
      if (_lastStreakIncrementDate != null) {
        final lastIncrement = DateTime(
          _lastStreakIncrementDate!.year,
          _lastStreakIncrementDate!.month,
          _lastStreakIncrementDate!.day,
        );
        // If we incremented today, don't reset (goal was met today)
        if (today.year == lastIncrement.year &&
            today.month == lastIncrement.month &&
            today.day == lastIncrement.day) {
          shouldReset = false;
        }
      }
      
      if (shouldReset) {
        _consecutiveDays = 0;
        _lastStreakIncrementDate = null;
        await _saveUserData();
        notifyListeners();
      }
    }
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

