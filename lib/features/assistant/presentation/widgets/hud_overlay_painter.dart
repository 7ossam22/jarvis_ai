import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class HudOverlayPainter extends CustomPainter {
  final double animation;
  final Color color;

  HudOverlayPainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Corner brackets
    _drawCornerBracket(canvas, Offset.zero, size, paint, 0);
    _drawCornerBracket(
        canvas, Offset(size.width, 0), size, paint, pi / 2);
    _drawCornerBracket(
        canvas, Offset(size.width, size.height), size, paint, pi);
    _drawCornerBracket(
        canvas, Offset(0, size.height), size, paint, 3 * pi / 2);

    // Horizontal scan line
    final scanY = size.height * animation;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          color.withValues(alpha: 0.3),
          color.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0, 0.3, 0.7, 1],
      ).createShader(Rect.fromLTWH(0, scanY - 20, size.width, 40));
    canvas.drawRect(
        Rect.fromLTWH(0, scanY - 1, size.width, 2), scanPaint);

    // Grid dots (sparse)
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    const spacing = 60.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }
  }

  void _drawCornerBracket(
      Canvas canvas, Offset corner, Size size, Paint paint, double angle) {
    const len = 30.0;
    canvas.save();
    canvas.translate(corner.dx, corner.dy);
    canvas.rotate(angle);

    final bracketPaint = Paint()
      ..color = AppColors.arcReactorCyan.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square;

    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), bracketPaint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, len), bracketPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(HudOverlayPainter old) => old.animation != animation;
}
