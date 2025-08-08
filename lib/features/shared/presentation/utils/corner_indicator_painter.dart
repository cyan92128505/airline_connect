import 'package:flutter/material.dart';

class CornerIndicatorPainter extends CustomPainter {
  final Color color;
  final double lineWidth;
  final bool isTopLeft;
  final bool isTopRight;
  final bool isBottomRight;
  final bool isBottomLeft;

  CornerIndicatorPainter({
    required this.color,
    required this.lineWidth,
    required this.isTopLeft,
    required this.isTopRight,
    required this.isBottomRight,
    required this.isBottomLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 20.0;

    if (isTopLeft) {
      // Top-left corner: horizontal line going right, vertical line going down
      canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
      canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);
    } else if (isTopRight) {
      // Top-right corner: horizontal line going left, vertical line going down
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width - cornerLength, 0),
        paint,
      );
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width, cornerLength),
        paint,
      );
    } else if (isBottomRight) {
      // Bottom-right corner: horizontal line going left, vertical line going up
      canvas.drawLine(
        Offset(size.width, size.height),
        Offset(size.width - cornerLength, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(size.width, size.height),
        Offset(size.width, size.height - cornerLength),
        paint,
      );
    } else if (isBottomLeft) {
      // Bottom-left corner: horizontal line going right, vertical line going up
      canvas.drawLine(
        Offset(0, size.height),
        Offset(cornerLength, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, size.height),
        Offset(0, size.height - cornerLength),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
