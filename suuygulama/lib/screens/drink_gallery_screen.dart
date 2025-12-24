import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../models/drink_model.dart';
import '../providers/water_provider.dart';
import '../providers/user_provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/drink_provider.dart';

class DrinkGalleryScreen extends StatefulWidget {
  const DrinkGalleryScreen({super.key});

  @override
  State<DrinkGalleryScreen> createState() => _DrinkGalleryScreenState();
}

class _DrinkGalleryScreenState extends State<DrinkGalleryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Drink> _filteredDrinks = [];

  @override
  void initState() {
    super.initState();
    final drinkProvider = Provider.of<DrinkProvider>(context, listen: false);
    _filteredDrinks = drinkProvider.allDrinks;
    _searchController.addListener(_filterDrinks);
  }

  void _filterDrinks() {
    final drinkProvider = Provider.of<DrinkProvider>(context, listen: false);
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredDrinks = drinkProvider.allDrinks;
      } else {
        _filteredDrinks = drinkProvider.allDrinks
            .where((drink) => drink.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterDrinks);
    _searchController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<DrinkProvider>(
      builder: (context, drinkProvider, child) {
        // DrinkProvider'dan güncel içecekleri al
        if (_filteredDrinks.isEmpty || _searchController.text.isEmpty) {
          _filteredDrinks = drinkProvider.allDrinks;
        }
        
        return Scaffold(
          backgroundColor: AppColors.verySoftBlue,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF4A5568)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'İçecek Galerisi',
              style: TextStyle(
                color: Color(0xFF4A5568),
                fontWeight: FontWeight.w300,
                letterSpacing: 1.2,
              ),
            ),
          ),
          body: Column(
            children: [
              // Arama Çubuğu
              Padding(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'İçecek ara...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF4A5568)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              
              // İçecek Grid
              Expanded(
                child: _filteredDrinks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'İçecek bulunamadı',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _filteredDrinks.length,
                        itemBuilder: (context, index) {
                          final drink = _filteredDrinks[index];
                          return _buildDrinkCard(drink);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrinkCard(Drink drink) {
    return GestureDetector(
      onTap: () => _showDrinkDetailDialog(drink),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: _getDrinkColor(drink.id).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getDrinkIcon(drink.id),
                color: _getDrinkColor(drink.id),
                size: 36,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              drink.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A5568),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '%${(drink.hydrationFactor * 100).toStringAsFixed(0)} hidrasyon',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDrinkDetailDialog(Drink drink) {
    if (!mounted) return;
    final TextEditingController customAmountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // İçecek Başlığı
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _getDrinkColor(drink.id).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getDrinkIcon(drink.id),
                          color: _getDrinkColor(drink.id),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              drink.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4A5568),
                              ),
                            ),
                            Text(
                              'Vücuda sıvı sağlama oranı: %${(drink.hydrationFactor * 100).toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Sağ Üst İkonlar: Favori (Kalp) ve Hızlı Erişim (Artı)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Favori Butonu (Kalp)
                          Consumer<DrinkProvider>(
                            builder: (context, drinkProvider, child) {
                              final isFavorite = drinkProvider.isFavorite(drink.id);
                              return IconButton(
                                icon: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : Colors.grey[600],
                                  size: 28,
                                ),
                                onPressed: () async {
                                  if (isFavorite) {
                                    // Favoriden çıkar
                                    await drinkProvider.removeFavorite(drink.id);
                                  } else {
                                    // Favoriye ekle - varsayılan miktar ile
                                    await drinkProvider.addFavorite(drink.id, amount: 200.0);
                                  }
                                  setDialogState(() {});
                                },
                                tooltip: isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
                              );
                            },
                          ),
                          // Hızlı Erişim Butonu (Artı) - Pembe
                          Consumer<DrinkProvider>(
                            builder: (context, drinkProvider, child) {
                              final isQuickAccess = drinkProvider.isQuickAccess(drink.id);
                              return IconButton(
                                icon: Icon(
                                  isQuickAccess ? Icons.add_circle : Icons.add_circle_outline,
                                  color: isQuickAccess ? AppColors.softPinkButton : AppColors.softPinkButton,
                                  size: 28,
                                ),
                                onPressed: () async {
                                  if (isQuickAccess) {
                                    // Hızlı erişimden çıkar
                                    await drinkProvider.removeQuickAccess(drink.id);
                                    setDialogState(() {});
                                  } else {
                                    // Hızlı erişime ekle - varsayılan miktar ile
                                    await drinkProvider.addQuickAccess(drink.id, amount: 200.0);
                                    // Modalı kapat ve ana ekrana geri dön
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                      // Şık SnackBar bildirimi göster
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  'İçecek hızlı erişim için ana sayfaya eklendi!',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: AppColors.softPinkButton,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          margin: const EdgeInsets.all(16),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                },
                                tooltip: isQuickAccess ? 'Hızlı erişimden çıkar' : 'Hızlı erişime ekle',
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Hızlı Seçim Butonları
                  const Text(
                    'Hızlı Seçim',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildQuickSelectButton(
                        '200ml',
                        200.0,
                        drink,
                        customAmountController,
                        setDialogState,
                      ),
                      _buildQuickSelectButton(
                        '330ml',
                        330.0,
                        drink,
                        customAmountController,
                        setDialogState,
                      ),
                      _buildQuickSelectButton(
                        '500ml',
                        500.0,
                        drink,
                        customAmountController,
                        setDialogState,
                      ),
                      _buildQuickSelectButton(
                        '750ml',
                        750.0,
                        drink,
                        customAmountController,
                        setDialogState,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Özel Miktar Girişi
                  const Text(
                    'Özel Miktar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: customAmountController,
                    decoration: InputDecoration(
                      hintText: 'Miktar (ml)',
                      suffixText: 'ml',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  
                  // Onay Butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final amount = double.tryParse(customAmountController.text);
                        if (amount != null && amount > 0) {
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          await _drinkWithAmount(drink, amount);
                        } else {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Lütfen geçerli bir miktar girin'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.softPinkButton,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'İç',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSelectButton(
    String label,
    double amount,
    Drink drink,
    TextEditingController controller,
    StateSetter setDialogState,
  ) {
    return GestureDetector(
      onTap: () async {
        if (!context.mounted) return;
        Navigator.pop(context);
        await _drinkWithAmount(drink, amount);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.softPinkButton.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.softPinkButton.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.softPinkButton,
          ),
        ),
      ),
    );
  }

  Future<void> _drinkWithAmount(Drink drink, double amount) async {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    
    final waterProvider = Provider.of<WaterProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final achievementProvider = Provider.of<AchievementProvider>(context, listen: false);
    
    // WaterProvider'ın drink metodunu kullan (bilimsel hesaplama içinde yapılıyor)
    final result = await waterProvider.drink(drink, amount);
    
    if (!context.mounted) return;
    
    if (result.success) {
      // Hidrasyon faktörüne göre efektif miktarı ekle
      final effectiveAmount = amount * drink.hydrationFactor;
      await userProvider.addToTotalWater(effectiveAmount);
      
      if (!context.mounted) return;
      
      // Başarı kontrolü
      if (result.isFirstDrink) {
        final coins = await achievementProvider.checkFirstStep();
        if (coins > 0) {
          await waterProvider.addCoins(coins);
          await userProvider.addAchievement('first_step');
        }
      }
      
      if (!context.mounted) return;
      
      final wasGoalReachedBefore = achievementProvider.isAchievementUnlocked('daily_goal');
      if (waterProvider.hasReachedDailyGoal && !wasGoalReachedBefore) {
        final coins = await achievementProvider.checkDailyGoal();
        if (coins > 0) {
          await waterProvider.addCoins(coins);
          await userProvider.addAchievement('daily_goal');
          await userProvider.updateConsecutiveDays(true);
        }
      } else if (waterProvider.hasReachedDailyGoal) {
        await userProvider.updateConsecutiveDays(true);
      }
      
      if (!context.mounted) return;
      
      final totalWater = userProvider.userData.totalWaterConsumed;
      final wasWaterMasterUnlocked = achievementProvider.isAchievementUnlocked('water_master');
      final waterMasterCoins = await achievementProvider.checkWaterMaster(totalWater);
      if (waterMasterCoins > 0 && !wasWaterMasterUnlocked) {
        await waterProvider.addCoins(waterMasterCoins);
        await userProvider.addAchievement('water_master');
      }
      
      if (!context.mounted) return;
      
      final consecutiveDays = userProvider.consecutiveDays;
      final wasStreak3Unlocked = achievementProvider.isAchievementUnlocked('streak_3');
      final streak3Coins = await achievementProvider.checkStreak3(consecutiveDays);
      if (streak3Coins > 0 && !wasStreak3Unlocked) {
        await waterProvider.addCoins(streak3Coins);
        await userProvider.addAchievement('streak_3');
      }
      
      if (!context.mounted) return;
      
      final wasStreak7Unlocked = achievementProvider.isAchievementUnlocked('streak_7');
      final streak7Coins = await achievementProvider.checkStreak7(consecutiveDays);
      if (streak7Coins > 0 && !wasStreak7Unlocked) {
        await waterProvider.addCoins(streak7Coins);
        await userProvider.addAchievement('streak_7');
      }
      
      if (!context.mounted) return;
      
      // Şanslı Yudum ve diğer bonus bildirimleri
      if (result.isLuckyDrink) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Şanslı Yudum! +10 Coin kazandın! 🍀',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.amber.shade700,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.isDailyGoalBonus
                ? Colors.green.shade600
                : result.isEarlyBird || result.isNightOwl
                    ? Colors.orange.shade400
                    : AppColors.softPinkButton,
            duration: result.isDailyGoalBonus
                ? const Duration(seconds: 3)
                : const Duration(seconds: 2),
          ),
        );
      }
      
      if (result.isEarlyBird && !result.isLuckyDrink) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Erken Kuş Bonusu! +5 Coin 🌅'),
                backgroundColor: Colors.orange.shade400,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
      }
      
      if (result.isNightOwl && !result.isLuckyDrink) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Gece Kuşu Bonusu! +5 Coin 🌙'),
                backgroundColor: Colors.indigo.shade400,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
      }
      
      if (result.isDailyGoalBonus && !result.isLuckyDrink) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Günlük Hedefe Ulaşıldı! +15 Coin 🎯'),
                backgroundColor: Colors.green.shade600,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
      }
    } else {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Color _getDrinkColor(String drinkId) {
    switch (drinkId) {
      // Temel İçecekler
      case 'water':
        return Colors.blue;
      case 'mineral_water':
        return const Color(0xFF4A9ED8);
      
      // Sıcak İçecekler
      case 'coffee':
        return Colors.brown;
      case 'tea':
        return Colors.green;
      case 'herbal_tea':
        return const Color(0xFF6B8E23);
      case 'green_tea':
        return const Color(0xFF228B22);
      
      // Soğuk İçecekler
      case 'cold_tea':
        return const Color(0xFF8B7355);
      case 'lemonade':
        return const Color(0xFFFFD700);
      case 'iced_coffee':
        return const Color(0xFF8B4513);
      
      // Süt Ürünleri
      case 'ayran':
        return const Color(0xFFF5F5DC);
      case 'kefir':
        return const Color(0xFFFFE4B5);
      case 'milk':
        return Colors.white70;
      
      // Meyve İçecekleri
      case 'juice':
        return Colors.orange;
      case 'smoothie':
        return const Color(0xFFFF6347);
      case 'fresh_juice':
        return const Color(0xFFFF8C00);
      
      // Spor ve Sağlık
      case 'sports':
        return Colors.cyan;
      case 'protein_shake':
        return const Color(0xFF9370DB);
      case 'coconut_water':
        return const Color(0xFFDEB887);
      
      // Diğer
      case 'soda':
        return Colors.red;
      case 'energy_drink':
        return const Color(0xFFFF1493);
      case 'detox_water':
        return const Color(0xFF98D8C8);
      
      default:
        return AppColors.softPinkButton;
    }
  }

  IconData _getDrinkIcon(String drinkId) {
    switch (drinkId) {
      // Temel İçecekler
      case 'water':
        return Icons.water_drop;
      case 'mineral_water':
        return Icons.water;
      
      // Sıcak İçecekler
      case 'coffee':
        return Icons.local_cafe;
      case 'tea':
        return Icons.emoji_food_beverage;
      case 'herbal_tea':
        return Icons.eco;
      case 'green_tea':
        return Icons.eco;
      
      // Soğuk İçecekler
      case 'cold_tea':
        return Icons.emoji_food_beverage;
      case 'lemonade':
        return Icons.local_drink;
      case 'iced_coffee':
        return Icons.local_cafe;
      
      // Süt Ürünleri
      case 'ayran':
        return Icons.liquor;
      case 'kefir':
        return Icons.liquor;
      case 'milk':
        return Icons.local_drink;
      
      // Meyve İçecekleri
      case 'juice':
        return Icons.local_drink;
      case 'smoothie':
        return Icons.blender;
      case 'fresh_juice':
        return Icons.local_drink;
      
      // Spor ve Sağlık
      case 'sports':
        return Icons.fitness_center;
      case 'protein_shake':
        return Icons.sports_gymnastics;
      case 'coconut_water':
        return Icons.water_drop;
      
      // Diğer
      case 'soda':
        return Icons.sports_bar;
      case 'energy_drink':
        return Icons.bolt;
      case 'detox_water':
        return Icons.spa;
      
      default:
        return Icons.local_drink;
    }
  }
}

