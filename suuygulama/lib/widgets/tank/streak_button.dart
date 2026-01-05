import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/app_colors.dart';

/// Streak button widget - Circular button with fire icon, streak count, and progress ring
///
/// Displays real-time streak progress with:
/// - Circular progress ring showing current consumption vs daily goal
/// - Center text showing live streak count
/// - Dynamic updates when goal changes
class StreakButton extends StatelessWidget {
  final int streakCount;
  final double consumedAmount;
  final double dailyGoal;
  final VoidCallback onTap;

  const StreakButton({
    super.key,
    required this.streakCount,
    required this.consumedAmount,
    required this.dailyGoal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress dynamically: consumedAmount / dailyGoal
    // This recalculates immediately if dailyGoal changes
    final progress = dailyGoal > 0 ? (consumedAmount / dailyGoal).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 54,
        width: 54,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Progress ring background (inactive)
            CustomPaint(
              size: const Size(54, 54),
              painter: _ProgressRingPainter(
                progress: 1.0, // Full circle
                color: AppColors.tankBorder,
                strokeWidth: 3.5,
              ),
            ),

            // Progress ring foreground (active)
            CustomPaint(
              size: const Size(54, 54),
              painter: _ProgressRingPainter(
                progress: progress,
                color: AppColors.secondaryAqua,
                strokeWidth: 3.5,
              ),
            ),

            // Inner white circle
            Container(
              height: 46,
              width: 46,
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
                    top: 6,
                    child: Icon(
                      Icons.local_fire_department,
                      color: Color(0xFFF87D38), // Orange
                      size: 22,
                    ),
                  ),
                  // Streak count
                  Positioned(
                    bottom: 8,
                    child: Text(
                      '$streakCount',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for circular progress ring
class _ProgressRingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
