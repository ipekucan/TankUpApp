import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../providers/daily_hydration_provider.dart';
import '../providers/aquarium_provider.dart';
import '../models/decoration_item.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _selectedCategory = 'Kumlar'; // Varsayılan kategori

  // Kategoriler
  final List<String> _categories = ['Kumlar', 'Bitkiler', 'Objeler'];

  // Mağaza ürünleri - Kategorize edilmiş
  List<DecorationItem> _getShopItems() {
    return [
      // Kumlar (Zemin/Kum kategorisi)
      DecorationItem(
        id: 'sand_basic',
        name: 'Temel Kum',
        imagePath: 'sand_basic',
        price: 50,
        bottom: 0.1,
        left: 0.5,
        layerOrder: 1,
        category: 'Zemin/Kum',
      ),
      DecorationItem(
        id: 'sand_golden',
        name: 'Altın Kum',
        imagePath: 'sand_golden',
        price: 100,
        bottom: 0.1,
        left: 0.5,
        layerOrder: 1,
        category: 'Zemin/Kum',
      ),
      DecorationItem(
        id: 'sand_white',
        name: 'Beyaz Kum',
        imagePath: 'sand_white',
        price: 150,
        bottom: 0.1,
        left: 0.5,
        layerOrder: 1,
        category: 'Zemin/Kum',
      ),
      
      // Bitkiler (Arka Plan kategorisi)
      DecorationItem(
        id: 'plant_seaweed',
        name: 'Deniz Yosunu',
        imagePath: 'plant_seaweed',
        price: 80,
        bottom: 0.3,
        left: 0.2,
        layerOrder: 2,
        category: 'Arka Plan',
      ),
      DecorationItem(
        id: 'plant_coral',
        name: 'Mercan',
        imagePath: 'plant_coral',
        price: 120,
        bottom: 0.3,
        left: 0.5,
        layerOrder: 2,
        category: 'Arka Plan',
      ),
      DecorationItem(
        id: 'plant_anemone',
        name: 'Anemon',
        imagePath: 'plant_anemone',
        price: 150,
        bottom: 0.3,
        left: 0.8,
        layerOrder: 2,
        category: 'Arka Plan',
      ),
      
      // Objeler (Süs kategorisi)
      DecorationItem(
        id: 'decoration_starfish',
        name: 'Deniz Yıldızı',
        imagePath: 'decoration_starfish',
        price: 70,
        bottom: 0.15,
        left: 0.15,
        layerOrder: 3,
        category: 'Süs',
      ),
      DecorationItem(
        id: 'decoration_shell',
        name: 'Deniz Kabuğu',
        imagePath: 'decoration_shell',
        price: 60,
        bottom: 0.15,
        left: 0.85,
        layerOrder: 3,
        category: 'Süs',
      ),
      DecorationItem(
        id: 'decoration_bubbles',
        name: 'Hava Kabarcıkları',
        imagePath: 'decoration_bubbles',
        price: 90,
        bottom: 0.5,
        left: 0.5,
        layerOrder: 3,
        category: 'Süs',
      ),
      DecorationItem(
        id: 'decoration_treasure',
        name: 'Hazine Kutusu',
        imagePath: 'decoration_treasure',
        price: 200,
        bottom: 0.2,
        left: 0.5,
        layerOrder: 3,
        category: 'Süs',
      ),
    ];
  }

  // Seçili kategoriye göre ürünleri filtrele
  List<DecorationItem> _getFilteredItems() {
    final allItems = _getShopItems();
    final categoryMap = {
      'Kumlar': 'Zemin/Kum',
      'Bitkiler': 'Arka Plan',
      'Objeler': 'Süs',
    };
    final targetCategory = categoryMap[_selectedCategory] ?? '';
    return allItems.where((item) => item.category == targetCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSubtle,
      appBar: AppBar(
        title: const Text('Mağaza'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer2<DailyHydrationProvider, AquariumProvider>(
        builder: (context, dailyHydrationProvider, aquariumProvider, child) {
          final filteredItems = _getFilteredItems();
          
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
                      '${dailyHydrationProvider.tankCoins} TankCoin',
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
              
              // Kategori seçimi
              Container(
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.softPinkButton
                              : Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.softPinkButton
                                : Colors.grey.withValues(alpha: 0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF4A5568),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Ürün listesi
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final isOwned = aquariumProvider.isDecorationOwned(item.id);
                    final isActive = aquariumProvider.isDecorationActive(item.id);
                    
                    return _buildShopCard(
                      context,
                      item,
                      dailyHydrationProvider,
                      aquariumProvider,
                      isOwned,
                      isActive,
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

  // Mağaza kartı widget'ı
  Widget _buildShopCard(
    BuildContext context,
    DecorationItem item,
    DailyHydrationProvider dailyHydrationProvider,
    AquariumProvider aquariumProvider,
    bool isOwned,
    bool isActive,
  ) {
    final canAfford = dailyHydrationProvider.tankCoins >= item.price;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isOwned
            ? () {
                // Aktif/pasif yap
                if (isActive) {
                  aquariumProvider.removeActiveDecoration(item.category);
                } else {
                  aquariumProvider.setActiveDecoration(item.id);
                }
              }
            : canAfford
                ? () async {
                    await _purchaseItem(context, item, dailyHydrationProvider, aquariumProvider);
                  }
                : null,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isActive
                  ? AppColors.softPinkButton
                  : isOwned
                      ? AppColors.softPinkButton.withValues(alpha: 0.3)
                      : canAfford
                          ? AppColors.softPinkButton.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.1),
              width: isActive ? 3 : 1.5,
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
                // Ürün ikonu
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(item.category).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    _getCategoryIcon(item.category),
                    size: 36,
                    color: _getCategoryColor(item.category),
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
                                color: isActive
                                    ? AppColors.softPinkButton
                                    : isOwned
                                        ? Colors.grey[600]
                                        : const Color(0xFF4A5568),
                              ),
                            ),
                          ),
                          if (isActive)
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
                                'Aktif',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4A5568),
                                ),
                              ),
                            )
                          else if (isOwned)
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
                        'Kategori: ${item.category}',
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
                
                // Buton
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
                  )
                else
                  Container(
                    width: 90,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.grey[300]
                          : AppColors.softPinkButton.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        isActive ? 'Kaldır' : 'Aktif Et',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? Colors.grey[600]
                              : AppColors.softPinkButton,
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

  // Kategoriye göre renk
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Zemin/Kum':
        return const Color(0xFFD4A574);
      case 'Arka Plan':
        return const Color(0xFF6B9BD1);
      case 'Süs':
        return const Color(0xFFFF6B9D);
      default:
        return AppColors.softPinkButton;
    }
  }

  // Kategoriye göre icon
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Zemin/Kum':
        return Icons.landscape;
      case 'Arka Plan':
        return Icons.water;
      case 'Süs':
        return Icons.star;
      default:
        return Icons.auto_awesome;
    }
  }

  // Ürün satın alma
  Future<void> _purchaseItem(
    BuildContext context,
    DecorationItem item,
    DailyHydrationProvider dailyHydrationProvider,
    AquariumProvider aquariumProvider,
  ) async {
    // Coin kontrolü ve düşürme
    if (!(await dailyHydrationProvider.spendCoins(item.price))) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yeterli TankCoin\'iniz yok!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Dekorasyonu satın al
    final success = await aquariumProvider.purchaseDecoration(item);
    if (success) {
      // Otomatik olarak aktif yap
      await aquariumProvider.setActiveDecoration(item.id);
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} satın alındı ve aktif edildi!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
