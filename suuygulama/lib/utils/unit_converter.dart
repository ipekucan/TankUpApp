// Birim dönüşüm yardımcı fonksiyonları
class UnitConverter {
  // ml'den fl oz'a dönüşüm (1 fl oz = 29.5735 ml)
  static double mlToFlOz(double ml) {
    return ml / 29.5735;
  }

  // fl oz'dan ml'ye dönüşüm
  static double flOzToMl(double flOz) {
    return flOz * 29.5735;
  }

  // L'den fl oz'a dönüşüm (1 L = 33.814 fl oz)
  static double lToFlOz(double liters) {
    return liters * 33.814;
  }

  // fl oz'dan L'ye dönüşüm
  static double flOzToL(double flOz) {
    return flOz / 33.814;
  }

  // kg'dan lbs'e dönüşüm (1 kg = 2.20462 lbs)
  static double kgToLbs(double kg) {
    return kg * 2.20462;
  }

  // lbs'den kg'a dönüşüm
  static double lbsToKg(double lbs) {
    return lbs / 2.20462;
  }

  // ml'yi metrik veya imperial'e göre formatla
  static String formatVolume(double ml, bool isMetric) {
    if (isMetric) {
      if (ml >= 1000) {
        return '${(ml / 1000).toStringAsFixed(1)} L';
      } else {
        return '${ml.toStringAsFixed(0)} ml';
      }
    } else {
      final flOz = mlToFlOz(ml);
      return '${flOz.toStringAsFixed(1)} fl oz';
    }
  }

  // Ağırlığı metrik veya imperial'e göre formatla
  static String formatWeight(double kg, bool isMetric) {
    if (isMetric) {
      return '${kg.toStringAsFixed(1)} kg';
    } else {
      final lbs = kgToLbs(kg);
      return '${lbs.toStringAsFixed(1)} lbs';
    }
  }

  // En yakın standart oz değerine yuvarla (8 oz, 12 oz, 16 oz, vb.)
  static double roundToNearestStandardOz(double flOz) {
    final standardOzValues = [4.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0, 20.0, 24.0, 32.0];
    double closest = standardOzValues[0];
    double minDiff = (flOz - closest).abs();
    
    for (final value in standardOzValues) {
      final diff = (flOz - value).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = value;
      }
    }
    
    return closest;
  }
}

