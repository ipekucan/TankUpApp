// Mağaza ürünü modeli
class ShopItem {
  final String id;
  final String name;
  final String description;
  final int price; // TankCoin cinsinden fiyat
  final ShopItemType type;
  final Map<String, dynamic> data; // Ürün tipine göre ek veriler

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.type,
    this.data = const {},
  });
}

// Mağaza ürün tipleri
enum ShopItemType {
  accessory, // Aksesuar (şapka, gözlük, atkı)
  skinColor, // Cilt rengi
  eyeColor, // Göz rengi
  decoration, // Tank dekorasyonu (mercan, deniz yıldızı, hava kabarcıkları)
}

// Mağaza verileri
class ShopData {
  static List<ShopItem> getItems() {
    return [
      // Aksesuarlar
      ShopItem(
        id: 'hat_stylish',
        name: 'Şık Şapka',
        description: 'Çok şık bir şapka',
        price: 50,
        type: ShopItemType.accessory,
        data: {
          'type': 'hat',
          'name': 'Şık Şapka',
          'color': 'Gold',
        },
      ),
      ShopItem(
        id: 'glasses_sun',
        name: 'Güneş Gözlüğü',
        description: 'Şık bir güneş gözlüğü',
        price: 100,
        type: ShopItemType.accessory,
        data: {
          'type': 'glasses',
          'name': 'Güneş Gözlüğü',
          'color': 'Gray',
        },
      ),
      ShopItem(
        id: 'scarf_red',
        name: 'Kırmızı Atkı',
        description: 'Sıcacık bir atkı',
        price: 120,
        type: ShopItemType.accessory,
        data: {
          'type': 'scarf',
          'name': 'Kırmızı Atkı',
          'color': 'Red',
        },
      ),
      // Cilt renkleri
      ShopItem(
        id: 'skin_blue',
        name: 'Mavi Cilt',
        description: 'Pastel mavi cilt rengi',
        price: 150,
        type: ShopItemType.skinColor,
        data: {
          'color': 'Blue',
        },
      ),
      ShopItem(
        id: 'skin_yellow',
        name: 'Sarı Cilt',
        description: 'Pastel sarı cilt rengi',
        price: 200,
        type: ShopItemType.skinColor,
        data: {
          'color': 'Yellow',
        },
      ),
      ShopItem(
        id: 'skin_green',
        name: 'Yeşil Cilt',
        description: 'Pastel yeşil cilt rengi',
        price: 200,
        type: ShopItemType.skinColor,
        data: {
          'color': 'Green',
        },
      ),
      // Göz renkleri
      ShopItem(
        id: 'eye_brown',
        name: 'Kahverengi Göz',
        description: 'Sıcak kahverengi gözler',
        price: 150,
        type: ShopItemType.eyeColor,
        data: {
          'color': 'Brown',
        },
      ),
      ShopItem(
        id: 'eye_blue',
        name: 'Mavi Göz',
        description: 'Parlak mavi gözler',
        price: 150,
        type: ShopItemType.eyeColor,
        data: {
          'color': 'Blue',
        },
      ),
      // Tank dekorasyonları
      ShopItem(
        id: 'decoration_coral',
        name: 'Mercan',
        description: 'Renkli bir mercan',
        price: 80,
        type: ShopItemType.decoration,
        data: {
          'type': 'coral',
          'name': 'Mercan',
          'x': 0.15, // Sol alt köşe
          'y': 0.2,
        },
      ),
      ShopItem(
        id: 'decoration_starfish',
        name: 'Deniz Yıldızı',
        description: 'Sevimli bir deniz yıldızı',
        price: 70,
        type: ShopItemType.decoration,
        data: {
          'type': 'starfish',
          'name': 'Deniz Yıldızı',
          'x': 0.85, // Sağ alt köşe
          'y': 0.15,
        },
      ),
      ShopItem(
        id: 'decoration_bubbles',
        name: 'Hava Kabarcıkları',
        description: 'Yüzen hava kabarcıkları',
        price: 60,
        type: ShopItemType.decoration,
        data: {
          'type': 'bubbles',
          'name': 'Hava Kabarcıkları',
          'x': 0.5, // Orta üst
          'y': 0.3,
        },
      ),
    ];
  }
}

