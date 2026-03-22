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
    // The game state uses a logical coordinate system (canvasWidth x canvasHeight,
    // typically 400x300). Scale the canvas so everything renders at the correct
    // size regardless of the actual widget dimensions.
    final gameW = gameState.canvasWidth;
    final gameH = gameState.canvasHeight;
    final scaleX = size.width / gameW;
    final scaleY = size.height / gameH;

    // Use the logical game size for all renderers
    final gameSize = Size(gameW, gameH);

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // Layer 1: Sky with stars
    SkyRenderer.paint(canvas, gameSize);

    // Layer 2: Mountain terrain
    MountainRenderer.paint(canvas, gameState.mountain, gameSize);

    // Layer 3: Ground plane
    final groundPaint = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFF1A3300);
    canvas.drawRect(
      Rect.fromLTWH(0, gameSize.height * 0.85, gameSize.width, gameSize.height * 0.15),
      groundPaint,
    );

    // Layer 4: Castles
    CastleRenderer.paint(canvas, gameState.leftCastle, gameSize);
    CastleRenderer.paint(canvas, gameState.rightCastle, gameSize);

    // Layer 5: Projectile
    ProjectileRenderer.paint(canvas, gameState.projectile);

    // Layer 6: Explosion
    ExplosionRenderer.paint(
      canvas,
      gameState.explosionPoint,
      gameState.explosionProgress,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BallerburgPainter oldDelegate) {
    return oldDelegate.gameState != gameState;
  }
}
