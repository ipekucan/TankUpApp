// Modüler dekorasyon modeli
class DecorationItem {
  final String id;
  final String name;
  final String imagePath; // Görsel yolu (şimdilik icon kullanacağız)
  final int price;
  final double bottom; // Y pozisyonu (0.0 - 1.0)
  final double left; // X pozisyonu (0.0 - 1.0)
  final int layerOrder; // Katman sırası (z-index)
  final String category; // 'Zemin/Kum', 'Arka Plan', 'Süs'
  final int? requiredStreak; // Gerekli streak (null ise streak gereksiz)

  DecorationItem({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.price,
    required this.bottom,
    required this.left,
    required this.layerOrder,
    required this.category,
    this.requiredStreak,
  });

  // JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'price': price,
      'bottom': bottom,
      'left': left,
      'layerOrder': layerOrder,
      'category': category,
      'requiredStreak': requiredStreak,
    };
  }

  // JSON'dan oluşturma
  factory DecorationItem.fromJson(Map<String, dynamic> json) {
    return DecorationItem(
      id: json['id'] as String,
      name: json['name'] as String,
      imagePath: json['imagePath'] as String,
      price: json['price'] as int,
      bottom: (json['bottom'] as num).toDouble(),
      left: (json['left'] as num).toDouble(),
      layerOrder: json['layerOrder'] as int,
      category: json['category'] as String,
      requiredStreak: json['requiredStreak'] as int?,
    );
  }

  // Kopya oluşturma
  DecorationItem copyWith({
    String? id,
    String? name,
    String? imagePath,
    int? price,
    double? bottom,
    double? left,
    int? layerOrder,
    String? category,
    int? requiredStreak,
  }) {
    return DecorationItem(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      price: price ?? this.price,
      bottom: bottom ?? this.bottom,
      left: left ?? this.left,
      layerOrder: layerOrder ?? this.layerOrder,
      category: category ?? this.category,
      requiredStreak: requiredStreak ?? this.requiredStreak,
    );
  }
}

