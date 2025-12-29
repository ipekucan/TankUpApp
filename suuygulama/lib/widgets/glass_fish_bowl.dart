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
          color: Colors.white.withValues(alpha: 0.3), // Zarif beyaz kenarlık
          width: 2,
        ),
      ),
      child: ClipOval(
        child: child, // Su animasyonunu daire içine kırp
      ),
    );
  }
}

