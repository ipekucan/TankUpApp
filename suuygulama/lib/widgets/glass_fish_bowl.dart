import 'package:flutter/material.dart';

/// Basit yuvarlak tank widget'ı - İçindeki child'ı daire şeklinde gösterir
class GlassFishBowl extends StatelessWidget {
  final Widget child;
  final double size;

  const GlassFishBowl({
    super.key,
    required this.child,
    this.size = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.15), // Hafif açık arka plan
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5), // Daha görünür beyaz kenarlık
          width: 3,
        ),
        // Dış çizgiye gölge ekle - arka plandan ayırt edilebilir olsun
        boxShadow: [
          // Dış gölge - tank'ı arka plandan ayırır
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          // İç parıltı efekti
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: -5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipOval(
        child: child, // Su animasyonunu daire içine kırp
      ),
    );
  }
}

