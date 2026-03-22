import '../models/chess_board.dart';
import '../models/chess_piece.dart';
import 'chess_move_generator.dart';

class ChessRules {
  ChessRules._();

  /// Checks if a square is attacked by any piece of the given color.
  static bool isSquareAttacked(
      ChessBoard board, int square, PieceColor byColor) {
    final row = square ~/ 8;
    final col = square % 8;

    // Knight attacks
    const knightOffsets = [
      [-2, -1], [-2, 1], [-1, -2], [-1, 2],
      [1, -2], [1, 2], [2, -1], [2, 1],
    ];
    for (final offset in knightOffsets) {
      final r = row + offset[0];
      final c = col + offset[1];
      if (r >= 0 && r < 8 && c >= 0 && c < 8) {
        final p = board.pieceAt(r * 8 + c);
        if (p != null && p.color == byColor && p.type == PieceType.knight) {
          return true;
        }
      }
    }

    // Pawn attacks
    final pawnDir = byColor == PieceColor.white ? -1 : 1;
    for (final dc in [-1, 1]) {
      final r = row + pawnDir;
      final c = col + dc;
      if (r >= 0 && r < 8 && c >= 0 && c < 8) {
        final p = board.pieceAt(r * 8 + c);
        if (p != null && p.color == byColor && p.type == PieceType.pawn) {
          return true;
        }
      }
    }

    // King attacks
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final r = row + dr;
        final c = col + dc;
        if (r >= 0 && r < 8 && c >= 0 && c < 8) {
          final p = board.pieceAt(r * 8 + c);
          if (p != null && p.color == byColor && p.type == PieceType.king) {
            return true;
          }
        }
      }
    }

    // Diagonal sliding (bishop + queen)
    const diagonals = [
      [1, 1], [1, -1], [-1, 1], [-1, -1],
    ];
    for (final dir in diagonals) {
      for (int dist = 1; dist < 8; dist++) {
        final r = row + dir[0] * dist;
        final c = col + dir[1] * dist;
        if (r < 0 || r > 7 || c < 0 || c > 7) break;
        final p = board.pieceAt(r * 8 + c);
        if (p != null) {
          if (p.color == byColor &&
              (p.type == PieceType.bishop || p.type == PieceType.queen)) {
            return true;
          }
          break;
        }
      }
    }

    // Straight sliding (rook + queen)
    const straights = [
      [1, 0], [-1, 0], [0, 1], [0, -1],
    ];
    for (final dir in straights) {
      for (int dist = 1; dist < 8; dist++) {
        final r = row + dir[0] * dist;
        final c = col + dir[1] * dist;
        if (r < 0 || r > 7 || c < 0 || c > 7) break;
        final p = board.pieceAt(r * 8 + c);
        if (p != null) {
          if (p.color == byColor &&
              (p.type == PieceType.rook || p.type == PieceType.queen)) {
            return true;
          }
          break;
        }
      }
    }

    return false;
  }

  /// Returns true if the given color's king is in check.
  static bool isInCheck(ChessBoard board, PieceColor color) {
    final kingSquare = board.findKing(color);
    if (kingSquare < 0) return false;
    final opponent =
        color == PieceColor.white ? PieceColor.black : PieceColor.white;
    return isSquareAttacked(board, kingSquare, opponent);
  }

  /// Returns true if the given color is in checkmate.
  static bool isCheckmate(ChessBoard board, PieceColor color) {
    if (!isInCheck(board, color)) return false;
    return ChessMoveGenerator.generateLegalMoves(board, color).isEmpty;
  }

  /// Returns true if the given color is in stalemate.
  static bool isStalemate(ChessBoard board, PieceColor color) {
    if (isInCheck(board, color)) return false;
    return ChessMoveGenerator.generateLegalMoves(board, color).isEmpty;
  }

  /// Returns true if the position is a draw (50-move rule or insufficient material).
  static bool isDraw(ChessBoard board) {
    // 50-move rule
    if (board.halfMoveClock >= 100) return true;

    // Insufficient material
    final whites = <PieceType>[];
    final blacks = <PieceType>[];
    for (int i = 0; i < 64; i++) {
      final p = board.pieceAt(i);
      if (p == null) continue;
      if (p.color == PieceColor.white) {
        whites.add(p.type);
      } else {
        blacks.add(p.type);
      }
    }

    // King vs King
    if (whites.length == 1 && blacks.length == 1) return true;

    // King + minor vs King
    if (whites.length == 1 && blacks.length == 2) {
      final nonKing = blacks.firstWhere((t) => t != PieceType.king);
      if (nonKing == PieceType.bishop || nonKing == PieceType.knight) {
        return true;
      }
    }
    if (blacks.length == 1 && whites.length == 2) {
      final nonKing = whites.firstWhere((t) => t != PieceType.king);
      if (nonKing == PieceType.bishop || nonKing == PieceType.knight) {
        return true;
      }
    }

    return false;
  }
}
