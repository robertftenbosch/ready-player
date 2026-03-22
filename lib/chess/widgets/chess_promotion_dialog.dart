import 'package:flutter/material.dart';

import '../../core/theme/retro_colors.dart';
import '../models/chess_move.dart';
import '../models/chess_piece.dart';

class ChessPromotionDialog extends StatelessWidget {
  final int from;
  final int to;
  final PieceColor color;

  const ChessPromotionDialog({
    super.key,
    required this.from,
    required this.to,
    required this.color,
  });

  /// Shows the promotion dialog and returns the selected ChessMove,
  /// or null if cancelled.
  static Future<ChessMove?> show(
    BuildContext context, {
    required int from,
    required int to,
    required PieceColor color,
  }) {
    return showDialog<ChessMove>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChessPromotionDialog(
        from: from,
        to: to,
        color: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pieces = [
      PieceType.queen,
      PieceType.rook,
      PieceType.bishop,
      PieceType.knight,
    ];

    return Dialog(
      backgroundColor: RetroColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: RetroColors.primary, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PROMOTE PAWN',
              style: TextStyle(
                color: RetroColors.primary,
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: pieces.map((type) {
                final piece = ChessPiece(type, color);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop(
                        ChessMove(
                          from: from,
                          to: to,
                          promotion: type,
                        ),
                      );
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: RetroColors.surfaceLight,
                        border: Border.all(
                          color: RetroColors.primaryDim,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          piece.symbol,
                          style: TextStyle(
                            fontSize: 36,
                            color: color == PieceColor.white
                                ? RetroColors.pieceWhite
                                : RetroColors.pieceBlack,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
