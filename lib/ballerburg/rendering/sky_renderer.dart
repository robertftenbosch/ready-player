import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../core/theme/retro_colors.dart';

class SkyRenderer {
  static final List<Offset> _stars = _generateStars();

  static List<Offset> _generateStars() {
    final rng = Random(42); // fixed seed for consistent stars
    return List.generate(60, (_) {
      return Offset(rng.nextDouble(), rng.nextDouble());
    });
  }

  static void paint(Canvas canvas, Size size) {
    // Sky gradient
    final skyPaint = Paint()
      ..isAntiAlias = false
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        [RetroColors.skyTop, RetroColors.skyBottom],
      );
    canvas.drawRect(Offset.zero & size, skyPaint);

    // Pixel stars
    final starPaint = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xCCFFFFFF);

    for (final star in _stars) {
      final sx = star.dx * size.width;
      final sy = star.dy * size.height * 0.6; // stars only in upper portion
      canvas.drawRect(Rect.fromLTWH(sx, sy, 2, 2), starPaint);
    }
  }
}
