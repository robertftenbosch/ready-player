import 'dart:ui';

import 'package:flutter/painting.dart';

import '../../core/theme/retro_colors.dart';
import '../models/projectile.dart';

class ProjectileRenderer {
  static void paint(Canvas canvas, Projectile? projectile) {
    if (projectile == null) return;

    // Draw trail
    final trailPaint = Paint()
      ..isAntiAlias = false
      ..color = RetroColors.cannonBall.withAlpha(80);

    final startIdx = (projectile.currentIndex - 20).clamp(0, projectile.trajectory.length - 1);
    for (int i = startIdx; i < projectile.currentIndex; i += 2) {
      final pt = projectile.trajectory[i];
      canvas.drawRect(
        Rect.fromLTWH(pt.dx - 1, pt.dy - 1, 2, 2),
        trailPaint,
      );
    }

    // Draw cannonball
    final pos = projectile.currentPosition;
    final ballPaint = Paint()
      ..isAntiAlias = false
      ..color = RetroColors.cannonBall;
    canvas.drawRect(
      Rect.fromLTWH(pos.dx - 2, pos.dy - 2, 4, 4),
      ballPaint,
    );

    // Bright center pixel
    final centerPaint = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFFFFFFFF);
    canvas.drawRect(
      Rect.fromLTWH(pos.dx - 1, pos.dy - 1, 2, 2),
      centerPaint,
    );
  }
}
