import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/challenge_card.dart';

class ChallengeProvider extends ChangeNotifier {
  static const String _challengesKey = 'active_challenges';
  static const String _challengeProgressKey = 'challenge_progress_';
  
  List<Challenge> _activeChallenges = [];
  
  List<Challenge> get activeChallenges => _activeChallenges;
  
  ChallengeProvider() {
    _loadChallenges();
  }
  
  // Mücadeleleri yükle
  Future<void> _loadChallenges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final challengesJson = prefs.getString(_challengesKey);
      
      if (challengesJson != null) {
        final List<dynamic> challengesList = jsonDecode(challengesJson);
        _activeChallenges = challengesList.map((json) {
          final challengeData = ChallengeData.getChallenges().firstWhere(
            (c) => c.id == json['id'],
            orElse: () => ChallengeData.getChallenges().first,
          );
          
          // İlerleme verilerini yükle
          final progressKey = _challengeProgressKey + json['id'];
          final currentProgress = prefs.getDouble(progressKey) ?? 0.0;
          final isCompleted = prefs.getBool('challenge_${json['id']}_completed') ?? false;
          
          return challengeData.copyWith(
            currentProgress: currentProgress,
            isCompleted: isCompleted,
          );
        }).toList();
      }
      
      notifyListeners();
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }
  
  // Mücadeleyi başlat (Çoklu mücadele desteği - aynı anda birden fazla mücadeleye katılabilir)
  Future<void> startChallenge(String challengeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Mücadele zaten aktif mi kontrol et (eğer aktifse, tekrar ekleme)
      if (_activeChallenges.any((c) => c.id == challengeId && !c.isCompleted)) {
        return; // Zaten aktif ve tamamlanmamış
      }
      
      // Mücadele verisini al
      final challenge = ChallengeData.getChallenges().firstWhere(
        (c) => c.id == challengeId,
      );
      
      // Eğer tamamlanmış bir mücadele varsa, yeni bir örnek olarak ekle
      final existingIndex = _activeChallenges.indexWhere((c) => c.id == challengeId);
      if (existingIndex != -1) {
        // Mevcut mücadeleyi yeni bir örnekle değiştir (sıfırdan başlat)
        _activeChallenges[existingIndex] = challenge;
      } else {
        // Aktif mücadelelere ekle
        _activeChallenges.add(challenge);
      }
      
      // SharedPreferences'a kaydet
      await _saveChallenges();
      
      // Başlangıç tarihini kaydet
      await prefs.setString('challenge_${challengeId}_start_date', DateTime.now().toIso8601String());
      
      notifyListeners();
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }
  
  // Mücadele ilerlemesini güncelle
  Future<int> updateProgress(String challengeId, double increment) async {
    try {
      final challengeIndex = _activeChallenges.indexWhere((c) => c.id == challengeId);
      
      if (challengeIndex == -1) {
        return 0; // Mücadele aktif değil
      }
      
      final challenge = _activeChallenges[challengeIndex];
      
      // Tamamlanmış mücadeleyi güncelleme
      if (challenge.isCompleted) {
        return 0;
      }
      
      final newProgress = challenge.currentProgress + increment;
      final isCompleted = newProgress >= challenge.targetValue;
      
      // İlerlemeyi güncelle
      _activeChallenges[challengeIndex] = challenge.copyWith(
        currentProgress: newProgress,
        isCompleted: isCompleted,
        progress: isCompleted ? 1.0 : (newProgress / challenge.targetValue),
        progressText: isCompleted 
            ? 'Tamamlandı! 🎉'
            : '${newProgress.toStringAsFixed(1)} / ${challenge.targetValue.toStringAsFixed(1)}',
      );
      
      // SharedPreferences'a kaydet
      final prefs = await SharedPreferences.getInstance();
      final progressKey = _challengeProgressKey + challengeId;
      await prefs.setDouble(progressKey, newProgress);
      
      if (isCompleted) {
        await prefs.setBool('challenge_${challengeId}_completed', true);
      }
      
      await _saveChallenges();
      notifyListeners();
      
      // Tamamlandıysa coin ödülü döndür
      if (isCompleted) {
        return challenge.coinReward;
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
    return 0;
  }
  
  // Mücadeleleri kaydet
  Future<void> _saveChallenges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final challengesJson = jsonEncode(
        _activeChallenges.map((c) => {
          'id': c.id,
        }).toList(),
      );
      await prefs.setString(_challengesKey, challengesJson);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }
  
  // Aktif mücadele var mı kontrol et (tamamlanmamış mücadele)
  bool hasActiveChallenge(String challengeId) {
    return _activeChallenges.any((c) => c.id == challengeId && !c.isCompleted);
  }
  
  // Tamamlanmamış aktif mücadeleler
  List<Challenge> get activeIncompleteChallenges {
    return _activeChallenges.where((c) => !c.isCompleted).toList();
  }
  
  // Mücadeleyi al
  Challenge? getChallenge(String challengeId) {
    try {
      return _activeChallenges.firstWhere((c) => c.id == challengeId);
    } catch (e) {
      return null;
    }
  }
}

