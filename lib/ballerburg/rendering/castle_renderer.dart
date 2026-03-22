import 'dart:ui';

import 'package:flutter/painting.dart';

import '../../core/theme/retro_colors.dart';
import '../models/castle.dart';

class CastleRenderer {
  static void paint(Canvas canvas, Castle castle, Size size) {
    final tl = castle.topLeft;
    final blockPaint = Paint()..isAntiAlias = false;

    // Draw blocks
    for (int row = 0; row < castle.blocks.length; row++) {
      for (int col = 0; col < castle.blocks[row].length; col++) {
        if (castle.blocks[row][col]) {
          final x = tl.dx + col * Castle.blockSize;
          final y = tl.dy + row * Castle.blockSize;

          // Slightly different shade for edges
          final isEdge = row == 0 ||
              col == 0 ||
              row == castle.blocks.length - 1 ||
              col == castle.blocks[row].length - 1 ||
              (row > 0 && !castle.blocks[row - 1][col]) ||
              (col > 0 && !castle.blocks[row][col - 1]);

          blockPaint.color = isEdge
              ? RetroColors.castle
              : RetroColors.castleDamaged;

          canvas.drawRect(
            Rect.fromLTWH(x, y, Castle.blockSize - 1, Castle.blockSize - 1),
            blockPaint,
          );
        }
      }
    }

    // Draw king as a small pixel character
    if (castle.health > 0) {
      final kingWorld = Offset(
        tl.dx + castle.kingPosition.dx,
        tl.dy + castle.kingPosition.dy,
      );

      final kingPaint = Paint()
        ..isAntiAlias = false
        ..color = const Color(0xFFFFD700); // gold

      // Crown (3 pixels on top)
      canvas.drawRect(
          Rect.fromLTWH(kingWorld.dx - 3, kingWorld.dy - 4, 2, 2), kingPaint);
      canvas.drawRect(
          Rect.fromLTWH(kingWorld.dx, kingWorld.dy - 5, 2, 2), kingPaint);
      canvas.drawRect(
          Rect.fromLTWH(kingWorld.dx + 3, kingWorld.dy - 4, 2, 2), kingPaint);

      // Head
      final headPaint = Paint()
        ..isAntiAlias = false
        ..color = const Color(0xFFFFCC99);
      canvas.drawRect(
          Rect.fromLTWH(kingWorld.dx - 1, kingWorld.dy - 2, 4, 3), headPaint);

      // Body
      final bodyPaint = Paint()
        ..isAntiAlias = false
        ..color = const Color(0xFFCC0000);
      canvas.drawRect(
          Rect.fromLTWH(kingWorld.dx - 2, kingWorld.dy + 1, 6, 4), bodyPaint);
    }

    // Draw cannon
    _drawCannon(canvas, castle);

    // Health bar
    _drawHealthBar(canvas, castle);
  }

  static void _drawCannon(Canvas canvas, Castle castle) {
    final tl = castle.topLeft;
    final cannonY = tl.dy + 2 * Castle.blockSize;
    final cannonX = castle.isLeft
        ? castle.x + Castle.gridWidth * Castle.blockSize / 2
        : castle.x - Castle.gridWidth * Castle.blockSize / 2;

    final cannonPaint = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFF444444);

    // Cannon base
    canvas.drawRect(
      Rect.fromLTWH(cannonX - 3, cannonY - 2, 6, 5),
      cannonPaint,
    );

    // Cannon barrel pointing outward
    final barrelPaint = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFF333333)
      ..strokeWidth = 3.0;

    final barrelEnd = castle.isLeft
        ? Offset(cannonX + 10, cannonY - 4)
        : Offset(cannonX - 10, cannonY - 4);
    canvas.drawLine(
      Offset(cannonX, cannonY),
      barrelEnd,
      barrelPaint,
    );
  }

  static void _drawHealthBar(Canvas canvas, Castle castle) {
    final barWidth = Castle.gridWidth * Castle.blockSize;
    final barX = castle.topLeft.dx;
    final barY = castle.topLeft.dy - 8;

    // Background
    final bgPaint = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFF333333);
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth, 4),
      bgPaint,
    );

    // Health fill
    final healthColor = castle.health > 0.5
        ? const Color(0xFF00FF00)
        : castle.health > 0.25
            ? const Color(0xFFFFCC00)
            : const Color(0xFFFF0000);
    final fillPaint = Paint()
      ..isAntiAlias = false
      ..color = healthColor;
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth * castle.health, 4),
      fillPaint,
    );
  }
}
