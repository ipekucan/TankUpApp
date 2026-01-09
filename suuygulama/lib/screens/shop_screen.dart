import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../providers/daily_hydration_provider.dart';
import '../providers/aquarium_provider.dart';
import '../providers/history_provider.dart';
import '../models/decoration_item.dart';
import '../widgets/shop/shop_item_card.dart';
import '../widgets/shop/purchase_dialog.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _selectedCategory = 'Kumlar';
  String _selectedTab = 'all'; 

  final List<String> _categories = ['Kumlar', 'Bitkiler', 'Objeler', 'Ödüller'];

  // Not: Bu listeyi const yapabilir veya dışarı taşıyabiliriz ama şimdilik burada kalsın.
  // Her build'de yeniden oluşturulmaması için getter yerine variable yapabilirsin ama
  // şimdilik performans sorunu bu değil.
  List<DecorationItem> _getShopItems() {
    return [
      // ... (Senin mevcut liste kodların aynı kalacak) ...
      // KOD TASARRUFU İÇİN LİSTEYİ BURAYA TEKRAR YAZMIYORUM, 
      // SENİN KODUNDAKİ LİSTENİN AYNISINI KULLANACAKSIN.
      DecorationItem(id: 'sand_basic', name: 'Temel Kum', imagePath: 'sand_basic', price: 5, bottom: 0.1, left: 0.5, layerOrder: 1, category: 'Zemin/Kum'),
      DecorationItem(id: 'sand_golden', name: 'Altın Kum', imagePath: 'sand_golden', price: 100, bottom: 0.1, left: 0.5, layerOrder: 1, category: 'Zemin/Kum'),
      DecorationItem(id: 'sand_white', name: 'Beyaz Kum', imagePath: 'sand_white', price: 150, bottom: 0.1, left: 0.5, layerOrder: 1, category: 'Zemin/Kum'),
      DecorationItem(id: 'plant_seaweed', name: 'Deniz Yosunu', imagePath: 'plant_seaweed', price: 80, bottom: 0.3, left: 0.2, layerOrder: 2, category: 'Arka Plan'),
      DecorationItem(id: 'plant_coral', name: 'Mercan', imagePath: 'plant_coral', price: 120, bottom: 0.3, left: 0.5, layerOrder: 2, category: 'Arka Plan'),
      DecorationItem(id: 'plant_anemone', name: 'Anemon', imagePath: 'plant_anemone', price: 150, bottom: 0.3, left: 0.8, layerOrder: 2, category: 'Arka Plan'),
      DecorationItem(id: 'decoration_starfish', name: 'Deniz Yıldızı', imagePath: 'decoration_starfish', price: 70, bottom: 0.15, left: 0.15, layerOrder: 3, category: 'Süs'),
      DecorationItem(id: 'decoration_shell', name: 'Deniz Kabuğu', imagePath: 'decoration_shell', price: 60, bottom: 0.15, left: 0.85, layerOrder: 3, category: 'Süs'),
      DecorationItem(id: 'decoration_bubbles', name: 'Hava Kabarcıkları', imagePath: 'decoration_bubbles', price: 90, bottom: 0.5, left: 0.5, layerOrder: 3, category: 'Süs'),
      DecorationItem(id: 'decoration_treasure', name: 'Hazine Kutusu', imagePath: 'decoration_treasure', price: 200, bottom: 0.2, left: 0.5, layerOrder: 3, category: 'Süs', requiredStreak: 7),
      DecorationItem(id: 'reward_coral_castle', name: 'Mercan Kalesi', imagePath: 'reward_coral_castle', price: 300, bottom: 0.35, left: 0.5, layerOrder: 3, category: 'Ödül', requiredStreak: 7),
      DecorationItem(id: 'reward_legendary_pearl', name: 'Efsanevi İnci', imagePath: 'reward_legendary_pearl', price: 500, bottom: 0.4, left: 0.7, layerOrder: 3, category: 'Ödül', requiredStreak: 14),
      DecorationItem(id: 'reward_poseidon_statue', name: 'Poseidon Heykeli', imagePath: 'reward_poseidon_statue', price: 1000, bottom: 0.45, left: 0.5, layerOrder: 3, category: 'Ödül', requiredStreak: 30),
    ];
  }

  // Bu fonksiyon artık Provider'a bağımlı DEĞİL. Sadece listeyi ve provider'ı parametre alır.
  // Bu sayede "Context" karmaşası yaşanmaz.
  List<DecorationItem> _filterItems(List<DecorationItem> allItems, AquariumProvider aquariumProvider) {
    List<DecorationItem> items;
    
    // 1. Kategori Filtresi
    if (_selectedCategory == 'Ödüller') {
      items = allItems.where((item) => 
        item.requiredStreak != null && item.requiredStreak! > 0
      ).toList();
    } else {
      final categoryMap = {
        'Kumlar': 'Zemin/Kum',
        'Bitkiler': 'Arka Plan',
        'Objeler': 'Süs',
      };
      final targetCategory = categoryMap[_selectedCategory] ?? '';
      
      items = allItems.where((item) => 
        item.category == targetCategory && item.requiredStreak == null
      ).toList();
    }
    
    // 2. Tab (Sahip Olunanlar) Filtresi
    if (_selectedTab == 'owned') {
      items = items.where((item) => aquariumProvider.isDecorationOwned(item.id)).toList();
    }
    
    return items;
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold'ın body'sinde Consumer3 KULLANMIYORUZ.
    // Böylece statik kısımlar (Arka plan, Menü, Başlık) gereksiz yere çizilmez.
    return Scaffold(
      backgroundColor: AppColors.backgroundSubtle,
      body: SafeArea(
        child: Column(
          children: [
            // Üst başlık (Sabit)
            _buildTopHeaderRow(context),
            
            const SizedBox(height: 16),
            
            // Ana içerik
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 16),
                  
                  // Content Area
                  Expanded(
                    child: Column(
                      children: [
                        // Başlık (Sabit)
                        const Text(
                          'Mağaza',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C5282),
                            letterSpacing: 2.0,
                            fontFamily: 'Arial Rounded MT Bold',
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Coin ve Streak (Dinamik - Sadece burası dinler)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Sadece Coin değişince burası çizilir
                            Consumer<DailyHydrationProvider>(
                              builder: (context, provider, child) => _buildCoinButton(provider),
                            ),
                            const SizedBox(width: 12),
                            // Sadece Streak değişince burası çizilir
                            Consumer2<HistoryProvider, DailyHydrationProvider>(
                              builder: (context, history, hydration, child) {
                                final streak = history.calculateLiveStreak(
                                  hydration.consumedAmount,
                                  hydration.dailyGoal,
                                );
                                return _buildStreakButton(streak);
                              },
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Layout: Sidebar + Grid
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sol Menü (Sabit - Provider dinlemez)
                              _buildSidebarMenu(),
                              
                              const SizedBox(width: 12),
                              
                              // Ürün Listesi (Dinamik - AquariumProvider dinler)
                              Expanded(
                                child: Consumer2<AquariumProvider, DailyHydrationProvider>(
                                  builder: (context, aquariumProvider, dailyHydrationProvider, child) {
                                    // Listeyi burada hesaplıyoruz
                                    final allItems = _getShopItems();
                                    final filteredItems = _filterItems(allItems, aquariumProvider);
                                    
                                    // Streak'i tekrar alıyoruz (veya yukarıdan geçirebiliriz ama burada hesaplamak güvenli)
                                    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
                                    final currentStreak = historyProvider.calculateLiveStreak(
                                      dailyHydrationProvider.consumedAmount,
                                      dailyHydrationProvider.dailyGoal,
                                    );

                                    return _buildContentArea(
                                      filteredItems,
                                      dailyHydrationProvider,
                                      aquariumProvider,
                                      currentStreak,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET METODLARI (Aynı kalabilir, sadece ufak düzenlemeler) ---

  Widget _buildTopHeaderRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, size: 28),
            onPressed: () => Navigator.pop(context),
            color: const Color(0xFF2C5282),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              icon: Icons.home_outlined,
              isSelected: _selectedTab == 'all',
              onTap: () => setState(() => _selectedTab = 'all'),
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.2)),
          Expanded(
            child: _buildTabButton(
              icon: Icons.check,
              isSelected: _selectedTab == 'owned',
              onTap: () => setState(() => _selectedTab = 'owned'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondaryAqua.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 28,
          color: isSelected ? AppColors.secondaryAqua : const Color(0xFF4A5568),
        ),
      ),
    );
  }

  Widget _buildCoinButton(DailyHydrationProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.goldCoin.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.goldCoin.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on, size: 20, color: AppColors.goldCoin),
          const SizedBox(width: 6),
          Text(
            '${provider.tankCoins}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.goldCoin),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakButton(int streak) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondaryAqua.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondaryAqua.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 20, color: AppColors.secondaryAqua),
          const SizedBox(width: 6),
          Text(
            'Günlük Seri: $streak',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.secondaryAqua),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarMenu() {
    return SizedBox(
      width: 60,
      child: Column(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          return _buildCategoryButton(category, isSelected);
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryButton(String category, bool isSelected) {
    final iconMap = {
      'Kumlar': Icons.landscape,
      'Bitkiler': Icons.water,
      'Objeler': Icons.star,
      'Ödüller': Icons.emoji_events,
    };

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        width: 50,
        height: 50,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondaryAqua.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? AppColors.secondaryAqua : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.secondaryAqua.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
        ),
        child: Center(
          child: Icon(
            iconMap[category] ?? Icons.auto_awesome,
            size: 26,
            color: isSelected ? AppColors.secondaryAqua : const Color(0xFF4A5568),
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea(
    List<DecorationItem> items,
    DailyHydrationProvider dailyHydrationProvider,
    AquariumProvider aquariumProvider,
    int currentStreak,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.tankBorder.withValues(alpha: 0.3), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildTabButtons(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: items.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      addAutomaticKeepAlives: false, // Performans için önemli
                      addRepaintBoundaries: true, // Performans için önemli
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isOwned = aquariumProvider.isDecorationOwned(item.id);
                        final isActive = aquariumProvider.isDecorationActive(item.id);
                        final canAfford = dailyHydrationProvider.tankCoins >= item.price;

                        return ShopItemCard(
                          item: item,
                          currentStreak: currentStreak,
                          isOwned: isOwned,
                          isActive: isActive,
                          canAfford: canAfford,
                          categoryColor: _getCategoryColor(item.category),
                          categoryIcon: _getCategoryIcon(item.category),
                          onTap: _getItemTapHandler(
                            item, isOwned, isActive, canAfford, dailyHydrationProvider, aquariumProvider,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'Bu kategoride ürün yok',
            style: TextStyle(fontSize: 16, color: Colors.grey.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  VoidCallback? _getItemTapHandler(
    DecorationItem item,
    bool isOwned,
    bool isActive,
    bool canAfford,
    DailyHydrationProvider dailyHydrationProvider,
    AquariumProvider aquariumProvider,
  ) {
    return () {
      _showPurchaseDialog(
        context,
        item,
        dailyHydrationProvider,
        aquariumProvider,
        isOwned: isOwned,
        isActive: isActive,
        canAfford: canAfford,
        itemIcon: _getCategoryIcon(item.category),
        itemIconColor: _getCategoryColor(item.category),
      );
    };
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Zemin/Kum': return const Color(0xFFD4A574);
      case 'Arka Plan': return const Color(0xFF6B9BD1);
      case 'Süs': return const Color(0xFFFF6B9D);
      case 'Ödül': return AppColors.goldCoin;
      default: return AppColors.softPinkButton;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Zemin/Kum': return Icons.landscape;
      case 'Arka Plan': return Icons.water;
      case 'Süs': return Icons.star;
      case 'Ödül': return Icons.emoji_events;
      default: return Icons.auto_awesome;
    }
  }

  void _showPurchaseDialog(
    BuildContext context,
    DecorationItem item,
    DailyHydrationProvider dailyHydrationProvider,
    AquariumProvider aquariumProvider, {
    required bool isOwned,
    required bool isActive,
    required bool canAfford,
    IconData? itemIcon,
    Color? itemIconColor,
  }) {
    showDialog(
      context: context,
      builder: (context) => PurchaseDialog(
        item: item,
        itemIcon: itemIcon,
        itemIconColor: itemIconColor,
        onPurchase: () async {
          if (isOwned) {
            if (isActive) {
              await aquariumProvider.removeActiveDecoration(item.category);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item.name} kaldırıldı!'), backgroundColor: Colors.orange, duration: const Duration(seconds: 2)),
              );
            } else {
              await aquariumProvider.setActiveDecoration(item.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item.name} aktif edildi!'), backgroundColor: Colors.green, duration: const Duration(seconds: 2)),
              );
            }
          } else {
            await _purchaseItem(context, item, dailyHydrationProvider, aquariumProvider);
          }
        },
        onWatchAd: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reklam izleme özelliği yakında eklenecek!'), backgroundColor: Colors.orange, duration: Duration(seconds: 2)),
          );
        },
      ),
    );
  }

  Future<void> _purchaseItem(
    BuildContext context,
    DecorationItem item,
    DailyHydrationProvider dailyHydrationProvider,
    AquariumProvider aquariumProvider,
  ) async {
    if (!(await dailyHydrationProvider.spendCoins(item.price))) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeterli TankCoin\'iniz yok!'), backgroundColor: Colors.red),
      );
      return;
    }

    final success = await aquariumProvider.purchaseDecoration(item);
    if (success) {
      await aquariumProvider.setActiveDecoration(item.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} satın alındı ve aktif edildi!'), backgroundColor: Colors.green, duration: const Duration(seconds: 2)),
      );
    }
  }
}