import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/achievement_model.dart';

class AchievementProvider extends ChangeNotifier {
  static const String _achievementsKey = 'achievements';
  
  List<Achievement> _achievements = [];

  List<Achievement> get achievements => _achievements;

  AchievementProvider() {
    _loadAchievements();
  }

  // Başarıları yükle
  Future<void> _loadAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = prefs.getString(_achievementsKey);
      
      if (achievementsJson != null) {
        final List<dynamic> decoded = jsonDecode(achievementsJson);
        _achievements = decoded
            .map((json) => Achievement.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        // İlk başlatma - varsayılan başarıları oluştur
        _initializeDefaultAchievements();
        await _saveAchievements();
      }
      notifyListeners();
    } catch (e) {
      // Hata durumunda varsayılan başarıları yükle
      _initializeDefaultAchievements();
      notifyListeners();
    }
  }

  // Varsayılan başarıları oluştur (Zorluk Seviyeleri: Kolay: 20, Orta: 50, Zor: 100)
  void _initializeDefaultAchievements() {
    _achievements = [
      // Kolay (20 Coin)
      Achievement(
        id: 'first_cup',
        name: 'İlk Bardak',
        description: 'Uygulamadaki ilk suyunu iç ve macerayı başlat!',
        coinReward: 20,
      ),
      Achievement(
        id: 'first_step',
        name: 'İlk Adım',
        description: 'İlk su içişini tamamla',
        coinReward: 20,
      ),
      Achievement(
        id: 'daily_goal',
        name: 'Günlük Hedef',
        description: 'Günlük su hedefine ulaş',
        coinReward: 20,
      ),
      // Orta (50 Coin)
      Achievement(
        id: 'streak_3',
        name: 'Seri Başlangıcı',
        description: '3 gün üst üste hedefe ulaş',
        coinReward: 50,
      ),
      Achievement(
        id: 'water_master',
        name: 'Su Ustası',
        description: 'Toplamda 10 litre su iç',
        coinReward: 50,
      ),
      // Zor (100 Coin)
      Achievement(
        id: 'streak_7',
        name: 'Haftalık Şampiyon',
        description: '7 gün üst üste hedefe ulaş',
        coinReward: 100,
      ),
    ];
  }

  // Başarıları kaydet
  Future<void> _saveAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = jsonEncode(
        _achievements.map((a) => a.toJson()).toList(),
      );
      await prefs.setString(_achievementsKey, achievementsJson);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  // Başarıyı aç
  Future<int> unlockAchievement(String achievementId) async {
    final achievementIndex = _achievements.indexWhere((a) => a.id == achievementId);
    
    if (achievementIndex != -1 && !_achievements[achievementIndex].isUnlocked) {
      _achievements[achievementIndex] = _achievements[achievementIndex].copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );
      await _saveAchievements();
      notifyListeners();
      return _achievements[achievementIndex].coinReward;
    }
    
    return 0;
  }

  // Başarı kontrolü - İlk Bardak
  Future<int> checkFirstCup() {
    return unlockAchievement('first_cup');
  }

  // Başarı kontrolü - İlk Adım
  Future<int> checkFirstStep() {
    return unlockAchievement('first_step');
  }

  // Başarı kontrolü - Günlük Hedef
  Future<int> checkDailyGoal() {
    return unlockAchievement('daily_goal');
  }

  // Başarı kontrolü - Su Ustası (toplam su kontrolü)
  Future<int> checkWaterMaster(double totalWaterConsumed) {
    if (totalWaterConsumed >= 10000.0) { // 10 litre = 10000 ml
      return unlockAchievement('water_master');
    }
    return Future.value(0);
  }

  // Başarı kontrolü - Seri Başlangıcı (3 gün üst üste)
  Future<int> checkStreak3(int consecutiveDays) {
    if (consecutiveDays >= 3) {
      return unlockAchievement('streak_3');
    }
    return Future.value(0);
  }

  // Başarı kontrolü - Haftalık Şampiyon (7 gün üst üste)
  Future<int> checkStreak7(int consecutiveDays) {
    if (consecutiveDays >= 7) {
      return unlockAchievement('streak_7');
    }
    return Future.value(0);
  }

  // Belirli bir başarının açık olup olmadığını kontrol et
  bool isAchievementUnlocked(String achievementId) {
    final achievement = _achievements.firstWhere(
      (a) => a.id == achievementId,
      orElse: () => Achievement(
        id: '',
        name: '',
        description: '',
        coinReward: 0,
      ),
    );
    return achievement.isUnlocked;
  }
}

