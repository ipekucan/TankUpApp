class UserModel {
  final String name; // Kullanıcı adı
  final double totalWaterConsumed; // Toplam içilen su (ml)
  final List<String> achievements; // Kazanılan başarılar
  final double? height; // Boy (cm)
  final double? weight; // Kilo (kg)
  final String? gender; // Cinsiyet ('male', 'female', 'other')
  final int? age; // Yaş
  final String? activityLevel; // Aktivite seviyesi ('low', 'medium', 'high')
  final String? wakeUpTime; // Uyanma saati (HH:mm formatında)
  final String? sleepTime; // Uyuma saati (HH:mm formatında)

  UserModel({
    this.name = '',
    this.totalWaterConsumed = 0.0,
    this.achievements = const [],
    this.height,
    this.weight,
    this.gender,
    this.age,
    this.activityLevel,
    this.wakeUpTime,
    this.sleepTime,
  });

  // Varsayılan değerlerle başlangıç modeli
  factory UserModel.initial() {
    return UserModel(
      name: '',
      totalWaterConsumed: 0.0,
      achievements: const [],
      height: null,
      weight: null,
      gender: null,
      age: null,
      activityLevel: null,
      wakeUpTime: null,
      sleepTime: null,
    );
  }

  // Yeni değerlerle kopya oluşturma
  UserModel copyWith({
    String? name,
    double? totalWaterConsumed,
    List<String>? achievements,
    double? height,
    double? weight,
    String? gender,
    int? age,
    String? activityLevel,
    String? wakeUpTime,
    String? sleepTime,
  }) {
    return UserModel(
      name: name ?? this.name,
      totalWaterConsumed: totalWaterConsumed ?? this.totalWaterConsumed,
      achievements: achievements ?? this.achievements,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      activityLevel: activityLevel ?? this.activityLevel,
      wakeUpTime: wakeUpTime ?? this.wakeUpTime,
      sleepTime: sleepTime ?? this.sleepTime,
    );
  }

  // JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'totalWaterConsumed': totalWaterConsumed,
      'achievements': achievements,
      'height': height,
      'weight': weight,
      'gender': gender,
      'age': age,
      'activityLevel': activityLevel,
      'wakeUpTime': wakeUpTime,
      'sleepTime': sleepTime,
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
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      gender: json['gender'] as String?,
      age: json['age'] as int?,
      activityLevel: json['activityLevel'] as String?,
      wakeUpTime: json['wakeUpTime'] as String?,
      sleepTime: json['sleepTime'] as String?,
    );
  }
}

