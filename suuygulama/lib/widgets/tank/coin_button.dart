import 'package:flutter/material.dart';

/// Coin button widget - Yellow circular button with coin amount inside
class CoinButton extends StatelessWidget {
  final int coinAmount;

  const CoinButton({
    super.key,
    required this.coinAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      width: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFF3E38D), // Pastel Yellow
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF3E38D).withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$coinAmount',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF5D4037),
          ),
        ),
      ),
    );
  }
}
