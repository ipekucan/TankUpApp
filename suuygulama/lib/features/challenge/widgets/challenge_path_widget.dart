import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/challenge_level_model.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';

/// Challenge Path Widget
/// Displays a Central Spine/Vine layout with level nodes on alternating sides
class ChallengePathWidget extends StatelessWidget {
  final List<ChallengeLevelModel> levels;
  final Function(ChallengeLevelModel)? onLevelTap;

  const ChallengePathWidget({
    super.key,
    required this.levels,
    this.onLevelTap,
  });

  static const double _nodeRadius = 26.0;
  static const double _nodeSpacing = 100.0;
  static const double _stemLength = 60.0;

  @override
  Widget build(BuildContext context) {
    if (levels.isEmpty) {
      return Center(
        child: Text(
          'Henüz görev bulunmuyor',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final centerX = screenWidth / 2;
        final totalHeight = levels.length * _nodeSpacing;
        const topPadding = 40.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            top: topPadding,
            bottom: AppConstants.defaultPadding * 2,
          ),
          child: SizedBox(
            height: totalHeight,
            child: CustomPaint(
              painter: _CentralSpinePainter(
                centerX: centerX,
                nodeCount: levels.length,
                nodeSpacing: _nodeSpacing,
                completedIndices: levels
                    .asMap()
                    .entries
                    .where((e) => e.value.isCompleted)
                    .map((e) => e.key)
                    .toList(),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: levels.asMap().entries.map((entry) {
                  final index = entry.key;
                  final level = entry.value;
                  final nodeY = index * _nodeSpacing + _nodeRadius;
                  final isLeft = index % 2 == 0; // Even = left, odd = right
                  final nodeX = isLeft
                      ? centerX - _stemLength - _nodeRadius
                      : centerX + _stemLength + _nodeRadius;

                  return Positioned(
                    left: nodeX - _nodeRadius,
                    top: nodeY - _nodeRadius,
                    child: GestureDetector(
                      onTap: onLevelTap != null ? () => onLevelTap!(level) : null,
                      child: _LevelNode(
                        dayNumber: level.dayNumber,
                        isCompleted: level.isCompleted,
                        isLocked: level.isLocked,
                        isActive: level.isActive,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Painter for the Central Spine (Vine) and connecting stems
class _CentralSpinePainter extends CustomPainter {
  final double centerX;
  final int nodeCount;
  final double nodeSpacing;
  final List<int> completedIndices;

  _CentralSpinePainter({
    required this.centerX,
    required this.nodeCount,
    required this.nodeSpacing,
    required this.completedIndices,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Draw central spine (vine) with slight sine wave
    final spinePath = Path();
    final totalHeight = nodeCount * nodeSpacing;
    const waveAmplitude = 5.0; // Slight wave for organic look
    const waveFrequency = 0.02;

    for (double y = 0; y <= totalHeight; y += 1) {
      final waveOffset = math.sin(y * waveFrequency) * waveAmplitude;
      final x = centerX + waveOffset;
      if (y == 0) {
        spinePath.moveTo(x, y);
      } else {
        spinePath.lineTo(x, y);
      }
    }

    paint.color = Colors.white.withValues(alpha: 0.4);
    canvas.drawPath(spinePath, paint);

    // Draw horizontal stems connecting to nodes
    const stemLength = 60.0;
    const nodeRadius = 26.0;

    for (int index = 0; index < nodeCount; index++) {
      final nodeY = index * nodeSpacing + nodeRadius;
      final isLeft = index % 2 == 0;
      final isCompleted = completedIndices.contains(index);

      // Calculate stem endpoint (where it touches the node)
      final stemEndX = isLeft
          ? centerX - stemLength - nodeRadius
          : centerX + stemLength + nodeRadius;

      final stemPath = Path();
      stemPath.moveTo(centerX, nodeY);
      stemPath.lineTo(stemEndX, nodeY);

      paint.strokeWidth = 2.5;
      // Use vibrant turquoise for completed, white for uncompleted
      paint.color = isCompleted
          ? const Color(0xFF00C9FF).withValues(alpha: 0.7)
          : Colors.white.withValues(alpha: 0.4);
      canvas.drawPath(stemPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CentralSpinePainter oldDelegate) {
    return oldDelegate.centerX != centerX ||
        oldDelegate.nodeCount != nodeCount ||
        oldDelegate.nodeSpacing != nodeSpacing ||
        oldDelegate.completedIndices != completedIndices;
  }
}

/// Individual Level Node Component
class _LevelNode extends StatelessWidget {
  final int dayNumber;
  final bool isCompleted;
  final bool isLocked;
  final bool isActive;

  const _LevelNode({
    required this.dayNumber,
    required this.isCompleted,
    required this.isLocked,
    required this.isActive,
  });

  static const double _nodeRadius = 26.0;

  @override
  Widget build(BuildContext context) {
    final nodeSize = _nodeRadius * 2;

    Color backgroundColor;
    Color borderColor;
    Widget content;

    // Vibrant Turquoise/Seafoam for completed and active
    const vibrantTurquoise = Color(0xFF00C9FF);
    
    if (isLocked) {
      // Frosted sea glass look for locked - semi-transparent white with slight blue tint
      backgroundColor = const Color(0xFFE8F4F8).withValues(alpha: 0.6); // Light blue-tinted white
      borderColor = Colors.white.withValues(alpha: 0.4); // Visible border
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock,
            color: Colors.grey[600],
            size: 18,
          ),
          const SizedBox(height: 4),
          Text(
            '$dayNumber',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      );
    } else if (isCompleted) {
      // Vibrant turquoise/seafoam for completed
      backgroundColor = vibrantTurquoise;
      borderColor = vibrantTurquoise;
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(height: 4),
          Text(
            '$dayNumber',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      );
    } else if (isActive) {
      // Active node - vibrant turquoise with glow
      backgroundColor = vibrantTurquoise;
      borderColor = vibrantTurquoise;
      content = Icon(
        Icons.water_drop,
        color: Colors.white,
        size: 32, // Large icon for active state
      );
    } else {
      // Unlocked but not active - vibrant turquoise
      backgroundColor = vibrantTurquoise;
      borderColor = vibrantTurquoise;
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.water_drop,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(height: 4),
          Text(
            '$dayNumber',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      );
    }

    return Container(
      width: nodeSize,
      height: nodeSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: isActive ? 3.0 : 2.5,
        ),
        boxShadow: [
          // Shadow for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
          // Subtle outer glow for completed and active nodes (aquatic theme)
          if (!isLocked)
            BoxShadow(
              color: const Color(0xFF00C9FF).withValues(alpha: 0.5),
              blurRadius: 12,
              spreadRadius: 2,
            ),
        ],
      ),
      child: content,
    );
  }
}
