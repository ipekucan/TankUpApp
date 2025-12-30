import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/constants/app_constants.dart';
import '../../theme/app_text_styles.dart';

/// Custom painter for drawing the S-shaped winding path (road) connecting challenge nodes.
class _ChallengePathPainter extends CustomPainter {
  final int totalDays;
  final int completedDays;
  final double nodeRadius;

  _ChallengePathPainter({
    required this.totalDays,
    required this.completedDays,
    required this.nodeRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Calculate node positions (S-shaped curve)
    final nodePositions = _calculateNodePositions(size);

    // Draw path segments
    for (int i = 0; i < nodePositions.length - 1; i++) {
      final start = nodePositions[i];
      final end = nodePositions[i + 1];

      // Determine color based on completion
      if (i < completedDays) {
        // Completed path - vibrant orange gradient
        paint.shader = LinearGradient(
          colors: [
            const Color(0xFFFF6B35), // Vibrant orange
            const Color(0xFFFF8C42), // Lighter orange
          ],
        ).createShader(Rect.fromPoints(start, end));
      } else {
        // Incomplete path - subtle grey
        paint.color = Colors.grey[300]!;
        paint.shader = null;
      }

      // Draw curved path between nodes (smooth S-curve)
      final path = Path();
      path.moveTo(start.dx, start.dy);

      // Calculate control points for smooth S-curve
      final midX = (start.dx + end.dx) / 2;

      // Create S-curve effect by alternating control point positions
      final controlPoint1 = Offset(
        midX + (i % 2 == 0 ? 30 : -30), // Alternate left/right
        start.dy,
      );
      final controlPoint2 = Offset(
        midX + (i % 2 == 0 ? -30 : 30), // Alternate right/left
        end.dy,
      );

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        end.dx,
        end.dy,
      );

      canvas.drawPath(path, paint);
    }
  }

  /// Calculate positions for all nodes in an S-shaped pattern.
  List<Offset> _calculateNodePositions(Size size) {
    final positions = <Offset>[];
    final nodeSpacing = size.height / (totalDays + 1);
    final horizontalCenter = size.width / 2;
    final horizontalAmplitude = size.width * 0.25; // S-curve width

    for (int i = 0; i < totalDays; i++) {
      final y = nodeSpacing * (i + 1);
      // Create S-curve: alternate left/right with smooth transition
      final phase = (i / totalDays) * math.pi * 2;
      final x = horizontalCenter + math.sin(phase) * horizontalAmplitude;
      positions.add(Offset(x, y));
    }

    return positions;
  }

  @override
  bool shouldRepaint(_ChallengePathPainter oldDelegate) {
    return oldDelegate.totalDays != totalDays ||
        oldDelegate.completedDays != completedDays;
  }
}

/// Widget displaying the gamified challenge map with S-shaped path and nodes.
class ChallengeMapWidget extends StatelessWidget {
  final int totalDays;
  final int completedDays;
  final List<Map<String, dynamic>> dailyChallenges; // Each day's challenge data

  const ChallengeMapWidget({
    super.key,
    required this.totalDays,
    required this.completedDays,
    required this.dailyChallenges,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: _ChallengePathPainter(
            totalDays: totalDays,
            completedDays: completedDays,
            nodeRadius: AppConstants.challengeMapNodeRadius,
          ),
          child: Stack(
            children: _buildNodes(constraints),
          ),
        );
      },
    );
  }

  /// Build positioned nodes for each day.
  List<Widget> _buildNodes(BoxConstraints constraints) {
    final nodes = <Widget>[];
    final nodeSpacing = constraints.maxHeight / (totalDays + 1);
    final horizontalCenter = constraints.maxWidth / 2;
    final horizontalAmplitude = constraints.maxWidth * 0.25;
    final nodeRadius = AppConstants.challengeMapNodeRadius;

    for (int i = 0; i < totalDays; i++) {
      final y = nodeSpacing * (i + 1);
      final phase = (i / totalDays) * math.pi * 2;
      final x = horizontalCenter + math.sin(phase) * horizontalAmplitude;

      final isCompleted = i < completedDays;
      final isCurrent = i == completedDays;

      nodes.add(
        Positioned(
          left: x - nodeRadius,
          top: y - nodeRadius,
          child: _ChallengeNode(
            dayNumber: i + 1,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            radius: nodeRadius,
          ),
        ),
      );
    }

    return nodes;
  }
}

/// Individual challenge node (day circle).
class _ChallengeNode extends StatelessWidget {
  final int dayNumber;
  final bool isCompleted;
  final bool isCurrent;
  final double radius;

  const _ChallengeNode({
    required this.dayNumber,
    required this.isCompleted,
    required this.isCurrent,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? const Color(0xFFFF6B35) // Vibrant orange
            : isCurrent
                ? Colors.orange[300] // Current day - lighter orange
                : Colors.grey[300], // Incomplete - grey
        boxShadow: [
          BoxShadow(
            color: (isCompleted || isCurrent
                    ? const Color(0xFFFF6B35)
                    : Colors.grey)
                .withValues(alpha: isCurrent ? 0.4 : 0.2),
            blurRadius: isCurrent ? 12 : 8,
            spreadRadius: isCurrent ? 2 : 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$dayNumber',
          style: AppTextStyles.heading3.copyWith(
            color: isCompleted || isCurrent ? Colors.white : Colors.grey[700],
            fontSize: radius * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

