import 'dart:ui';

import '../models/castle.dart';

class DamageCalculator {
  static const double _blastRadius = 2.0; // in block units
  static const double _damagePerBlock = 0.02;

  static Castle applyDamage(Castle castle, Offset hitPoint) {
    final tl = castle.topLeft;
    final localX = (hitPoint.dx - tl.dx) / Castle.blockSize;
    final localY = (hitPoint.dy - tl.dy) / Castle.blockSize;

    var result = castle.clone();
    double totalDamage = 0.0;

    // Destroy blocks in a radius around the hit
    final minBX = (localX - _blastRadius).floor().clamp(0, Castle.gridWidth - 1);
    final maxBX = (localX + _blastRadius).ceil().clamp(0, Castle.gridWidth - 1);
    final minBY =
        (localY - _blastRadius).floor().clamp(0, Castle.gridHeight - 1);
    final maxBY =
        (localY + _blastRadius).ceil().clamp(0, Castle.gridHeight - 1);

    for (int by = minBY; by <= maxBY; by++) {
      for (int bx = minBX; bx <= maxBX; bx++) {
        final dist = ((bx + 0.5 - localX) * (bx + 0.5 - localX) +
                (by + 0.5 - localY) * (by + 0.5 - localY));
        if (dist <= _blastRadius * _blastRadius &&
            result.blocks[by][bx]) {
          result.blocks[by][bx] = false;
          totalDamage += _damagePerBlock;
        }
      }
    }

    return Castle(
      x: result.x,
      y: result.y,
      health: (result.health - totalDamage).clamp(0.0, 1.0),
      blocks: result.blocks,
      kingPosition: result.kingPosition,
      isLeft: result.isLeft,
    );
  }
}
