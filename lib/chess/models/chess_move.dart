import 'chess_board.dart';
import 'chess_piece.dart';
import '../logic/chess_move_generator.dart';

class ChessMove {
  final int from;
  final int to;
  final PieceType? promotion;
  final bool isCastling;
  final bool isEnPassant;

  const ChessMove({
    required this.from,
    required this.to,
    this.promotion,
    this.isCastling = false,
    this.isEnPassant = false,
  });

  /// Converts this move to standard algebraic notation given the current board.
  String toAlgebraic(ChessBoard board) {
    // Castling
    if (isCastling) {
      return (to % 8 == 6) ? 'O-O' : 'O-O-O';
    }

    final piece = board.pieceAt(from);
    if (piece == null) return '??';

    final capture = board.pieceAt(to) != null || isEnPassant;
    final targetSquare = ChessBoard.notationFromSquare(to);

    // Apply the move to check for check/checkmate
    final newBoard = board.applyMove(this);
    final opponentColor = piece.color == PieceColor.white
        ? PieceColor.black
        : PieceColor.white;
    final opponentKing = newBoard.findKing(opponentColor);
    final inCheck = opponentKing >= 0 &&
        _isSquareAttackedSimple(newBoard, opponentKing, piece.color);
    final legalMoves =
        ChessMoveGenerator.generateLegalMoves(newBoard, opponentColor);
    final isMate = inCheck && legalMoves.isEmpty;

    String suffix = isMate
        ? '#'
        : inCheck
            ? '+'
            : '';

    // Pawn moves
    if (piece.type == PieceType.pawn) {
      String result;
      if (capture) {
        final fromFile =
            String.fromCharCode('a'.codeUnitAt(0) + (from % 8));
        result = '${fromFile}x$targetSquare';
      } else {
        result = targetSquare;
      }
      if (promotion != null) {
        result += '=${_pieceChar(promotion!)}';
      }
      return '$result$suffix';
    }

    final pieceChar = _pieceChar(piece.type);

    // Disambiguation: find other pieces of the same type and color that can
    // reach the same target square.
    String disambiguation = '';
    final allMoves =
        ChessMoveGenerator.generateLegalMoves(board, piece.color);
    final samePieceMoves = allMoves.where((m) {
      if (m.to != to) return false;
      if (m.from == from) return false;
      final p = board.pieceAt(m.from);
      return p != null && p.type == piece.type;
    }).toList();

    if (samePieceMoves.isNotEmpty) {
      final sameFile = samePieceMoves.any((m) => m.from % 8 == from % 8);
      final sameRank = samePieceMoves.any((m) => m.from ~/ 8 == from ~/ 8);
      if (!sameFile) {
        disambiguation =
            String.fromCharCode('a'.codeUnitAt(0) + (from % 8));
      } else if (!sameRank) {
        disambiguation = '${(from ~/ 8) + 1}';
      } else {
        disambiguation =
            ChessBoard.notationFromSquare(from);
      }
    }

    final captureStr = capture ? 'x' : '';
    return '$pieceChar$disambiguation$captureStr$targetSquare$suffix';
  }

  /// Parses algebraic notation into a ChessMove given the current board.
  static ChessMove? fromAlgebraic(String notation, ChessBoard board) {
    String san = notation.replaceAll('+', '').replaceAll('#', '').trim();

    if (san == 'O-O' || san == '0-0') {
      final king = board.activeColor == PieceColor.white ? 4 : 60;
      final target = board.activeColor == PieceColor.white ? 6 : 62;
      return ChessMove(from: king, to: target, isCastling: true);
    }
    if (san == 'O-O-O' || san == '0-0-0') {
      final king = board.activeColor == PieceColor.white ? 4 : 60;
      final target = board.activeColor == PieceColor.white ? 2 : 58;
      return ChessMove(from: king, to: target, isCastling: true);
    }

    // Parse promotion
    PieceType? promo;
    if (san.contains('=')) {
      final parts = san.split('=');
      san = parts[0];
      promo = _pieceTypeFromChar(parts[1][0]);
    }

    // Determine piece type
    PieceType pieceType = PieceType.pawn;
    if (san.isNotEmpty && 'KQRBN'.contains(san[0])) {
      pieceType = _pieceTypeFromChar(san[0])!;
      san = san.substring(1);
    }

    // Remove 'x' for captures
    san = san.replaceAll('x', '');

    // The last two characters are the target square
    if (san.length < 2) return null;
    final targetStr = san.substring(san.length - 2);
    final target = ChessBoard.squareFromNotation(targetStr);
    if (target < 0) return null;

    // Disambiguation characters (everything before target)
    final disambig = san.substring(0, san.length - 2);

    // Find the matching legal move
    final legalMoves =
        ChessMoveGenerator.generateLegalMoves(board, board.activeColor);

    for (final move in legalMoves) {
      if (move.to != target) continue;
      final piece = board.pieceAt(move.from);
      if (piece == null || piece.type != pieceType) continue;

      // Check promotion match
      if (promo != null && move.promotion != promo) continue;
      if (promo == null && move.promotion != null) continue;

      // Check disambiguation
      if (disambig.isNotEmpty) {
        final fromNotation = ChessBoard.notationFromSquare(move.from);
        if (disambig.length == 1) {
          // Could be file (a-h) or rank (1-8)
          if (!fromNotation.contains(disambig)) continue;
        } else if (disambig.length == 2) {
          if (fromNotation != disambig) continue;
        }
      }

      return move;
    }

    return null;
  }

  static String _pieceChar(PieceType type) {
    switch (type) {
      case PieceType.king:
        return 'K';
      case PieceType.queen:
        return 'Q';
      case PieceType.rook:
        return 'R';
      case PieceType.bishop:
        return 'B';
      case PieceType.knight:
        return 'N';
      case PieceType.pawn:
        return '';
    }
  }

  static PieceType? _pieceTypeFromChar(String c) {
    switch (c.toUpperCase()) {
      case 'K':
        return PieceType.king;
      case 'Q':
        return PieceType.queen;
      case 'R':
        return PieceType.rook;
      case 'B':
        return PieceType.bishop;
      case 'N':
        return PieceType.knight;
      default:
        return null;
    }
  }

  /// Simple attack check without importing chess_rules to avoid circular dep.
  static bool _isSquareAttackedSimple(
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

    // Sliding pieces (bishop/queen diagonals, rook/queen straights)
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

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'promotion': promotion?.name,
        'isCastling': isCastling,
        'isEnPassant': isEnPassant,
      };

  factory ChessMove.fromJson(Map<String, dynamic> json) {
    return ChessMove(
      from: json['from'] as int,
      to: json['to'] as int,
      promotion: json['promotion'] != null
          ? PieceType.values.byName(json['promotion'] as String)
          : null,
      isCastling: json['isCastling'] as bool? ?? false,
      isEnPassant: json['isEnPassant'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChessMove &&
          from == other.from &&
          to == other.to &&
          promotion == other.promotion &&
          isCastling == other.isCastling &&
          isEnPassant == other.isEnPassant;

  @override
  int get hashCode =>
      from.hashCode ^
      to.hashCode ^
      promotion.hashCode ^
      isCastling.hashCode ^
      isEnPassant.hashCode;

  @override
  String toString() =>
      'ChessMove(${ChessBoard.notationFromSquare(from)}->${ChessBoard.notationFromSquare(to)}'
      '${promotion != null ? '=${promotion!.name}' : ''}'
      '${isCastling ? ' castle' : ''}'
      '${isEnPassant ? ' ep' : ''})';
}
