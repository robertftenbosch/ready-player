import '../models/chess_board.dart';
import '../models/chess_move.dart';
import '../models/chess_piece.dart';

class ChessMoveGenerator {
  ChessMoveGenerator._();

  /// Generates all legal moves for the given color.
  static List<ChessMove> generateLegalMoves(
      ChessBoard board, PieceColor color) {
    final moves = <ChessMove>[];
    for (int sq = 0; sq < 64; sq++) {
      final piece = board.pieceAt(sq);
      if (piece != null && piece.color == color) {
        moves.addAll(_generatePseudoLegalMoves(board, sq, piece));
      }
    }
    return _filterLegal(board, moves, color);
  }

  /// Generates all legal moves from a specific square.
  static List<ChessMove> generateLegalMovesFromSquare(
      ChessBoard board, int square) {
    final piece = board.pieceAt(square);
    if (piece == null) return [];
    final pseudoLegal = _generatePseudoLegalMoves(board, square, piece);
    return _filterLegal(board, pseudoLegal, piece.color);
  }

  /// Filters out moves that leave the king in check.
  static List<ChessMove> _filterLegal(
      ChessBoard board, List<ChessMove> moves, PieceColor color) {
    final opponent =
        color == PieceColor.white ? PieceColor.black : PieceColor.white;
    return moves.where((move) {
      final newBoard = board.applyMove(move);
      final kingSquare = newBoard.findKing(color);
      if (kingSquare < 0) return false;
      return !_isSquareAttacked(newBoard, kingSquare, opponent);
    }).toList();
  }

  static List<ChessMove> _generatePseudoLegalMoves(
      ChessBoard board, int square, ChessPiece piece) {
    switch (piece.type) {
      case PieceType.pawn:
        return _pawnMoves(board, square, piece.color);
      case PieceType.knight:
        return _knightMoves(board, square, piece.color);
      case PieceType.bishop:
        return _bishopMoves(board, square, piece.color);
      case PieceType.rook:
        return _rookMoves(board, square, piece.color);
      case PieceType.queen:
        return [
          ..._bishopMoves(board, square, piece.color),
          ..._rookMoves(board, square, piece.color),
        ];
      case PieceType.king:
        return _kingMoves(board, square, piece.color);
    }
  }

  static List<ChessMove> _pawnMoves(
      ChessBoard board, int square, PieceColor color) {
    final moves = <ChessMove>[];
    final row = square ~/ 8;
    final col = square % 8;
    final dir = color == PieceColor.white ? 1 : -1;
    final startRow = color == PieceColor.white ? 1 : 6;
    final promoRow = color == PieceColor.white ? 7 : 0;

    // Single push
    final oneStep = square + dir * 8;
    if (oneStep >= 0 && oneStep < 64 && board.pieceAt(oneStep) == null) {
      if (oneStep ~/ 8 == promoRow) {
        for (final promo in [
          PieceType.queen,
          PieceType.rook,
          PieceType.bishop,
          PieceType.knight,
        ]) {
          moves.add(ChessMove(from: square, to: oneStep, promotion: promo));
        }
      } else {
        moves.add(ChessMove(from: square, to: oneStep));
      }

      // Double push from starting position
      if (row == startRow) {
        final twoStep = square + dir * 16;
        if (board.pieceAt(twoStep) == null) {
          moves.add(ChessMove(from: square, to: twoStep));
        }
      }
    }

    // Captures
    for (final dc in [-1, 1]) {
      final c = col + dc;
      if (c < 0 || c > 7) continue;
      final target = (row + dir) * 8 + c;
      if (target < 0 || target > 63) continue;

      final targetPiece = board.pieceAt(target);
      if (targetPiece != null && targetPiece.color != color) {
        if (target ~/ 8 == promoRow) {
          for (final promo in [
            PieceType.queen,
            PieceType.rook,
            PieceType.bishop,
            PieceType.knight,
          ]) {
            moves.add(ChessMove(from: square, to: target, promotion: promo));
          }
        } else {
          moves.add(ChessMove(from: square, to: target));
        }
      }

      // En passant
      if (target == board.enPassantSquare) {
        moves.add(
            ChessMove(from: square, to: target, isEnPassant: true));
      }
    }

    return moves;
  }

  static List<ChessMove> _knightMoves(
      ChessBoard board, int square, PieceColor color) {
    final moves = <ChessMove>[];
    final row = square ~/ 8;
    final col = square % 8;
    const offsets = [
      [-2, -1], [-2, 1], [-1, -2], [-1, 2],
      [1, -2], [1, 2], [2, -1], [2, 1],
    ];
    for (final offset in offsets) {
      final r = row + offset[0];
      final c = col + offset[1];
      if (r < 0 || r > 7 || c < 0 || c > 7) continue;
      final target = r * 8 + c;
      final targetPiece = board.pieceAt(target);
      if (targetPiece == null || targetPiece.color != color) {
        moves.add(ChessMove(from: square, to: target));
      }
    }
    return moves;
  }

  static List<ChessMove> _bishopMoves(
      ChessBoard board, int square, PieceColor color) {
    return _slidingMoves(
        board, square, color, const [[1, 1], [1, -1], [-1, 1], [-1, -1]]);
  }

  static List<ChessMove> _rookMoves(
      ChessBoard board, int square, PieceColor color) {
    return _slidingMoves(
        board, square, color, const [[1, 0], [-1, 0], [0, 1], [0, -1]]);
  }

  static List<ChessMove> _slidingMoves(
      ChessBoard board, int square, PieceColor color,
      List<List<int>> directions) {
    final moves = <ChessMove>[];
    final row = square ~/ 8;
    final col = square % 8;
    for (final dir in directions) {
      for (int dist = 1; dist < 8; dist++) {
        final r = row + dir[0] * dist;
        final c = col + dir[1] * dist;
        if (r < 0 || r > 7 || c < 0 || c > 7) break;
        final target = r * 8 + c;
        final targetPiece = board.pieceAt(target);
        if (targetPiece == null) {
          moves.add(ChessMove(from: square, to: target));
        } else {
          if (targetPiece.color != color) {
            moves.add(ChessMove(from: square, to: target));
          }
          break;
        }
      }
    }
    return moves;
  }

  static List<ChessMove> _kingMoves(
      ChessBoard board, int square, PieceColor color) {
    final moves = <ChessMove>[];
    final row = square ~/ 8;
    final col = square % 8;

    // Normal king moves
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final r = row + dr;
        final c = col + dc;
        if (r < 0 || r > 7 || c < 0 || c > 7) continue;
        final target = r * 8 + c;
        final targetPiece = board.pieceAt(target);
        if (targetPiece == null || targetPiece.color != color) {
          moves.add(ChessMove(from: square, to: target));
        }
      }
    }

    // Castling
    final opponent =
        color == PieceColor.white ? PieceColor.black : PieceColor.white;

    // Don't castle out of check
    if (_isSquareAttacked(board, square, opponent)) return moves;

    if (color == PieceColor.white) {
      // King-side: e1(4) -> g1(6), rook h1(7) -> f1(5)
      if (board.whiteKingSide &&
          square == 4 &&
          board.pieceAt(5) == null &&
          board.pieceAt(6) == null &&
          board.pieceAt(7)?.type == PieceType.rook &&
          board.pieceAt(7)?.color == PieceColor.white &&
          !_isSquareAttacked(board, 5, opponent) &&
          !_isSquareAttacked(board, 6, opponent)) {
        moves.add(const ChessMove(from: 4, to: 6, isCastling: true));
      }
      // Queen-side: e1(4) -> c1(2), rook a1(0) -> d1(3)
      if (board.whiteQueenSide &&
          square == 4 &&
          board.pieceAt(3) == null &&
          board.pieceAt(2) == null &&
          board.pieceAt(1) == null &&
          board.pieceAt(0)?.type == PieceType.rook &&
          board.pieceAt(0)?.color == PieceColor.white &&
          !_isSquareAttacked(board, 3, opponent) &&
          !_isSquareAttacked(board, 2, opponent)) {
        moves.add(const ChessMove(from: 4, to: 2, isCastling: true));
      }
    } else {
      // King-side: e8(60) -> g8(62), rook h8(63) -> f8(61)
      if (board.blackKingSide &&
          square == 60 &&
          board.pieceAt(61) == null &&
          board.pieceAt(62) == null &&
          board.pieceAt(63)?.type == PieceType.rook &&
          board.pieceAt(63)?.color == PieceColor.black &&
          !_isSquareAttacked(board, 61, opponent) &&
          !_isSquareAttacked(board, 62, opponent)) {
        moves.add(const ChessMove(from: 60, to: 62, isCastling: true));
      }
      // Queen-side: e8(60) -> c8(58), rook a8(56) -> d8(59)
      if (board.blackQueenSide &&
          square == 60 &&
          board.pieceAt(59) == null &&
          board.pieceAt(58) == null &&
          board.pieceAt(57) == null &&
          board.pieceAt(56)?.type == PieceType.rook &&
          board.pieceAt(56)?.color == PieceColor.black &&
          !_isSquareAttacked(board, 59, opponent) &&
          !_isSquareAttacked(board, 58, opponent)) {
        moves.add(const ChessMove(from: 60, to: 58, isCastling: true));
      }
    }

    return moves;
  }

  /// Internal attack check to avoid circular dependency with ChessRules.
  static bool _isSquareAttacked(
      ChessBoard board, int square, PieceColor byColor) {
    final row = square ~/ 8;
    final col = square % 8;

    // Knight
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

    // Pawn
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

    // King
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

    // Diagonals (bishop/queen)
    const diagonals = [[1, 1], [1, -1], [-1, 1], [-1, -1]];
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

    // Straights (rook/queen)
    const straights = [[1, 0], [-1, 0], [0, 1], [0, -1]];
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
}
