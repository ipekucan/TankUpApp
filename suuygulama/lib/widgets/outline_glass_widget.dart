import 'package:flutter/material.dart';

/// Outlined glass/cup widget for visual representation
class OutlineGlassWidget extends StatelessWidget {
  final Color color;
  final double width;
  final double height;

  const OutlineGlassWidget({
    super.key,
    required this.color,
    this.width = 120,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _GlassPainter(color: color),
    );
  }
}

class _GlassPainter extends CustomPainter {
  final Color color;

  _GlassPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    // Glass shape - tapered cup
    final topWidth = size.width * 0.85;
    final bottomWidth = size.width * 0.65;
    final cupHeight = size.height * 0.85;
    
    // Top left
    path.moveTo((size.width - topWidth) / 2, size.height * 0.1);
    
    // Top right
    path.lineTo((size.width + topWidth) / 2, size.height * 0.1);
    
    // Right side (tapered)
    path.lineTo((size.width + bottomWidth) / 2, size.height * 0.1 + cupHeight);
    
    // Bottom (rounded)
    path.quadraticBezierTo(
      size.width / 2,
      size.height * 0.1 + cupHeight + 5,
      (size.width - bottomWidth) / 2,
      size.height * 0.1 + cupHeight,
    );
    
    // Left side (tapered)
    path.lineTo((size.width - topWidth) / 2, size.height * 0.1);

    canvas.drawPath(path, paint);

    // Add horizontal lines for volume marks
    final markPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * 0.1 + (cupHeight / 4) * i;
      final widthAtY = bottomWidth + (topWidth - bottomWidth) * (1 - i / 4);
      
      canvas.drawLine(
        Offset((size.width - widthAtY) / 2 + 8, y),
        Offset((size.width + widthAtY) / 2 - 8, y),
        markPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GlassPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
