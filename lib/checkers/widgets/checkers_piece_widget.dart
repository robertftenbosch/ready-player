import 'package:flutter/material.dart';

import '../../core/theme/retro_colors.dart';
import '../models/checkers_piece.dart';

class CheckersPieceWidget extends StatelessWidget {
  final CheckersPiece piece;
  final double size;

  const CheckersPieceWidget({
    super.key,
    required this.piece,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isWhite = piece.color == CheckersColor.white;
    final fillColor = isWhite ? RetroColors.pieceWhite : RetroColors.pieceBlack;
    final borderColor = isWhite ? Colors.black54 : Colors.white54;
    final diameter = size * 0.78;

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fillColor,
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                offset: const Offset(1, 2),
                blurRadius: 2,
              ),
            ],
          ),
          child: piece.isKing ? _buildCrown(isWhite, diameter) : null,
        ),
      ),
    );
  }

  Widget _buildCrown(bool isWhite, double diameter) {
    return Center(
      child: Container(
        width: diameter * 0.55,
        height: diameter * 0.55,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isWhite ? Colors.amber.shade800 : Colors.amber.shade400,
            width: 2.5,
          ),
        ),
        child: Center(
          child: Text(
            '♛',
            style: TextStyle(
              fontSize: diameter * 0.32,
              color: isWhite ? Colors.amber.shade800 : Colors.amber.shade400,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
