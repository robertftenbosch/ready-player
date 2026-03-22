import 'package:flutter/material.dart';
import '../theme/retro_colors.dart';

class PixelBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double borderWidth;
  final EdgeInsets padding;

  const PixelBorder({
    super.key,
    required this.child,
    this.color = RetroColors.primary,
    this.borderWidth = 2,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PixelBorderPainter(color: color, borderWidth: borderWidth),
      child: Padding(
        padding: padding + EdgeInsets.all(borderWidth),
        child: child,
      ),
    );
  }
}

class _PixelBorderPainter extends CustomPainter {
  final Color color;
  final double borderWidth;

  _PixelBorderPainter({required this.color, required this.borderWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;

    final b = borderWidth;

    // Top
    canvas.drawRect(Rect.fromLTWH(b, 0, size.width - 2 * b, b), paint);
    // Bottom
    canvas.drawRect(
        Rect.fromLTWH(b, size.height - b, size.width - 2 * b, b), paint);
    // Left
    canvas.drawRect(Rect.fromLTWH(0, b, b, size.height - 2 * b), paint);
    // Right
    canvas.drawRect(
        Rect.fromLTWH(size.width - b, b, b, size.height - 2 * b), paint);

    // Corner pixels (stepped corners)
    canvas.drawRect(Rect.fromLTWH(b, b, b, b), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - 2 * b, b, b, b), paint);
    canvas.drawRect(
        Rect.fromLTWH(b, size.height - 2 * b, b, b), paint);
    canvas.drawRect(
        Rect.fromLTWH(size.width - 2 * b, size.height - 2 * b, b, b), paint);
  }

  @override
  bool shouldRepaint(covariant _PixelBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.borderWidth != borderWidth;
  }
}
