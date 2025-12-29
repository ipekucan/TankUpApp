import 'package:flutter/material.dart';

/// Boş mücadele slot kartı - Kullanıcıya yeni mücadele ekleyebileceğini gösterir
class EmptyChallengeSlot extends StatelessWidget {
  final VoidCallback? onTap;

  const EmptyChallengeSlot({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {
        // Şimdilik boş - ileride mücadele keşfet ekranına yönlendirilebilir
        debugPrint('Yeni Mücadele Ekle tıklandı');
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity, // Üstteki kartla aynı genişlik
        height: 70, // Slim yükseklik
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.4),
            width: 2,
            style: BorderStyle.solid, // Dashed yerine solid border (basit çözüm)
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 28, // Biraz küçültüldü (40 -> 28)
              color: Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(
              'Yeni Mücadele Ekle',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


