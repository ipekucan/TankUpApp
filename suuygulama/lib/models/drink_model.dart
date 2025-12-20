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

// Varsayılan içecekler
class DrinkData {
  static List<Drink> getDrinks() {
    return [
      Drink(
        id: 'water',
        name: 'Su',
        caloriePer100ml: 0.0,
        hydrationFactor: 1.0, // %100 hidrasyon
      ),
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
        id: 'juice',
        name: 'Meyve Suyu',
        caloriePer100ml: 45.0,
        hydrationFactor: 0.9, // %90 hidrasyon
      ),
      Drink(
        id: 'soda',
        name: 'Gazlı İçecek',
        caloriePer100ml: 42.0,
        hydrationFactor: 0.6, // %60 hidrasyon
      ),
      Drink(
        id: 'sports',
        name: 'Spor İçeceği',
        caloriePer100ml: 25.0,
        hydrationFactor: 0.95, // %95 hidrasyon
      ),
    ];
  }
}

