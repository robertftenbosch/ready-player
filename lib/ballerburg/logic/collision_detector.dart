import 'dart:ui';

import '../models/ballerburg_game_state.dart';
import '../models/castle.dart';

enum CollisionType {
  mountain,
  leftCastle,
  rightCastle,
  leftKingHit,
  rightKingHit,
  ground,
}

class CollisionResult {
  final CollisionType type;
  final Offset point;
  final int? blockX;
  final int? blockY;

  const CollisionResult({
    required this.type,
    required this.point,
    this.blockX,
    this.blockY,
  });
}

class CollisionDetector {
  static CollisionResult? checkCollision(
      Offset point, BallerburgGameState state) {
    // Check king hits first (highest priority)
    final leftKing = _checkKingHit(point, state.leftCastle);
    if (leftKing != null) {
      return CollisionResult(
        type: CollisionType.leftKingHit,
        point: point,
      );
    }

    final rightKing = _checkKingHit(point, state.rightCastle);
    if (rightKing != null) {
      return CollisionResult(
        type: CollisionType.rightKingHit,
        point: point,
      );
    }

    // Check castle block collisions
    final leftBlock = _checkCastleBlocks(point, state.leftCastle);
    if (leftBlock != null) {
      return CollisionResult(
        type: CollisionType.leftCastle,
        point: point,
        blockX: leftBlock.$1,
        blockY: leftBlock.$2,
      );
    }

    final rightBlock = _checkCastleBlocks(point, state.rightCastle);
    if (rightBlock != null) {
      return CollisionResult(
        type: CollisionType.rightCastle,
        point: point,
        blockX: rightBlock.$1,
        blockY: rightBlock.$2,
      );
    }

    // Check mountain
    if (state.mountain.heightMap.isNotEmpty) {
      final mx = point.dx;
      if (mx >= 0 && mx < state.mountain.heightMap.length) {
        final mountainY = state.mountain.heightAt(mx);
        if (point.dy >= mountainY) {
          return CollisionResult(
            type: CollisionType.mountain,
            point: point,
          );
        }
      }
    }

    // Check ground
    if (point.dy >= state.canvasHeight) {
      return CollisionResult(
        type: CollisionType.ground,
        point: point,
      );
    }

    return null;
  }

  static bool? _checkKingHit(Offset point, Castle castle) {
    final tl = castle.topLeft;
    final kingWorldPos = Offset(
      tl.dx + castle.kingPosition.dx,
      tl.dy + castle.kingPosition.dy,
    );
    const kingSize = 6.0;
    final kingRect = Rect.fromCenter(
      center: kingWorldPos,
      width: kingSize,
      height: kingSize,
    );
    if (kingRect.contains(point)) return true;
    return null;
  }

  static (int, int)? _checkCastleBlocks(Offset point, Castle castle) {
    final tl = castle.topLeft;
    final localX = point.dx - tl.dx;
    final localY = point.dy - tl.dy;

    final blockX = (localX / Castle.blockSize).floor();
    final blockY = (localY / Castle.blockSize).floor();

    if (blockY >= 0 &&
        blockY < castle.blocks.length &&
        blockX >= 0 &&
        blockX < castle.blocks[blockY].length) {
      if (castle.blocks[blockY][blockX]) {
        return (blockX, blockY);
      }
    }
    return null;
  }
}
