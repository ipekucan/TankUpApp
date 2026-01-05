import 'package:flutter/material.dart';
import '../../models/decoration_item.dart';
import '../../utils/app_colors.dart';

/// Satın alma onay dialogu - Modüler widget
///
/// "Satın almak ister misiniz?" sorusu ile birlikte
/// - Satın Al butonu (yeşil)
/// - Reklam İzle butonu (mor)
class PurchaseDialog extends StatelessWidget {
  final DecorationItem item;
  final VoidCallback onPurchase;
  final VoidCallback onWatchAd;
  final IconData? itemIcon; // Ürün ikonu
  final Color? itemIconColor; // İkon rengi

  const PurchaseDialog({
    super.key,
    required this.item,
    required this.onPurchase,
    required this.onWatchAd,
    this.itemIcon,
    this.itemIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85, // Ekranı ortalayacak büyüklük
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Soru metni
            const Text(
              'Satın almak ister misiniz?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Ürün bilgisi
            _buildItemInfo(),
            const SizedBox(height: 28),

            // Butonlar
            Row(
              children: [
                // Satın Al butonu (yeşil, sol)
                Expanded(
                  child: _buildPurchaseButton(context),
                ),
                const SizedBox(width: 14),

                // Reklam İzle butonu (mor, sağ)
                Expanded(
                  child: _buildAdButton(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Ürün bilgisi (isim + ikon + fiyat)
  Widget _buildItemInfo() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Ürün adı
          Text(
            item.name,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Ürün ikonu (ortada, büyük)
          if (itemIcon != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: (itemIconColor ?? AppColors.secondaryAqua).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                itemIcon,
                size: 48,
                color: itemIconColor ?? AppColors.secondaryAqua,
              ),
            ),
          
          if (itemIcon != null) const SizedBox(height: 16),
          
          // Fiyat (coin icon + miktar)
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.monetization_on,
                size: 24,
                color: AppColors.goldCoin,
              ),
              const SizedBox(width: 8),
              Text(
                '${item.price}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldCoin,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Satın Al butonu (soft pastel yeşil, yarı opak)
  Widget _buildPurchaseButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        onPurchase();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF9AE6B4).withValues(alpha: 0.7), // Soft pastel yeşil
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: 0,
      ),
      child: const Text(
        'Satın Al',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// Reklam İzle butonu (soft pastel mor, yarı opak)
  Widget _buildAdButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        onWatchAd();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD6BCFA).withValues(alpha: 0.7), // Soft pastel mor
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: 0,
      ),
      child: const Text(
        'Reklam İzle',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
