import 'package:flutter/material.dart';

import '../../core/theme/retro_colors.dart';
import '../models/chess_piece.dart';

class ChessPieceWidget extends StatelessWidget {
  final ChessPiece piece;
  final double size;

  const ChessPieceWidget({
    super.key,
    required this.piece,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
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
  }
}
