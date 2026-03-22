import 'dart:math';
import 'dart:ui';

import 'package:flutter/painting.dart';

import '../../core/theme/retro_colors.dart';

class ExplosionRenderer {
  static void paint(Canvas canvas, Offset? explosionPoint, double progress) {
    if (explosionPoint == null || progress <= 0.0) return;

    final rng = Random(explosionPoint.hashCode);
    final maxRadius = 15.0 * progress;
    final numParticles = (12 * progress).toInt().clamp(1, 12);

    // Outer glow
    final glowPaint = Paint()
      ..isAntiAlias = false
      ..color = RetroColors.explosion.withAlpha((150 * (1.0 - progress)).toInt());
    canvas.drawRect(
      Rect.fromCenter(
        center: explosionPoint,
        width: maxRadius * 2,
        height: maxRadius * 2,
      ),
      glowPaint,
    );

    // Particles
    for (int i = 0; i < numParticles; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final dist = rng.nextDouble() * maxRadius;
      final px = explosionPoint.dx + cos(angle) * dist;
      final py = explosionPoint.dy + sin(angle) * dist;
      final size = 2.0 + rng.nextDouble() * 3.0;

      final color = rng.nextBool()
          ? RetroColors.explosion
          : RetroColors.cannonBall;

      final particlePaint = Paint()
        ..isAntiAlias = false
        ..color = color.withAlpha((255 * (1.0 - progress * 0.7)).toInt());

      canvas.drawRect(
        Rect.fromLTWH(px, py, size, size),
        particlePaint,
      );
    }

    // Center flash (bright white at start)
    if (progress < 0.3) {
      final flashPaint = Paint()
        ..isAntiAlias = false
        ..color = const Color(0xFFFFFFFF)
            .withAlpha((255 * (1.0 - progress / 0.3)).toInt());
      canvas.drawRect(
        Rect.fromCenter(center: explosionPoint, width: 6, height: 6),
        flashPaint,
      );
    }
  }
}
