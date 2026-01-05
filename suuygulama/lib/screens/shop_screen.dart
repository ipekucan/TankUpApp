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
  String _selectedCategory = 'Kumlar'; // Varsayılan kategori
  String _selectedTab = 'all'; // 'all' veya 'owned'

  // Kategoriler - Added "Ödüller" (Rewards) for streak-based items
  final List<String> _categories = ['Kumlar', 'Bitkiler', 'Objeler', 'Ödüller'];

  // Mağaza ürünleri - Kategorize edilmiş
  List<DecorationItem> _getShopItems() {
    return [
      // Kumlar (Zemin/Kum kategorisi)
      DecorationItem(
        id: 'sand_basic',
        name: 'Temel Kum',
        imagePath: 'sand_basic',
        price: 5, // Güncellendi: 50 → 5
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
        requiredStreak: 7, // Requires 7-day streak to unlock
      ),
      
      // Ödüller (Rewards) - Streak-based exclusive items
      DecorationItem(
        id: 'reward_coral_castle',
        name: 'Mercan Kalesi',
        imagePath: 'reward_coral_castle',
        price: 300,
        bottom: 0.35,
        left: 0.5,
        layerOrder: 3,
        category: 'Ödül',
        requiredStreak: 7, // 7-day streak
      ),
      DecorationItem(
        id: 'reward_legendary_pearl',
        name: 'Efsanevi İnci',
        imagePath: 'reward_legendary_pearl',
        price: 500,
        bottom: 0.4,
        left: 0.7,
        layerOrder: 3,
        category: 'Ödül',
        requiredStreak: 14, // 14-day streak
      ),
      DecorationItem(
        id: 'reward_poseidon_statue',
        name: 'Poseidon Heykeli',
        imagePath: 'reward_poseidon_statue',
        price: 1000,
        bottom: 0.45,
        left: 0.5,
        layerOrder: 3,
        category: 'Ödül',
        requiredStreak: 30, // 30-day streak
      ),
    ];
  }

  // Seçili kategoriye göre ürünleri filtrele - FIXED LOGIC + TAB FILTER
  List<DecorationItem> _getFilteredItems() {
    final allItems = _getShopItems();
    
    // "Ödüller" (Rewards): Show ALL items with requiredStreak > 0
    // Aggregates streak-based items regardless of category
    List<DecorationItem> items;
    if (_selectedCategory == 'Ödüller') {
      items = allItems.where((item) => 
        item.requiredStreak != null && item.requiredStreak! > 0
      ).toList();
    } else {
      // Regular categories: Filter by category, EXCLUDE streak items to avoid duplicates
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
    
    // Tab filtreleme: 'owned' seçiliyse sadece sahip olunanlr
    if (_selectedTab == 'owned') {
      final aquariumProvider = Provider.of<AquariumProvider>(context, listen: false);
      items = items.where((item) => aquariumProvider.isDecorationOwned(item.id)).toList();
    }
    
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSubtle,
      body: SafeArea(
        child: Consumer3<DailyHydrationProvider, AquariumProvider, HistoryProvider>(
          builder: (context, dailyHydrationProvider, aquariumProvider, historyProvider, child) {
            final filteredItems = _getFilteredItems();
            
            // Use live streak calculation for consistent behavior
            final currentStreak = historyProvider.calculateLiveStreak(
              dailyHydrationProvider.consumedAmount,
              dailyHydrationProvider.dailyGoal,
            );
            
            return Column(
              children: [
                // Üst başlık satırı: X butonu (sol)
                _buildTopHeaderRow(context),
                
                const SizedBox(height: 16),
                
                // Ana içerik: Sidebar + Content
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Spacer (Mağaza yazısı için)
                      const SizedBox(width: 16),
                      
                      // RIGHT CONTENT AREA (ortalanmış)
                      Expanded(
                        child: Column(
                          children: [
                            // Mağaza yazısı (büyük, kalın, yuvarlak)
                            const Text(
                              'Mağaza',
                              style: TextStyle(
                                fontSize: 40, // Büyütüldü: 36 → 40
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C5282),
                                letterSpacing: 2.0, // Harf aralığı artırıldı: 0.5 → 2.0
                                fontFamily: 'Arial Rounded MT Bold',
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Coin + Streak butonları (dikdörtgen genişliğine yayılmış)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8), // Kenarlardan biraz içeri
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildCoinButton(dailyHydrationProvider),
                                  _buildStreakButton(currentStreak),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Ana layout: Sidebar + Grid
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // LEFT SIDEBAR MENU (dikdörtgen başlangıcıyla aynı hizada)
                                  _buildSidebarMenu(),
                                  
                                  const SizedBox(width: 12),
                                  
                                  // Ürün grid alanı (Tab içinde)
                                  Expanded(
                                    child: _buildContentArea(
                                      filteredItems,
                                      dailyHydrationProvider,
                                      aquariumProvider,
                                      currentStreak,
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
            );
          },
        ),
      ),
    );
  }

  /// Üst başlık satırı: X butonu (sol)
  Widget _buildTopHeaderRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // X butonu (kapat)
          IconButton(
            icon: const Icon(Icons.close, size: 28),
            onPressed: () => Navigator.pop(context),
            color: const Color(0xFF2C5282),
          ),
        ],
      ),
    );
  }

  /// Tab butonları (Ev: Tümü, Tik: Sahip Olunanlar)
  Widget _buildTabButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Ev ikonu (Tümü) - Expanded ile genişlet
          Expanded(
            child: _buildTabButton(
              icon: Icons.home_outlined,
              isSelected: _selectedTab == 'all',
              onTap: () => setState(() => _selectedTab = 'all'),
            ),
          ),
          
          Container(
            width: 1,
            height: 40, // Yükseklik artırıldı: 30 → 40
            color: Colors.grey.withValues(alpha: 0.2),
          ),
          
          // Tik ikonu (Sahip Olunanlar) - Expanded ile genişlet
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

  /// Tek tab butonu
  Widget _buildTabButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, // Tam genişlik
        padding: const EdgeInsets.symmetric(vertical: 12), // Dikey padding artırıldı: 10 → 12
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondaryAqua.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 28, // Büyütüldü: 26 → 28
          color: isSelected
              ? AppColors.secondaryAqua
              : const Color(0xFF4A5568),
        ),
      ),
    );
  }

  /// Coin butonu
  Widget _buildCoinButton(DailyHydrationProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.goldCoin.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.goldCoin.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on,
            size: 20,
            color: AppColors.goldCoin,
          ),
          const SizedBox(width: 6),
          Text(
            '${provider.tankCoins}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.goldCoin,
            ),
          ),
        ],
      ),
    );
  }

  /// Streak butonu (kronometre + günlük seri)
  Widget _buildStreakButton(int streak) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondaryAqua.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondaryAqua.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 20,
            color: AppColors.secondaryAqua,
          ),
          const SizedBox(width: 6),
          Text(
            'Günlük Seri: $streak',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryAqua,
            ),
          ),
        ],
      ),
    );
  }

  /// Left sidebar menu - Sadece ikonlar (küçük)
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

  /// Category button widget - Sadece ikon (yazı yok)
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
        width: 50, // Küçük kare
        height: 50,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondaryAqua.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? AppColors.secondaryAqua
                : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.secondaryAqua.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Icon(
            iconMap[category] ?? Icons.auto_awesome,
            size: 26,
            color: isSelected
                ? AppColors.secondaryAqua
                : const Color(0xFF4A5568),
          ),
        ),
      ),
    );
  }

  /// Right content area - Grid view with border + Tab at top
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
        border: Border.all(
          color: AppColors.tankBorder.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tab butonları (dikdörtgen içinde, en üstte)
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildTabButtons(),
          ),
          
          // Grid alanı
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
                            item,
                            isOwned,
                            isActive,
                            canAfford,
                            dailyHydrationProvider,
                            aquariumProvider,
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

  /// Empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Bu kategoride ürün yok',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Mağaza kartı widget'ı - REPLACED with modular ShopItemCard
  // This method now returns the tap handler callback
  VoidCallback? _getItemTapHandler(
    DecorationItem item,
    bool isOwned,
    bool isActive,
    bool canAfford,
    DailyHydrationProvider dailyHydrationProvider,
    AquariumProvider aquariumProvider,
  ) {
    // TÜM ÜRÜNLER İÇİN DIALOG AÇ
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

  // Kategoriye göre renk
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Zemin/Kum':
        return const Color(0xFFD4A574);
      case 'Arka Plan':
        return const Color(0xFF6B9BD1);
      case 'Süs':
        return const Color(0xFFFF6B9D);
      case 'Ödül':
        return AppColors.goldCoin; // Golden color for rewards
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
      case 'Ödül':
        return Icons.emoji_events; // Trophy icon for rewards
      default:
        return Icons.auto_awesome;
    }
  }

  // Satın alma dialog'unu göster - TÜM ÜRÜNLER İÇİN
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
          // Eğer zaten sahipse, aktifleştir/kaldır
          if (isOwned) {
            if (isActive) {
              await aquariumProvider.removeActiveDecoration(item.category);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.name} kaldırıldı!'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else {
              await aquariumProvider.setActiveDecoration(item.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.name} aktif edildi!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } else {
            // Satın alma
            await _purchaseItem(context, item, dailyHydrationProvider, aquariumProvider);
          }
        },
        onWatchAd: () {
          // Reklam izleme özelliği - Şimdilik placeholder
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reklam izleme özelliği yakında eklenecek!'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
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
