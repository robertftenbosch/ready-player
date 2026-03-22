import 'package:flutter/rendering.dart';

import '../models/ballerburg_game_state.dart';
import 'castle_renderer.dart';
import 'explosion_renderer.dart';
import 'mountain_renderer.dart';
import 'projectile_renderer.dart';
import 'sky_renderer.dart';

class BallerburgPainter extends CustomPainter {
  final BallerburgGameState gameState;

  BallerburgPainter({required this.gameState});

  @override
  void paint(Canvas canvas, Size size) {
    // Layer 1: Sky with stars
    SkyRenderer.paint(canvas, size);

    // Layer 2: Mountain terrain
    MountainRenderer.paint(canvas, gameState.mountain, size);

    // Layer 3: Ground plane
    final groundPaint = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFF1A3300);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.85, size.width, size.height * 0.15),
      groundPaint,
    );

    // Layer 4: Castles
    CastleRenderer.paint(canvas, gameState.leftCastle, size);
    CastleRenderer.paint(canvas, gameState.rightCastle, size);

    // Layer 5: Projectile
    ProjectileRenderer.paint(canvas, gameState.projectile);

    // Layer 6: Explosion
    ExplosionRenderer.paint(
      canvas,
      gameState.explosionPoint,
      gameState.explosionProgress,
    );
  }

  @override
  bool shouldRepaint(covariant BallerburgPainter oldDelegate) {
    return oldDelegate.gameState != gameState;
  }
}
