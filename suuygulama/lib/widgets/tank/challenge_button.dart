import 'package:flutter/material.dart';

/// Challenge button widget - Trophy icon button with soft green color
class ChallengeButton extends StatelessWidget {
  final VoidCallback onTap;

  const ChallengeButton({
    super.key,
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
          color: const Color(0xFFA8E6CF), // Soft green
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA8E6CF).withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.emoji_events,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }
}
