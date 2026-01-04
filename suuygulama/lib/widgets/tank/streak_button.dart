import 'package:flutter/material.dart';

/// Streak button widget - Orange circular button with fire icon and streak count
class StreakButton extends StatelessWidget {
  final int streakCount;
  final VoidCallback onTap;

  const StreakButton({
    super.key,
    required this.streakCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        width: 54,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Fire icon
            const Positioned(
              top: 8,
              child: Icon(
                Icons.local_fire_department,
                color: Color(0xFFF87D38), // Orange
                size: 24,
              ),
            ),
            // Streak count
            Positioned(
              bottom: 10,
              child: Text(
                '$streakCount',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF5D4037),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
