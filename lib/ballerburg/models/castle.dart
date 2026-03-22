import 'dart:ui';

class Castle {
  final double x;
  final double y;
  final double health;
  final List<List<bool>> blocks;
  final Offset kingPosition;
  final bool isLeft;

  Castle({
    required this.x,
    required this.y,
    required this.health,
    required this.blocks,
    required this.kingPosition,
    required this.isLeft,
  });

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'health': health,
        'blocks': blocks.map((row) => row.map((b) => b).toList()).toList(),
        'kingPositionDx': kingPosition.dx,
        'kingPositionDy': kingPosition.dy,
        'isLeft': isLeft,
      };

  factory Castle.fromJson(Map<String, dynamic> json) {
    return Castle(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      health: (json['health'] as num).toDouble(),
      blocks: (json['blocks'] as List)
          .map((row) => (row as List).cast<bool>())
          .toList(),
      kingPosition: Offset(
        (json['kingPositionDx'] as num).toDouble(),
        (json['kingPositionDy'] as num).toDouble(),
      ),
      isLeft: json['isLeft'] as bool,
    );
  }

  static const int gridWidth = 8;
  static const int gridHeight = 12;
  static const double blockSize = 5.0;

  Castle clone() {
    return Castle(
      x: x,
      y: y,
      health: health,
      blocks: blocks.map((row) => List<bool>.from(row)).toList(),
      kingPosition: kingPosition,
      isLeft: isLeft,
    );
  }

  Castle takeDamage(double amount, int blockX, int blockY) {
    final newBlocks = blocks.map((row) => List<bool>.from(row)).toList();
    if (blockY >= 0 &&
        blockY < newBlocks.length &&
        blockX >= 0 &&
        blockX < newBlocks[blockY].length) {
      newBlocks[blockY][blockX] = false;
    }
    final newHealth = (health - amount).clamp(0.0, 1.0);
    return Castle(
      x: x,
      y: y,
      health: newHealth,
      blocks: newBlocks,
      kingPosition: kingPosition,
      isLeft: isLeft,
    );
  }

  /// Returns the top-left corner of the castle block grid in canvas coordinates.
  Offset get topLeft {
    final totalWidth = gridWidth * blockSize;
    final totalHeight = gridHeight * blockSize;
    return Offset(x - totalWidth / 2, y - totalHeight);
  }

  /// Returns the bounding rect of the castle block grid.
  Rect get boundingRect {
    final tl = topLeft;
    return Rect.fromLTWH(
      tl.dx,
      tl.dy,
      gridWidth * blockSize,
      gridHeight * blockSize,
    );
  }

  /// Creates a default castle with all blocks intact.
  static Castle createDefault({
    required double x,
    required double y,
    required bool isLeft,
  }) {
    // Build a castle shape: wider at base, narrower tower on top
    final blocks = List.generate(gridHeight, (row) {
      return List.generate(gridWidth, (col) {
        // Bottom 4 rows: full width base
        if (row >= gridHeight - 4) return true;
        // Middle 4 rows: slightly narrower
        if (row >= gridHeight - 8) {
          return col >= 1 && col <= gridWidth - 2;
        }
        // Top 4 rows: tower in center
        return col >= 2 && col <= gridWidth - 3;
      });
    });

    // King sits in the center of the castle, in the base area
    final kingX = (gridWidth / 2) * blockSize;
    final kingY = (gridHeight - 2) * blockSize;

    return Castle(
      x: x,
      y: y,
      health: 1.0,
      blocks: blocks,
      kingPosition: Offset(kingX, kingY),
      isLeft: isLeft,
    );
  }
}
