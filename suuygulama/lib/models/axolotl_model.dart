class AxolotlModel {
  final String skinColor; // Cilt rengi
  final String eyeColor; // Göz rengi
  final List<Accessory> accessories; // Takılan aksesuarlar
  final List<TankDecoration> tankDecorations; // Tank dekorasyonları
  final int level; // Büyüme seviyesi

  AxolotlModel({
    required this.skinColor,
    required this.eyeColor,
    required this.accessories,
    this.tankDecorations = const [],
    required this.level,
  });

  // Varsayılan değerlerle başlangıç modeli
  factory AxolotlModel.initial() {
    return AxolotlModel(
      skinColor: 'Pink', // Pastel pembe
      eyeColor: 'Black',
      accessories: [],
      tankDecorations: [],
      level: 1,
    );
  }

  // Yeni değerlerle kopya oluşturma
  AxolotlModel copyWith({
    String? skinColor,
    String? eyeColor,
    List<Accessory>? accessories,
    List<TankDecoration>? tankDecorations,
    int? level,
  }) {
    return AxolotlModel(
      skinColor: skinColor ?? this.skinColor,
      eyeColor: eyeColor ?? this.eyeColor,
      accessories: accessories ?? this.accessories,
      tankDecorations: tankDecorations ?? this.tankDecorations,
      level: level ?? this.level,
    );
  }

  // JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'skinColor': skinColor,
      'eyeColor': eyeColor,
      'accessories': accessories.map((a) => a.toJson()).toList(),
      'tankDecorations': tankDecorations.map((d) => d.toJson()).toList(),
      'level': level,
    };
  }

  // JSON'dan oluşturma
  factory AxolotlModel.fromJson(Map<String, dynamic> json) {
    return AxolotlModel(
      skinColor: json['skinColor'] as String,
      eyeColor: json['eyeColor'] as String,
      accessories: (json['accessories'] as List)
          .map((a) => Accessory.fromJson(a as Map<String, dynamic>))
          .toList(),
      tankDecorations: (json['tankDecorations'] as List?)
              ?.map((d) => TankDecoration.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      level: json['level'] as int,
    );
  }
}

// Aksesuar modeli
class Accessory {
  final String type; // 'hat', 'glasses', 'scarf', vb.
  final String name; // Aksesuar adı
  final String color; // Aksesuar rengi

  Accessory({
    required this.type,
    required this.name,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'color': color,
    };
  }

  factory Accessory.fromJson(Map<String, dynamic> json) {
    return Accessory(
      type: json['type'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
    );
  }
}

// Tank dekorasyonu modeli
class TankDecoration {
  final String id; // Dekorasyon ID'si
  final String type; // 'coral', 'starfish', 'bubbles'
  final String name; // Dekorasyon adı
  final double x; // X pozisyonu (0.0 - 1.0)
  final double y; // Y pozisyonu (0.0 - 1.0)

  TankDecoration({
    required this.id,
    required this.type,
    required this.name,
    required this.x,
    required this.y,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'x': x,
      'y': y,
    };
  }

  factory TankDecoration.fromJson(Map<String, dynamic> json) {
    return TankDecoration(
      id: json['id'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }
}

