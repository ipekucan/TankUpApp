import 'package:flutter/foundation.dart';
import '../models/axolotl_model.dart';

class AxolotlProvider extends ChangeNotifier {
  AxolotlModel _axolotl = AxolotlModel.initial();

  // Aksolotl verileri
  AxolotlModel get axolotl => _axolotl;

  // Cilt rengi
  String get skinColor => _axolotl.skinColor;

  // Göz rengi
  String get eyeColor => _axolotl.eyeColor;

  // Aksesuarlar
  List<Accessory> get accessories => _axolotl.accessories;

  // Tank dekorasyonları
  List<TankDecoration> get tankDecorations => _axolotl.tankDecorations;

  // Seviye
  int get level => _axolotl.level;

  // Cilt rengini güncelleme
  void setSkinColor(String color) {
    _axolotl = _axolotl.copyWith(skinColor: color);
    notifyListeners();
  }

  // Göz rengini güncelleme
  void setEyeColor(String color) {
    _axolotl = _axolotl.copyWith(eyeColor: color);
    notifyListeners();
  }

  // Aksesuar ekleme
  void addAccessory(Accessory accessory) {
    final updatedAccessories = List<Accessory>.from(_axolotl.accessories);
    
    // Aynı tipte aksesuar varsa kaldır (tek bir şapka, tek bir gözlük vb.)
    updatedAccessories.removeWhere((a) => a.type == accessory.type);
    
    updatedAccessories.add(accessory);
    _axolotl = _axolotl.copyWith(accessories: updatedAccessories);
    notifyListeners();
  }

  // Aksesuar kaldırma
  void removeAccessory(String type) {
    final updatedAccessories = List<Accessory>.from(_axolotl.accessories);
    updatedAccessories.removeWhere((a) => a.type == type);
    _axolotl = _axolotl.copyWith(accessories: updatedAccessories);
    notifyListeners();
  }

  // Tank dekorasyonu ekleme
  void addTankDecoration(TankDecoration decoration) {
    final updatedDecorations = List<TankDecoration>.from(_axolotl.tankDecorations);
    
    // Aynı ID'ye sahip dekorasyon varsa kaldır (tekrar satın alınmasını önle)
    updatedDecorations.removeWhere((d) => d.id == decoration.id);
    
    updatedDecorations.add(decoration);
    _axolotl = _axolotl.copyWith(tankDecorations: updatedDecorations);
    notifyListeners();
  }

  // Tank dekorasyonu kaldırma
  void removeTankDecoration(String id) {
    final updatedDecorations = List<TankDecoration>.from(_axolotl.tankDecorations);
    updatedDecorations.removeWhere((d) => d.id == id);
    _axolotl = _axolotl.copyWith(tankDecorations: updatedDecorations);
    notifyListeners();
  }

  // Seviye artırma
  void levelUp() {
    _axolotl = _axolotl.copyWith(level: _axolotl.level + 1);
    notifyListeners();
  }

  // Seviye ayarlama
  void setLevel(int level) {
    if (level > 0) {
      _axolotl = _axolotl.copyWith(level: level);
      notifyListeners();
    }
  }

  // Tüm verileri sıfırlama
  void reset() {
    _axolotl = AxolotlModel.initial();
    notifyListeners();
  }
}

