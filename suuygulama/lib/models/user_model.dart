class UserModel {
  final String name; // Kullanıcı adı
  final double totalWaterConsumed; // Toplam içilen su (ml)
  final List<String> achievements; // Kazanılan başarılar

  UserModel({
    this.name = '',
    this.totalWaterConsumed = 0.0,
    this.achievements = const [],
  });

  // Varsayılan değerlerle başlangıç modeli
  factory UserModel.initial() {
    return UserModel(
      name: '',
      totalWaterConsumed: 0.0,
      achievements: const [],
    );
  }

  // Yeni değerlerle kopya oluşturma
  UserModel copyWith({
    String? name,
    double? totalWaterConsumed,
    List<String>? achievements,
  }) {
    return UserModel(
      name: name ?? this.name,
      totalWaterConsumed: totalWaterConsumed ?? this.totalWaterConsumed,
      achievements: achievements ?? this.achievements,
    );
  }

  // JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'totalWaterConsumed': totalWaterConsumed,
      'achievements': achievements,
    };
  }

  // JSON'dan oluşturma
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] as String? ?? '',
      totalWaterConsumed: (json['totalWaterConsumed'] as num?)?.toDouble() ?? 0.0,
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}

