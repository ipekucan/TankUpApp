import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../providers/water_provider.dart';
import '../providers/axolotl_provider.dart';
import '../models/shop_item.dart';
import '../models/axolotl_model.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.verySoftBlue,
      appBar: AppBar(
        title: const Text('Mağaza'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer2<WaterProvider, AxolotlProvider>(
        builder: (context, waterProvider, axolotlProvider, child) {
          final shopItems = ShopData.getItems();
          
          return Column(
            children: [
              // Coin göstergesi
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.goldCoin,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.goldCoin.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${waterProvider.tankCoins} TankCoin',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Ürün listesi
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: shopItems.length,
                  itemBuilder: (context, index) {
                    final item = shopItems[index];
                    final isOwned = _isItemOwned(item, axolotlProvider);
                    
                    return _buildShopCard(
                      context,
                      item,
                      waterProvider,
                      axolotlProvider,
                      isOwned,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Ürünün sahip olunup olunmadığını kontrol et
  bool _isItemOwned(ShopItem item, AxolotlProvider provider) {
    switch (item.type) {
      case ShopItemType.accessory:
        return provider.accessories.any(
          (a) => a.type == item.data['type'],
        );
      case ShopItemType.skinColor:
        return provider.skinColor == item.data['color'];
      case ShopItemType.eyeColor:
        return provider.eyeColor == item.data['color'];
      case ShopItemType.decoration:
        return provider.tankDecorations.any(
          (d) => d.id == item.id,
        );
    }
  }

  // Mağaza kartı widget'ı - Yumuşak köşeli, pastel tonlu ve minimal tasarım
  Widget _buildShopCard(
    BuildContext context,
    ShopItem item,
    WaterProvider waterProvider,
    AxolotlProvider axolotlProvider,
    bool isOwned,
  ) {
    final canAfford = waterProvider.tankCoins >= item.price;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isOwned
            ? null
            : canAfford
                ? () async {
                    await _purchaseItem(context, item, waterProvider, axolotlProvider);
                  }
                : null,
        borderRadius: BorderRadius.circular(30),
        child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isOwned
                ? AppColors.softPinkButton.withValues(alpha: 0.3)
                : canAfford
                    ? AppColors.softPinkButton.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 3),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Ürün ikonu/önizleme - Yumuşak köşeli, pastel tonlu
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: _getItemColor(item).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  _getItemIcon(item),
                  size: 36,
                  color: _getItemColor(item),
                ),
              ),
              const SizedBox(width: 16),
              
              // Ürün bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: isOwned
                                  ? Colors.grey[600]
                                  : const Color(0xFF4A5568),
                            ),
                          ),
                        ),
                        if (isOwned)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.softPinkButton.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Satın Alındı',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4A5568),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.monetization_on,
                          size: 16,
                          color: canAfford
                              ? AppColors.goldCoin
                              : Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.price} Coin',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: canAfford
                                ? AppColors.goldCoin
                                : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Satın Al butonu - Minimal ve yumuşak köşeli
              if (!isOwned)
                Container(
                  width: 90,
                  height: 40,
                  decoration: BoxDecoration(
                    color: canAfford
                        ? AppColors.softPinkButton
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      canAfford ? 'Satın Al' : 'Yetersiz',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: canAfford
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  // Ürün ikonu
  IconData _getItemIcon(ShopItem item) {
    switch (item.type) {
      case ShopItemType.accessory:
        final type = item.data['type'] as String;
        if (type == 'glasses') return Icons.visibility;
        if (type == 'hat') return Icons.check_circle;
        if (type == 'scarf') return Icons.favorite;
        return Icons.shopping_bag;
      case ShopItemType.skinColor:
        return Icons.palette;
      case ShopItemType.eyeColor:
        return Icons.remove_red_eye;
      case ShopItemType.decoration:
        final type = item.data['type'] as String;
        if (type == 'coral') return Icons.eco;
        if (type == 'starfish') return Icons.star;
        if (type == 'bubbles') return Icons.water_drop;
        return Icons.auto_awesome;
    }
  }

  // Ürün rengi
  Color _getItemColor(ShopItem item) {
    switch (item.type) {
      case ShopItemType.accessory:
        final type = item.data['type'] as String;
        if (type == 'glasses') return AppColors.glassesColor;
        if (type == 'hat') return AppColors.hatColor;
        if (type == 'scarf') return AppColors.scarfColor;
        return AppColors.softPink;
      case ShopItemType.skinColor:
        return AppColors.blueSkin;
      case ShopItemType.eyeColor:
        return AppColors.blueEye;
      case ShopItemType.decoration:
        final type = item.data['type'] as String;
        if (type == 'coral') return const Color(0xFFFF6B9D); // Pembe mercan
        if (type == 'starfish') return const Color(0xFFFFD93D); // Sarı deniz yıldızı
        if (type == 'bubbles') return AppColors.waterColor; // Mavi kabarcıklar
        return AppColors.softPink;
    }
  }

  // Ürün satın alma
  Future<void> _purchaseItem(
    BuildContext context,
    ShopItem item,
    WaterProvider waterProvider,
    AxolotlProvider axolotlProvider,
  ) async {
    // Coin kontrolü ve düşürme
    if (!(await waterProvider.spendCoins(item.price))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yeterli TankCoin\'iniz yok!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Ürünü ekle
    switch (item.type) {
      case ShopItemType.accessory:
        final accessory = Accessory(
          type: item.data['type'] as String,
          name: item.data['name'] as String,
          color: item.data['color'] as String,
        );
        axolotlProvider.addAccessory(accessory);
        break;
      case ShopItemType.skinColor:
        axolotlProvider.setSkinColor(item.data['color'] as String);
        break;
      case ShopItemType.eyeColor:
        axolotlProvider.setEyeColor(item.data['color'] as String);
        break;
      case ShopItemType.decoration:
        final decoration = TankDecoration(
          id: item.id,
          type: item.data['type'] as String,
          name: item.data['name'] as String,
          x: (item.data['x'] as num).toDouble(),
          y: (item.data['y'] as num).toDouble(),
        );
        axolotlProvider.addTankDecoration(decoration);
        break;
    }

    // Başarı mesajı
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} satın alındı!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

