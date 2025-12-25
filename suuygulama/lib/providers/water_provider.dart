import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/water_model.dart';
import '../models/drink_model.dart';
import 'challenge_provider.dart';

class WaterProvider extends ChangeNotifier {
  static const String _waterDataKey = 'water_data';
  static const String _lastDrinkTimeKey = 'last_drink_time';
  static const String _lastResetDateKey = 'last_reset_date';
  static const String _drinkHistoryKey = 'drink_history'; // Son 30 günün verileri
  static const String _earlyBirdClaimedKey = 'early_bird_claimed'; // Erken Kuş bonusu alındı mı?
  static const String _nightOwlClaimedKey = 'night_owl_claimed'; // Gece Kuşu bonusu alındı mı?
  static const String _dailyGoalBonusClaimedKey = 'daily_goal_bonus_claimed'; // Günlük hedef bonusu alındı mı?
  static const double _dailyLimit = 5000.0; // 5 litre günlük limit (ml)
  
  WaterModel _waterData = WaterModel.initial();
  DateTime? _lastDrinkTime;
  DateTime? _lastResetDate;
  bool _isFirstDrink = true;
  Map<String, double> _drinkHistory = {}; // Tarih (YYYY-MM-DD) -> Miktar (ml)
  bool _earlyBirdClaimed = false; // Erken Kuş bonusu bugün alındı mı?
  bool _nightOwlClaimed = false; // Gece Kuşu bonusu bugün alındı mı?
  bool _dailyGoalBonusClaimed = false; // Günlük hedef bonusu bugün alındı mı?

  // Günlük su hedefi
  double get dailyGoal => _waterData.dailyGoal;

  // İçilen su miktarı (ml)
  double get consumedAmount => _waterData.consumedAmount;

  // İlerleme yüzdesi
  double get progressPercentage => _waterData.progressPercentage;

  // TankCoin miktarı
  int get tankCoins => _waterData.tankCoins;

  // Günlük toplam kalori
  double get dailyCalories => _waterData.dailyCalories;

  // Son 30 günün içme verileri
  Map<String, double> get drinkHistory => Map.unmodifiable(_drinkHistory);

  // Tüm su verileri
  WaterModel get waterData => _waterData;

  // Son su içme zamanı
  DateTime? get lastDrinkTime => _waterData.lastDrinkTime;

  WaterProvider() {
    _loadWaterData();
  }

  // Verileri yükle
  Future<void> _loadWaterData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Su verilerini yükle
      final waterDataJson = prefs.getString(_waterDataKey);
      if (waterDataJson != null) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(waterDataJson);
          _waterData = WaterModel.fromJson(decoded);
          
          // Eğer günlük hedef 5L değilse güncelle (eski veriler için)
          if (_waterData.dailyGoal != 5000.0) {
            _waterData = _waterData.copyWith(dailyGoal: 5000.0);
          }
          
          // consumedAmount'u kesinlikle kontrol et ve 0.0 yap
          // Null, negatif, NaN veya geçersiz değerler için 0.0 ata
          if (_waterData.consumedAmount.isNaN || 
              _waterData.consumedAmount.isInfinite || 
              _waterData.consumedAmount < 0) {
            _waterData = _waterData.copyWith(consumedAmount: 0.0);
          }
        } catch (e) {
          // JSON parse hatası durumunda varsayılan değerlerle başla
          _waterData = WaterModel.initial();
        }
      } else {
        // Veri null ise kesinlikle 0.0 ile başla
        _waterData = WaterModel.initial();
      }
      
      // consumedAmount'un kesinlikle 0.0 olduğundan emin ol (ekstra güvenlik)
      // Eğer consumedAmount geçersiz bir değerse veya 0 değilse, kontrol et
      if (_waterData.consumedAmount.isNaN || 
          _waterData.consumedAmount.isInfinite || 
          _waterData.consumedAmount < 0) {
        _waterData = _waterData.copyWith(consumedAmount: 0.0);
      }
      
      // Yeni gün başlamışsa veya veri yoksa consumedAmount kesinlikle 0.0 olmalı
      // Bu kontrol _checkAndResetDay() içinde de yapılıyor ama burada da emin oluyoruz
      
      // Son su içme zamanını yükle
      final lastDrinkTimeString = prefs.getString(_lastDrinkTimeKey);
      if (lastDrinkTimeString != null) {
        try {
          _lastDrinkTime = DateTime.parse(lastDrinkTimeString);
          // lastDrinkTime'ı _waterData'ya da kaydet
          _waterData = _waterData.copyWith(lastDrinkTime: _lastDrinkTime);
        } catch (e) {
          // Parse hatası durumunda null yap
          _lastDrinkTime = null;
          _waterData = _waterData.copyWith(lastDrinkTime: null);
        }
      } else {
        // lastDrinkTime null ise kesinlikle null yap
        _lastDrinkTime = null;
        _waterData = _waterData.copyWith(lastDrinkTime: null);
      }
      
      // Son sıfırlama tarihini yükle
      final lastResetDateString = prefs.getString(_lastResetDateKey);
      if (lastResetDateString != null) {
        try {
          _lastResetDate = DateTime.parse(lastResetDateString);
        } catch (e) {
          _lastResetDate = null;
        }
      } else {
        _lastResetDate = null;
      }
      
      // İçme geçmişini yükle (30 günlük veri)
      final drinkHistoryJson = prefs.getString(_drinkHistoryKey);
      if (drinkHistoryJson != null) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(drinkHistoryJson);
          _drinkHistory = decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
          // 30 günden eski verileri temizle
          _cleanOldHistory();
        } catch (e) {
          _drinkHistory = {};
        }
      } else {
        _drinkHistory = {};
      }
      
      // Bonus flag'lerini yükle
      _earlyBirdClaimed = prefs.getBool(_earlyBirdClaimedKey) ?? false;
      _nightOwlClaimed = prefs.getBool(_nightOwlClaimedKey) ?? false;
      _dailyGoalBonusClaimed = prefs.getBool(_dailyGoalBonusClaimedKey) ?? false;
      
      // Gün kontrolü yap (yeni gün başladıysa verileri sıfırla)
      await _checkAndResetDay();
      
      // Eski içme geçmişini temizle
      _cleanOldHistory();
      
      // consumedAmount'un kesinlikle 0.0 olduğundan emin ol (son kontrol)
      // Eski veriyi temizle - bir kerelik sıfırlama (tank dolu başlama sorununu çözmek için)
      if (_waterData.consumedAmount != 0.0) {
        _waterData = _waterData.copyWith(consumedAmount: 0.0);
        // Eski veriyi hafızadan da temizle
        await prefs.setString(_waterDataKey, jsonEncode(_waterData.toJson()));
      }
      
      // İlerleme yüzdesini güncelle
      _updateProgress();
      
      // UI'ı güncelle
      notifyListeners();
    } catch (e) {
      // Hata durumunda varsayılan değerlerle devam et (consumedAmount = 0.0)
      _waterData = WaterModel.initial();
      _lastDrinkTime = null;
      _lastResetDate = null;
      notifyListeners();
    }
  }

  // Verileri kaydet
  Future<void> _saveWaterData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Su verilerini kaydet
      final waterDataJson = jsonEncode(_waterData.toJson());
      await prefs.setString(_waterDataKey, waterDataJson);
      
      // Son su içme zamanını kaydet
      if (_lastDrinkTime != null) {
        await prefs.setString(_lastDrinkTimeKey, _lastDrinkTime!.toIso8601String());
      }
      
      // Son sıfırlama tarihini kaydet
      if (_lastResetDate != null) {
        await prefs.setString(_lastResetDateKey, _lastResetDate!.toIso8601String());
      }
      
      // İçme geçmişini kaydet (30 günlük veri)
      await prefs.setString(_drinkHistoryKey, jsonEncode(_drinkHistory));
      
      // Bonus flag'lerini kaydet
      await prefs.setBool(_earlyBirdClaimedKey, _earlyBirdClaimed);
      await prefs.setBool(_nightOwlClaimedKey, _nightOwlClaimed);
      await prefs.setBool(_dailyGoalBonusClaimedKey, _dailyGoalBonusClaimed);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  // Gün kontrolü ve sıfırlama
  Future<void> _checkAndResetDay() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    
    // Reset time'ı al (varsayılan: 00:00)
    final resetHour = prefs.getInt('reset_time_hour') ?? 0;
    final resetMinute = prefs.getInt('reset_time_minute') ?? 0;
    
    // Bugünün tarihini al
    final today = DateTime(now.year, now.month, now.day);
    
    if (_lastResetDate == null) {
      _lastResetDate = today;
      await _saveWaterData();
      return;
    }
    
    final lastReset = DateTime(
      _lastResetDate!.year,
      _lastResetDate!.month,
      _lastResetDate!.day,
    );
    
    // Bugünün reset zamanını hesapla
    final todayResetTime = DateTime(now.year, now.month, now.day, resetHour, resetMinute);
    
    // Yeni gün başladıysa (reset time geçtiyse) günlük verileri sıfırla
    bool shouldReset = false;
    
    if (today.isAfter(lastReset)) {
      // Tarih değişti, reset yapılmalı
      shouldReset = true;
    } else if (today.isAtSameMomentAs(lastReset) && now.isAfter(todayResetTime)) {
      // Aynı gün ama reset time geçti ve henüz reset yapılmamış
      // Bu durumda reset yapılmalı (ilk açılışta reset time geçmişse)
      final lastResetTime = DateTime(
        lastReset.year,
        lastReset.month,
        lastReset.day,
        resetHour,
        resetMinute,
      );
      if (now.isAfter(lastResetTime)) {
        shouldReset = true;
      }
    }
    
    if (shouldReset) {
      // Gün tamamlandı - 10 Coin ödülü ver
      _waterData = _waterData.copyWith(
        consumedAmount: 0.0,
        progressPercentage: 0.0,
        dailyCalories: 0.0,
        dailyGoal: 5000.0,
        lastDrinkTime: null,
        tankCoins: _waterData.tankCoins + 10, // Gün tamamlandı - 10 Coin
      );
      
      _lastResetDate = today;
      _lastDrinkTime = null;
      _isFirstDrink = true;
      
      // Bonus flag'lerini sıfırla
      _earlyBirdClaimed = false;
      _nightOwlClaimed = false;
      _dailyGoalBonusClaimed = false;
      await prefs.setBool(_earlyBirdClaimedKey, false);
      await prefs.setBool(_nightOwlClaimedKey, false);
      await prefs.setBool(_dailyGoalBonusClaimedKey, false);
      
      await _saveWaterData();
      notifyListeners();
    }
  }

  // Günlük limit kontrolü (5 litre)
  bool get hasReachedDailyLimit {
    return _waterData.consumedAmount >= _dailyLimit;
  }

  // Günlük hedefe ulaşıldı mı?
  bool get hasReachedDailyGoal {
    return _waterData.consumedAmount >= _waterData.dailyGoal;
  }

  // Günlük hedefi güncelleme
  Future<void> setDailyGoal(double goal) async {
    if (goal > 0) {
      _waterData = _waterData.copyWith(dailyGoal: goal);
      _updateProgress();
      await _saveWaterData();
      notifyListeners();
    }
  }

  // Su içme fonksiyonu - Varsayılan olarak su içer (geriye uyumluluk için)
  Future<DrinkWaterResult> drinkWater() async {
    final water = DrinkData.getDrinks().firstWhere((d) => d.id == 'water');
    return drink(water, 250.0);
  }

  // İçecek içme fonksiyonu - İçecek ve miktar parametreleri ile
  Future<DrinkWaterResult> drink(Drink drink, double amount, {BuildContext? context}) async {
    // Günlük limit kontrolü (5 litre)
    if (hasReachedDailyLimit) {
      return DrinkWaterResult(
        success: false,
        message: 'Günlük limitinize ulaştınız! (5 litre)',
        coinsReward: 0,
      );
    }

    // Hidrasyon faktörüne göre efektif miktarı hesapla
    final effectiveAmount = amount * drink.hydrationFactor;
    
    // Kalori hesapla (100ml başına kalori * miktar / 100)
    final calories = (drink.caloriePer100ml * amount) / 100.0;

    // Su miktarını efektif miktar kadar artır
    final newConsumedAmount = _waterData.consumedAmount + effectiveAmount;
    
    // Kaloriyi ekle
    final newDailyCalories = _waterData.dailyCalories + calories;

    // Günlük limit kontrolü (ekstra güvenlik - 5 litre)
    if (newConsumedAmount > _dailyLimit) {
      return DrinkWaterResult(
        success: false,
        message: 'Günlük limitinize ulaştınız! (5 litre)',
        coinsReward: 0,
      );
    }

    // Son su içme zamanını güncelle
    final now = DateTime.now();
    _lastDrinkTime = now;

    // Bugünün tarihini al (YYYY-MM-DD formatında)
    final todayKey = _getDateKey(now);
    _drinkHistory[todayKey] = (_drinkHistory[todayKey] ?? 0.0) + effectiveAmount;

    // Coin hesaplamaları
    int totalCoinsReward = 0;
    bool isLuckyDrink = false;
    bool isEarlyBird = false;
    bool isNightOwl = false;
    bool isDailyGoalBonus = false;

    // 1. Temel Coin (her içişte 10 Coin kaldırıldı - artık sadece bonuslar var)
    
    // 2. Şanslı Yudum (%5 ihtimal)
    final random = (now.millisecondsSinceEpoch % 100);
    if (random < 5) { // %5 ihtimal
      totalCoinsReward += 10;
      isLuckyDrink = true;
    }

    // 3. Erken Kuş Bonusu (Sabah 09:00'dan önce, ilk 500ml için tek seferlik)
    final currentHour = now.hour;
    if (!_earlyBirdClaimed && currentHour < 9 && newConsumedAmount <= 500.0) {
      totalCoinsReward += 5;
      isEarlyBird = true;
      _earlyBirdClaimed = true;
    }

    // 4. Gece Kuşu Bonusu (Akşam 20:00'dan sonra, günün son su ekleme işlemi)
    if (!_nightOwlClaimed && currentHour >= 20) {
      totalCoinsReward += 5;
      isNightOwl = true;
      _nightOwlClaimed = true;
    }

    // 5. Günlük Hedef Bonusu (Hedefe ulaşıldığında ekstra 15 Coin - tek seferlik)
    final wasGoalReachedBefore = _waterData.consumedAmount >= _waterData.dailyGoal;
    final isGoalReachedNow = newConsumedAmount >= _waterData.dailyGoal;
    
    if (!_dailyGoalBonusClaimed && !wasGoalReachedBefore && isGoalReachedNow) {
      totalCoinsReward += 15;
      isDailyGoalBonus = true;
      _dailyGoalBonusClaimed = true;
    }

    // Mücadele takibi - Sadece su içecekleri için (büyük bardak >= 330ml)
    int challengeCoinsReward = 0;
    if (context != null && drink.id == 'water' && amount >= 330.0) {
      try {
        final challengeProvider = Provider.of<ChallengeProvider>(context, listen: false);
        
        // Kafein Avcısı mücadelesi aktif mi kontrol et
        if (challengeProvider.hasActiveChallenge('caffeine_hunter')) {
          // İlerlemeyi 1 bardak artır
          challengeCoinsReward = await challengeProvider.updateProgress('caffeine_hunter', 1.0);
          
          // Mücadele tamamlandıysa bildirim göster
          if (challengeCoinsReward > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tebrikler! Kafein Avcısı mücadelesini tamamladın! 🎉 +$challengeCoinsReward Coin'),
                    backgroundColor: const Color(0xFF8B4513),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            });
          }
        }
      } catch (e) {
        // ChallengeProvider yoksa veya hata varsa sessizce devam et
      }
    }
    
    // Coin'leri ekle (mücadele ödülü dahil)
    final newTankCoins = _waterData.tankCoins + totalCoinsReward + challengeCoinsReward;

    // Verileri güncelle
    _waterData = _waterData.copyWith(
      consumedAmount: newConsumedAmount,
      tankCoins: newTankCoins,
      lastDrinkTime: now,
      dailyCalories: newDailyCalories,
    );

    // İlerleme yüzdesini güncelle
    _updateProgress();

    // Verileri kaydet
    await _saveWaterData();

    // UI'ı güncelle
    notifyListeners();

    // İlk içiş kontrolü için flag
    final wasFirstDrink = _isFirstDrink;
    _isFirstDrink = false;

    // Mesaj oluştur
    String message = '${drink.name} içildi!';
    final totalReward = totalCoinsReward + challengeCoinsReward;
    if (totalReward > 0) {
      message += ' +$totalReward Coin';
      if (isLuckyDrink) {
        message += ' (Şanslı Yudum! 🍀)';
      }
      if (isEarlyBird) {
        message += ' (Erken Kuş! 🌅)';
      }
      if (isNightOwl) {
        message += ' (Gece Kuşu! 🌙)';
      }
      if (isDailyGoalBonus) {
        message += ' (Hedefe Ulaşıldı! 🎯)';
      }
    }

    return DrinkWaterResult(
      success: true,
      message: message,
      coinsReward: totalCoinsReward + challengeCoinsReward,
      isFirstDrink: wasFirstDrink,
      isLuckyDrink: isLuckyDrink,
      isEarlyBird: isEarlyBird,
      isNightOwl: isNightOwl,
      isDailyGoalBonus: isDailyGoalBonus,
    );
  }

  // Tarih anahtarı oluştur (YYYY-MM-DD)
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // 30 günden eski verileri temizle
  void _cleanOldHistory() {
    final now = DateTime.now();
    final cutoffDate = now.subtract(const Duration(days: 30));
    final cutoffKey = _getDateKey(cutoffDate);
    
    _drinkHistory.removeWhere((key, value) {
      // Tarih karşılaştırması (string karşılaştırması yeterli çünkü YYYY-MM-DD formatı)
      return key.compareTo(cutoffKey) < 0;
    });
  }

  // Aksolot mesajları listesi (15-20 mesaj)
  static final List<String> axolotlMessages = [
    'Harika görünüyorsun! 💙',
    'Su içmek cildine iyi gelecek! ✨',
    'Tankımız pırıl pırıl! 🌊',
    'Bugün harika bir gün! 💪',
    'Su içmeyi unutma! 💧',
    'Seni çok seviyorum! 🌟',
    'Birlikte büyüyoruz! ☀️',
    'Her gün daha iyi oluyoruz! 💙',
    'Su içmek çok önemli! 💪',
    'Seninle olmak harika! ✨',
    'Bugün de harika bir gün olacak! 🌊',
    'Mükemmel gidiyorsun! 🎉',
    'Su içmek sağlıklı! 💧',
    'Tankımız çok temiz! 🌟',
    'Sen harikasın! 💙',
    'Su içmek seni güçlendirir! 💪',
    'Birlikte çok güzeliz! ✨',
    'Her gün daha iyi! 🌊',
    'Su içmek zindelik verir! 💧',
    'Seni seviyorum! 💙',
  ];
  
  // Rastgele mesaj al
  String getRandomMessage(String? userName) {
    final random = DateTime.now().millisecondsSinceEpoch % axolotlMessages.length;
    String message = axolotlMessages[random];
    
    // Eğer isim varsa mesaja ekle
    if (userName != null && userName.isNotEmpty) {
      // Bazı mesajlarda ismi kullan
      if (random % 3 == 0) {
        message = message.replaceFirst('görünüyorsun', '$userName, görünüyorsun');
        message = message.replaceFirst('Sen', '$userName, sen');
      }
    }
    
    return message;
  }

  // Tank temizlik durumu - Gerçek 24 saatlik mantık
  // Başlangıç değeri: false (tank temiz başlar)
  // Eğer hiç su içilmediyse (lastDrinkTime == null) tank kirli BAŞLAMASIN
  bool get isTankDirty {
    // Hiç su içilmemişse tank temiz kabul et (kirli başlamasın)
    // lastDrinkTime null ise kesinlikle false döndür
    if (_waterData.lastDrinkTime == null || _lastDrinkTime == null) {
      return false;
    }
    
    // Son su içme zamanından 24 saat geçtiyse kirli
    final now = DateTime.now();
    final difference = now.difference(_waterData.lastDrinkTime!);
    
    // 24 saatten fazla geçtiyse kirli, değilse temiz
    return difference.inHours >= 24;
  }
  
  // Test için: Kirliliği simüle et (lastDrinkTime'ı 25 saat öncesine çek)
  Future<void> simulateDirtyTank() async {
    final testTime = DateTime.now().subtract(const Duration(hours: 25));
    _lastDrinkTime = testTime;
    _waterData = _waterData.copyWith(lastDrinkTime: testTime);
    await _saveWaterData();
    notifyListeners();
  }

  // İlerleme yüzdesini hesaplama
  void _updateProgress() {
    final percentage = (_waterData.consumedAmount / _waterData.dailyGoal * 100).clamp(0.0, 100.0);
    _waterData = _waterData.copyWith(progressPercentage: percentage);
  }

  // Tank doluluk yüzdesi (0.0 - 1.0 arası)
  // Formül: (Günlük İçilen / Günlük Hedef)
  double get tankFillPercentage {
    // Eğer hiç su içilmediyse tank tamamen boş (0.0)
    if (_waterData.consumedAmount == 0.0) return 0.0;
    
    // Günlük hedef 0 ise 0 döndür (bölme hatası önleme)
    if (_waterData.dailyGoal == 0.0) return 0.0;
    
    // Normal hesaplama: (İçilen / Hedef)
    return (_waterData.consumedAmount / _waterData.dailyGoal).clamp(0.0, 1.0);
  }
  
  // Günlük hedefi güncelle (Profil sayfasından çağrılacak)
  Future<void> updateDailyGoal(double newGoal) async {
    // Hedef 1.5L ile 5L arasında olmalı
    final clampedGoal = newGoal.clamp(1500.0, 5000.0);
    _waterData = _waterData.copyWith(dailyGoal: clampedGoal);
    _updateProgress();
    await _saveWaterData();
    notifyListeners();
  }
  
  // Test için verileri sıfırla
  Future<void> resetData() async {
    _waterData = WaterModel.initial();
    _lastDrinkTime = null;
    _lastResetDate = null;
    _isFirstDrink = true;
    _drinkHistory = {};
    await _saveWaterData();
    notifyListeners();
  }

  // Coin düşürme fonksiyonu (mağazada satın alma için)
  Future<bool> spendCoins(int amount) async {
    if (amount > 0 && _waterData.tankCoins >= amount) {
      _waterData = _waterData.copyWith(
        tankCoins: _waterData.tankCoins - amount,
      );
      await _saveWaterData();
      notifyListeners();
      return true;
    }
    return false;
  }

  // Coin ekleme fonksiyonu (başarı ödülleri için)
  Future<void> addCoins(int amount) async {
    if (amount > 0) {
      _waterData = _waterData.copyWith(
        tankCoins: _waterData.tankCoins + amount,
      );
      await _saveWaterData();
      notifyListeners();
    }
  }

  // Coin'i sıfırla (onboarding tamamlandığında)
  Future<void> resetCoins() async {
    _waterData = _waterData.copyWith(
      tankCoins: 0,
    );
    await _saveWaterData();
    notifyListeners();
  }

  // Tüm verileri sıfırlama
  Future<void> resetAll() async {
    _waterData = WaterModel.initial();
    _lastDrinkTime = null;
    _lastResetDate = null;
    _isFirstDrink = true;
    await _saveWaterData();
    notifyListeners();
  }
}

// Su içme sonucu modeli
class DrinkWaterResult {
  final bool success;
  final String message;
  final int coinsReward;
  final bool isFirstDrink;
  final bool isLuckyDrink; // Şanslı Yudum (%5 ihtimal)
  final bool isEarlyBird; // Erken Kuş bonusu
  final bool isNightOwl; // Gece Kuşu bonusu
  final bool isDailyGoalBonus; // Günlük hedef bonusu

  DrinkWaterResult({
    required this.success,
    required this.message,
    this.coinsReward = 0,
    this.isFirstDrink = false,
    this.isLuckyDrink = false,
    this.isEarlyBird = false,
    this.isNightOwl = false,
    this.isDailyGoalBonus = false,
  });
}
