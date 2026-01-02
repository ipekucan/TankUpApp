import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/decoration_item.dart';
import '../core/services/logger_service.dart';

class AquariumProvider extends ChangeNotifier {
  List<DecorationItem> _ownedDecorations = []; // Satın alınan tüm dekorasyonlar
  Map<String, String> _activeDecorations = {}; // Aktif dekorasyonlar (category -> decorationId)

  // Satın alınan dekorasyonlar
  List<DecorationItem> get ownedDecorations => _ownedDecorations;

  // Aktif dekorasyonlar
  Map<String, String> get activeDecorations => Map.unmodifiable(_activeDecorations);

  // Aktif dekorasyonları listeye çevir
  List<DecorationItem> get activeDecorationsList {
    return _activeDecorations.values
        .map((id) {
          try {
            return _ownedDecorations.firstWhere((d) => d.id == id);
          } catch (e) {
            // Dekorasyon bulunamadıysa null döndür (sonra filtrelenecek)
            return null;
          }
        })
        .whereType<DecorationItem>()
        .toList()
      ..sort((a, b) => a.layerOrder.compareTo(b.layerOrder));
  }

  // Constructor'da verileri SharedPreferences'tan yükle
  // main.dart'ta lazy: false ile hemen yüklenir
  AquariumProvider() {
    _loadAquariumData(); // Async metod, veriler yüklendikten sonra notifyListeners() çağrılır
  }

  // Dekorasyon satın alma
  Future<bool> purchaseDecoration(DecorationItem decoration) async {
    // Zaten satın alınmış mı kontrol et
    if (_ownedDecorations.any((d) => d.id == decoration.id)) {
      return false; // Zaten satın alınmış
    }

    _ownedDecorations.add(decoration);
    await _saveAquariumData();
    notifyListeners();
    return true;
  }

  // Aktif dekorasyon ayarlama (her kategoriden sadece bir tane)
  Future<void> setActiveDecoration(String decorationId) async {
    try {
      final decoration = _ownedDecorations.firstWhere(
        (d) => d.id == decorationId,
      );

      // Aynı kategorideki eski dekorasyonu kaldır
      _activeDecorations.remove(decoration.category);
      
      // Yeni dekorasyonu aktif yap
      _activeDecorations[decoration.category] = decorationId;

      await _saveAquariumData();
      notifyListeners();
    } catch (e, stackTrace) {
      // Dekorasyon bulunamadı - sessizce devam et
      LoggerService.logError('Failed to load active decorations', e, stackTrace);
    }
  }

  // Aktif dekorasyonu kaldırma
  Future<void> removeActiveDecoration(String category) async {
    _activeDecorations.remove(category);
    await _saveAquariumData();
    notifyListeners();
  }

  // Dekorasyonun aktif olup olmadığını kontrol et
  bool isDecorationActive(String decorationId) {
    return _activeDecorations.values.contains(decorationId);
  }

  // Dekorasyonun satın alınıp alınmadığını kontrol et
  bool isDecorationOwned(String decorationId) {
    return _ownedDecorations.any((d) => d.id == decorationId);
  }

  // Verileri kaydetme
  Future<void> _saveAquariumData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Satın alınan dekorasyonları kaydet
      final ownedJson = _ownedDecorations.map((d) => d.toJson()).toList();
      await prefs.setString('ownedDecorations', jsonEncode(ownedJson));
      
      // Aktif dekorasyonları kaydet
      await prefs.setString('activeDecorations', jsonEncode(_activeDecorations));
    } catch (e, stackTrace) {
      // Hata durumunda sessizce devam et
      LoggerService.logError('Failed to save active decorations', e, stackTrace);
    }
  }

  // Verileri yükleme
  Future<void> _loadAquariumData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Satın alınan dekorasyonları yükle
      final ownedJsonString = prefs.getString('ownedDecorations');
      if (ownedJsonString != null) {
        final ownedJson = jsonDecode(ownedJsonString) as List;
        _ownedDecorations = ownedJson
            .map((json) => DecorationItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      // Aktif dekorasyonları yükle
      final activeJsonString = prefs.getString('activeDecorations');
      if (activeJsonString != null) {
        final activeJson = jsonDecode(activeJsonString) as Map<String, dynamic>;
        _activeDecorations = activeJson.map((key, value) => MapEntry(key, value as String));
      }
      
      notifyListeners();
    } catch (e, stackTrace) {
      // Hata durumunda varsayılan değerler
      LoggerService.logError('Failed to load owned decorations', e, stackTrace);
      _ownedDecorations = [];
      _activeDecorations = {};
    }
  }

  // Tüm verileri sıfırlama
  Future<void> reset() async {
    _ownedDecorations = [];
    _activeDecorations = {};
    await _saveAquariumData();
    notifyListeners();
  }
}

