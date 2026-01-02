import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_tooltip/super_tooltip.dart';
import '../utils/app_colors.dart';
import '../models/drink_model.dart';
import '../providers/daily_hydration_provider.dart';
import '../providers/user_provider.dart';
import '../providers/drink_provider.dart';
import '../utils/drink_helpers.dart';

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
  
  // İlk açılışta tooltip'i göster (dialog için)
  Future<void> _checkAndShowQuickAccessTooltipForDialog(SuperTooltipController controller) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenQuickAccessTooltip = prefs.getBool('has_seen_drink_detail_quick_access_tooltip') ?? false;
    
    if (!hasSeenQuickAccessTooltip && mounted) {
      // Kısa bir gecikme ile tooltip'i göster
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          await prefs.setBool('has_seen_drink_detail_quick_access_tooltip', true);
          // Tooltip'i göster
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              controller.showTooltip();
            }
          });
        }
      });
    }
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
          backgroundColor: AppColors.backgroundSubtle,
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
                color: DrinkHelpers.getColor(drink.id).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                DrinkHelpers.getIcon(drink.id),
                color: DrinkHelpers.getColor(drink.id),
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
    
    // Seçili miktar state'i (ml cinsinden) - dialog dışında tutulmalı
    double? selectedAmount;
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        // Controller'ı dialog builder içinde oluştur
        final tooltipController = SuperTooltipController();
        // İlk açılış kontrolü
        _checkAndShowQuickAccessTooltipForDialog(tooltipController);
        
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
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
                          color: DrinkHelpers.getColor(drink.id).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          DrinkHelpers.getIcon(drink.id),
                          color: DrinkHelpers.getColor(drink.id),
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
                      // Sağ Üst İkon: Hızlı Erişim (Artı) - SuperTooltip ile (Stack yapısı ile görsel bütünlük korunuyor)
                      Consumer<DrinkProvider>(
                        builder: (dialogContext, drinkProvider, child) {
                          final isQuickAccess = drinkProvider.isQuickAccess(drink.id);
                          
                          // Tıklama işlevi
                          void handleQuickAccessTap() async {
                            // Tooltip'i kapat
                            // SuperTooltip otomatik olarak kapanacak
                            if (isQuickAccess) {
                              // Hızlı erişimden çıkar
                              await drinkProvider.removeQuickAccess(drink.id);
                              setDialogState(() {});
                            } else {
                              // Hızlı erişime ekle - varsayılan miktar ile
                              await drinkProvider.addQuickAccess(drink.id, amount: 200.0);
                              // Modalı kapat ve ana ekrana geri dön
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                                // Şık SnackBar bildirimi göster
                                ScaffoldMessenger.of(dialogContext).showSnackBar(
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
                          }
                          
                          return Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              // Alt Katman: Orijinal IconButton (Görsel - Asla bozulmaz)
                              IconButton(
                                icon: Icon(
                                  isQuickAccess ? Icons.add_circle : Icons.add_circle_outline,
                                  color: AppColors.softPinkButton,
                                  size: 28,
                                ),
                                onPressed: null, // Tıklama devre dışı - üst katman işleyecek
                                tooltip: isQuickAccess ? 'Hızlı erişimden çıkar' : 'Hızlı erişime ekle',
                              ),
                              
                              // Üst Katman: Görünmez GestureDetector + SuperTooltip (Tıklama ve Tooltip için)
                              Positioned.fill(
                                child: SuperTooltip(
                                  controller: tooltipController,
                                  popupDirection: TooltipDirection.down,
                                  arrowLength: 20.0,
                                  arrowBaseWidth: 10.0,
                                  backgroundColor: Colors.blueGrey.shade900,
                                  hasShadow: true,
                                  shadowColor: Colors.black.withValues(alpha: 0.5),
                                  elevation: 8.0,
                                  content: const Text(
                                    'Bu içeceği ana ekrana kısayol olarak ekle!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  child: GestureDetector(
                                    onTap: handleQuickAccessTap,
                                    behavior: HitTestBehavior.opaque, // Tüm alanı tıklanabilir yap
                                    child: Container(
                                      color: Colors.transparent, // Tamamen şeffaf
                                      width: 48, // IconButton'ın standart boyutu
                                      height: 48,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
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
                  Consumer<UserProvider>(
                    builder: (dialogContext, userProvider, child) {
                      final isMetric = userProvider.isMetric;
                      // Miktar butonları - Küçükten büyüğe: 200ml, 250ml, 330ml, 500ml, 750ml, 1000ml
                      final quickSelectAmounts = [200.0, 250.0, 330.0, 500.0, 750.0, 1000.0];
                      
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2.1, // Genişlik/yükseklik oranı (2.5'ten 2.1'e düşürüldü - daha fazla dikey alan)
                        children: quickSelectAmounts.map((amountMl) {
                          final displayText = isMetric
                              ? '${amountMl.toStringAsFixed(0)}ml'
                              : '${(amountMl * 0.033814).toStringAsFixed(1)} oz';
                          final isSelected = selectedAmount == amountMl;
                          
                          return _buildQuickSelectButton(
                            displayText,
                            amountMl,
                            drink,
                            customAmountController,
                            setDialogState,
                            dialogContext,
                            isSelected,
                            () {
                              // Seçili miktarı güncelle (closure içinde dış değişkene erişim)
                              selectedAmount = amountMl;
                              // TextField'a yazma - kullanıcı elle girecek
                              setDialogState(() {});
                            },
                          );
                        }).toList(),
                      );
                    },
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
                  Consumer<UserProvider>(
                    builder: (dialogContext, userProvider, child) {
                      final unitLabel = userProvider.isMetric ? 'ml' : 'oz';
                      return TextField(
                        controller: customAmountController,
                        onChanged: (value) {
                          // TextField'a elle girildiğinde buton seçimini kaldır
                          if (value.isNotEmpty) {
                            selectedAmount = null;
                            setDialogState(() {});
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Miktar ($unitLabel)',
                          suffixText: unitLabel,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: !userProvider.isMetric),
                        style: const TextStyle(fontSize: 16),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Onay Butonu (İÇ)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final userProvider = Provider.of<UserProvider>(dialogContext, listen: false);
                        double? amount;
                        
                        // Önce TextField'dan değeri kontrol et
                        final inputAmount = double.tryParse(customAmountController.text);
                        if (inputAmount != null && inputAmount > 0) {
                          // Birime göre dönüştür: oz ise ml'ye çevir
                          amount = userProvider.isMetric 
                              ? inputAmount 
                              : inputAmount / 0.033814; // oz'u ml'ye çevir
                        } else if (selectedAmount != null && selectedAmount! > 0) {
                          // TextField boşsa ama buton seçiliyse, seçili miktarı kullan
                          amount = selectedAmount;
                        }
                        
                        if (amount != null && amount > 0) {
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          await _drinkWithAmount(drink, amount);
                        } else {
                          if (!dialogContext.mounted) return;
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text('Lütfen geçerli bir miktar seçin veya girin'),
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
            );
          },
        );
      },
    );
  }

  Widget _buildQuickSelectButton(
    String label,
    double amountMl, // Her zaman ml cinsinden
    Drink drink,
    TextEditingController controller,
    StateSetter setDialogState,
    BuildContext dialogContext,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // REMOVED PADDING HERE to prevent text clipping
        decoration: BoxDecoration(
          color: isSelected ? AppColors.softPinkButton : Colors.grey.shade200, // Seçili değilken açık gri
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.softPinkButton : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Center( // Center aligns the text perfectly
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700, // Seçili değilken koyu gri
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Future<void> _drinkWithAmount(Drink drink, double amount) async {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    
    final dailyHydrationProvider =
        Provider.of<DailyHydrationProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // DailyHydrationProvider'ın drink metodunu kullan (bilimsel hesaplama içinde yapılıyor)
    final result = await dailyHydrationProvider.drink(drink, amount, context: context);
    
    if (!context.mounted) return;
    
    if (result.success) {
      // Hidrasyon faktörüne göre efektif miktarı ekle
      final effectiveAmount = amount * drink.hydrationFactor;
      await userProvider.addToTotalWater(effectiveAmount);
      
      if (!context.mounted) return;
      
      if (dailyHydrationProvider.hasReachedDailyGoal) {
        await userProvider.updateConsecutiveDays(true);
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

  // Drink color and icon helpers moved to DrinkHelpers utility class
}

