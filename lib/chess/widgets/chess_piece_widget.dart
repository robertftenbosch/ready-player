import 'package:flutter/material.dart';

import '../../core/theme/retro_colors.dart';
import '../models/chess_piece.dart';

class ChessPieceWidget extends StatelessWidget {
  final ChessPiece piece;
  final double size;

  /// Rotation in quarter turns (0 = normal, 1 = 90° CW, 2 = 180°, 3 = 270°).
  final int quarterTurns;

  const ChessPieceWidget({
    super.key,
    required this.piece,
    this.size = 32,
    this.quarterTurns = 0,
  });

  @override
  Widget build(BuildContext context) {
    Widget text = Text(
      piece.symbol,
      style: TextStyle(
        fontSize: size,
        color: piece.color == PieceColor.white
            ? RetroColors.pieceWhite
            : RetroColors.pieceBlack,
        height: 1,
        shadows: [
          Shadow(
            color: piece.color == PieceColor.white
                ? Colors.black54
                : Colors.white24,
            blurRadius: 2,
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );
    if (quarterTurns != 0) {
      text = RotatedBox(quarterTurns: quarterTurns, child: text);
    }
    return text;
  }
}
