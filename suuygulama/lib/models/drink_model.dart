// İçecek modeli
class Drink {
  final String id;
  final String name;
  final double caloriePer100ml; // 100ml başına kalori
  final double hydrationFactor; // Hidrasyon faktörü (0.0 - 1.0), Su %100, Kahve %70 vb.

  Drink({
    required this.id,
    required this.name,
    required this.caloriePer100ml,
    required this.hydrationFactor,
  });

  // JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'caloriePer100ml': caloriePer100ml,
      'hydrationFactor': hydrationFactor,
    };
  }

  // JSON'dan oluşturma
  factory Drink.fromJson(Map<String, dynamic> json) {
    return Drink(
      id: json['id'] as String,
      name: json['name'] as String,
      caloriePer100ml: (json['caloriePer100ml'] as num).toDouble(),
      hydrationFactor: (json['hydrationFactor'] as num).toDouble(),
    );
  }
}

// Varsayılan içecekler - Kategorize edilmiş
class DrinkData {
  static List<Drink> getDrinks() {
    return [
      // Temel İçecekler
      Drink(
        id: 'water',
        name: 'Su',
        caloriePer100ml: 0.0,
        hydrationFactor: 1.0, // %100 hidrasyon
      ),
      Drink(
        id: 'mineral_water',
        name: 'Maden Suyu',
        caloriePer100ml: 0.0,
        hydrationFactor: 0.95, // %95 hidrasyon
      ),
      
      // Sıcak İçecekler
      Drink(
        id: 'coffee',
        name: 'Kahve',
        caloriePer100ml: 2.0,
        hydrationFactor: 0.7, // %70 hidrasyon
      ),
      Drink(
        id: 'tea',
        name: 'Çay',
        caloriePer100ml: 1.0,
        hydrationFactor: 0.8, // %80 hidrasyon
      ),
      Drink(
        id: 'herbal_tea',
        name: 'Bitki Çay',
        caloriePer100ml: 0.5,
        hydrationFactor: 0.85, // %85 hidrasyon
      ),
      Drink(
        id: 'green_tea',
        name: 'Yeşil Çay',
        caloriePer100ml: 1.0,
        hydrationFactor: 0.85, // %85 hidrasyon
      ),
      
      // Soğuk İçecekler
      Drink(
        id: 'cold_tea',
        name: 'Soğuk Çay',
        caloriePer100ml: 30.0,
        hydrationFactor: 0.75, // %75 hidrasyon
      ),
      Drink(
        id: 'lemonade',
        name: 'Limonata',
        caloriePer100ml: 35.0,
        hydrationFactor: 0.85, // %85 hidrasyon
      ),
      Drink(
        id: 'iced_coffee',
        name: 'Soğuk Kahve',
        caloriePer100ml: 15.0,
        hydrationFactor: 0.7, // %70 hidrasyon
      ),
      
      // Süt Ürünleri
      Drink(
        id: 'ayran',
        name: 'Ayran',
        caloriePer100ml: 40.0,
        hydrationFactor: 0.9, // %90 hidrasyon
      ),
      Drink(
        id: 'kefir',
        name: 'Kefir',
        caloriePer100ml: 45.0,
        hydrationFactor: 0.88, // %88 hidrasyon
      ),
      Drink(
        id: 'milk',
        name: 'Süt',
        caloriePer100ml: 60.0,
        hydrationFactor: 0.85, // %85 hidrasyon
      ),
      
      // Meyve İçecekleri
      Drink(
        id: 'juice',
        name: 'Meyve Suyu',
        caloriePer100ml: 45.0,
        hydrationFactor: 0.9, // %90 hidrasyon
      ),
      Drink(
        id: 'smoothie',
        name: 'Smoothie',
        caloriePer100ml: 55.0,
        hydrationFactor: 0.85, // %85 hidrasyon
      ),
      Drink(
        id: 'fresh_juice',
        name: 'Taze Suyu',
        caloriePer100ml: 50.0,
        hydrationFactor: 0.92, // %92 hidrasyon
      ),
      
      // Spor ve Sağlık
      Drink(
        id: 'sports',
        name: 'Spor İçeceği',
        caloriePer100ml: 25.0,
        hydrationFactor: 0.95, // %95 hidrasyon
      ),
      Drink(
        id: 'protein_shake',
        name: 'Protein',
        caloriePer100ml: 80.0,
        hydrationFactor: 0.75, // %75 hidrasyon
      ),
      Drink(
        id: 'coconut_water',
        name: 'Hindistan C.',
        caloriePer100ml: 20.0,
        hydrationFactor: 0.95, // %95 hidrasyon
      ),
      
      // Diğer
      Drink(
        id: 'soda',
        name: 'Gazlı',
        caloriePer100ml: 42.0,
        hydrationFactor: 0.6, // %60 hidrasyon
      ),
      Drink(
        id: 'energy_drink',
        name: 'Enerji',
        caloriePer100ml: 45.0,
        hydrationFactor: 0.65, // %65 hidrasyon
      ),
      Drink(
        id: 'detox_water',
        name: 'Detoks',
        caloriePer100ml: 5.0,
        hydrationFactor: 0.98, // %98 hidrasyon
      ),
    ];
  }
}

