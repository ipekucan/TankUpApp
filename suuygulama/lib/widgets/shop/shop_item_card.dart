import 'package:flutter/material.dart';
import '../../models/decoration_item.dart';
import '../../utils/app_colors.dart';

/// Shop Item Card Widget - Modular component for displaying shop items
///
/// Handles both locked (streak-based) and unlocked states with premium UI.
/// Features:
/// - Frosted glass blur effect for locked items
/// - Progress indicator for streak requirements
/// - Clean visual hierarchy
/// - Aquarium-themed design
class ShopItemCard extends StatelessWidget {
  final DecorationItem item;
  final int currentStreak;
  final bool isOwned;
  final bool isActive;
  final bool canAfford;
  final VoidCallback? onTap;
  final Color categoryColor;
  final IconData categoryIcon;

  const ShopItemCard({
    super.key,
    required this.item,
    required this.currentStreak,
    required this.isOwned,
    required this.isActive,
    required this.canAfford,
    required this.onTap,
    required this.categoryColor,
    required this.categoryIcon,
  });

  bool get _isLockedByStreak =>
      item.requiredStreak != null && currentStreak < item.requiredStreak!;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap, // TÜM ÜRÜNLER TİKLANABİLİR
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: _isLockedByStreak
                  ? Colors.grey.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isLockedByStreak
                    ? Colors.grey.withValues(alpha: 0.3)
                    : isActive
                        ? AppColors.secondaryAqua
                        : isOwned
                            ? AppColors.softPinkButton.withValues(alpha: 0.5)
                            : Colors.grey.withValues(alpha: 0.2),
                width: isActive ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Ana içerik - Yeni layout: İsim üstte, ikon ortada, fiyat altta
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Ürün adı (üstte)
                      _buildProductNameTop(),
                      
                      // Ürün ikonu (ortada)
                      Expanded(
                        child: Center(
                          child: _buildCenteredIcon(),
                        ),
                      ),
                      
                      // Fiyat satırı (altta: coin icon + miktar)
                      _buildPriceRowBottom(),
                    ],
                  ),
                ),
                
                // Kilit overlay (sadece kilitli itemlar için)
                if (_isLockedByStreak) _buildLockOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Ürün adı (üstte, küçük, karede sığacak şekilde)
  Widget _buildProductNameTop() {
    return SizedBox(
      height: 28, // Küçültüldü: 30 → 28
      child: Text(
        item.name,
        style: TextStyle(
          fontSize: 10, // Küçültüldü: 11 → 10
          fontWeight: FontWeight.w600,
          color: isActive
              ? AppColors.secondaryAqua
              : isOwned
                  ? Colors.grey[600]
                  : const Color(0xFF4A5568),
          height: 1.2, // Satır yüksekliği azaltıldı
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }

  /// Merkezi büyük ikon
  Widget _buildCenteredIcon() {
    return Center(
      child: Container(
        width: 64, // Sabit boyut
        height: 64,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: categoryColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            categoryIcon,
            size: 36,
            color: categoryColor,
          ),
        ),
      ),
    );
  }

  /// Fiyat satırı (altta: coin icon solda, miktar sağda)
  Widget _buildPriceRowBottom() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.monetization_on,
          size: 15, // Küçültüldü: 16 → 15
          color: canAfford ? AppColors.goldCoin : Colors.grey[400],
        ),
        const SizedBox(width: 4),
        Text(
          '${item.price}',
          style: TextStyle(
            fontSize: 13, // Küçültüldü: 14 → 13
            fontWeight: FontWeight.w700,
            color: canAfford ? AppColors.goldCoin : Colors.grey[400],
          ),
        ),
      ],
    );
  }

  /// Basitleştirilmiş kilit overlay
  Widget _buildLockOverlay() {
    final requiredStreak = item.requiredStreak!;
    final progress = (currentStreak / requiredStreak).clamp(0.0, 1.0);

    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(4.0), // Safety padding: 12 → 4
              child: FittedBox(
                fit: BoxFit.scaleDown, // Scale down if overflow
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Kilit ikonu
                    Icon(
                      Icons.lock_rounded,
                      size: 32,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.8),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4), // Azaltıldı: 8 → 4

                    // Gerekli seri metni
                    Text(
                      '$requiredStreak Günlük Seri',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2), // Azaltıldı: 4 → 2

                    // İlerleme metni
                    Text(
                      '$currentStreak / $requiredStreak',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4), // Azaltıldı: 8 → 4

                    // İlerleme çubuğu
                    Container(
                      width: 80,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.secondaryAqua,
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
      ),
    );
  }
}
