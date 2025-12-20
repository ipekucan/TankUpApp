class WaterModel {
  final double dailyGoal; // Günlük su hedefi (ml)
  final double consumedAmount; // İçilen miktar (ml)
  final double progressPercentage; // İlerleme yüzdesi (%)
  final int tankCoins; // Kazanılan TankCoin miktarı
  final DateTime? lastDrinkTime; // Son su içme zamanı
  final double dailyCalories; // Günlük toplam kalori

  WaterModel({
    required this.dailyGoal,
    required this.consumedAmount,
    required this.progressPercentage,
    required this.tankCoins,
    this.lastDrinkTime,
    this.dailyCalories = 0.0,
  });

  // Varsayılan değerlerle başlangıç modeli
  factory WaterModel.initial() {
    return WaterModel(
      dailyGoal: 5000.0, // 5L günlük hedef
      consumedAmount: 0.0, // Başlangıçta hiç su içilmemiş
      progressPercentage: 0.0, // Başlangıçta %0
      tankCoins: 0,
      lastDrinkTime: null,
      dailyCalories: 0.0, // Başlangıçta 0 kalori
    );
  }

  // Yeni değerlerle kopya oluşturma
  WaterModel copyWith({
    double? dailyGoal,
    double? consumedAmount,
    double? progressPercentage,
    int? tankCoins,
    DateTime? lastDrinkTime,
    double? dailyCalories,
  }) {
    return WaterModel(
      dailyGoal: dailyGoal ?? this.dailyGoal,
      consumedAmount: consumedAmount ?? this.consumedAmount,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      tankCoins: tankCoins ?? this.tankCoins,
      lastDrinkTime: lastDrinkTime ?? this.lastDrinkTime,
      dailyCalories: dailyCalories ?? this.dailyCalories,
    );
  }

  // JSON'a dönüştürme (ileride veri saklama için)
  Map<String, dynamic> toJson() {
    return {
      'dailyGoal': dailyGoal,
      'consumedAmount': consumedAmount,
      'progressPercentage': progressPercentage,
      'tankCoins': tankCoins,
      'lastDrinkTime': lastDrinkTime?.toIso8601String(),
      'dailyCalories': dailyCalories,
    };
  }

  // JSON'dan oluşturma
  factory WaterModel.fromJson(Map<String, dynamic> json) {
    return WaterModel(
      dailyGoal: (json['dailyGoal'] as num).toDouble(),
      consumedAmount: (json['consumedAmount'] as num).toDouble(),
      progressPercentage: (json['progressPercentage'] as num).toDouble(),
      tankCoins: json['tankCoins'] as int,
      lastDrinkTime: json['lastDrinkTime'] != null
          ? DateTime.parse(json['lastDrinkTime'] as String)
          : null,
      dailyCalories: (json['dailyCalories'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

