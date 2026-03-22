import '../models/checkers_board.dart';
import '../models/checkers_move.dart';
import '../models/checkers_piece.dart';

/// International 10x10 draughts rules engine.
///
/// Key rules:
/// - Men move diagonally forward one square.
/// - Men capture diagonally forward AND backward.
/// - Kings ("flying kings") move/capture any distance along a diagonal.
/// - Capture is mandatory. If multiple capture sequences exist, the player
///   must choose the one that captures the most pieces (maximum capture rule).
/// - Captured pieces are removed AFTER the complete multi-capture sequence.
/// - A man promotes to king ONLY if the back row is the final landing square
///   (not during a multi-capture pass-through).
/// - During a multi-capture, the same piece cannot be jumped twice.
class CheckersRules {
  CheckersRules._();

  /// All legal moves for [color] on the given [board], enforcing mandatory
  /// and maximum capture rules.
  static List<CheckersMove> generateLegalMoves(
    CheckersBoard board,
    CheckersColor color,
  ) {
    // First, gather all capture sequences.
    final captures = <CheckersMove>[];
    for (final sq in board.squaresFor(color)) {
      captures.addAll(_findCaptures(board, sq));
    }

    if (captures.isNotEmpty) {
      // Maximum capture rule: keep only sequences with the most captures.
      final maxCaptures =
          captures.map((m) => m.captureCount).reduce((a, b) => a > b ? a : b);
      return captures.where((m) => m.captureCount == maxCaptures).toList();
    }

    // No captures available – generate simple (non-capturing) moves.
    final simple = <CheckersMove>[];
    for (final sq in board.squaresFor(color)) {
      simple.addAll(_findSimpleMoves(board, sq));
    }
    return simple;
  }

  /// Legal moves from a specific [square], filtered according to mandatory /
  /// maximum capture rules applied globally.
  static List<CheckersMove> generateLegalMovesFromSquare(
    CheckersBoard board,
    int square,
  ) {
    final piece = board.pieceAt(square);
    if (piece == null) return [];

    final allLegal = generateLegalMoves(board, piece.color);
    return allLegal.where((m) => m.from == square).toList();
  }

  /// Returns true if [color] has won (opponent has no pieces or no moves).
  static bool hasWon(CheckersBoard board, CheckersColor color) {
    final opponent =
        color == CheckersColor.white ? CheckersColor.black : CheckersColor.white;
    if (board.squaresFor(opponent).isEmpty) return true;
    if (generateLegalMoves(board, opponent).isEmpty) return true;
    return false;
  }

  /// Returns true if the position is a draw (neither side can move).
  static bool isDraw(CheckersBoard board) {
    return generateLegalMoves(board, CheckersColor.white).isEmpty &&
        generateLegalMoves(board, CheckersColor.black).isEmpty;
  }

  // ── Simple (non-capturing) moves ────────────────────────────────────

  static List<CheckersMove> _findSimpleMoves(CheckersBoard board, int square) {
    final piece = board.pieceAt(square);
    if (piece == null) return [];

    final moves = <CheckersMove>[];
    final row = CheckersBoard.rowOf(square);
    final col = CheckersBoard.colOf(square);

    if (piece.isMan) {
      // Men move diagonally forward one square.
      final directions = piece.color == CheckersColor.white
          ? [(-1, -1), (-1, 1)] // white moves up
          : [(1, -1), (1, 1)]; // black moves down
      for (final (dr, dc) in directions) {
        final nr = row + dr;
        final nc = col + dc;
        final target = CheckersBoard.squareFromRowCol(nr, nc);
        if (target != null && board.pieceAt(target) == null) {
          moves.add(CheckersMove(from: square, to: target));
        }
      }
    } else {
      // Flying king: any distance along diagonals.
      for (final (dr, dc) in _diagonals) {
        var r = row + dr;
        var c = col + dc;
        while (r >= 0 && r <= 9 && c >= 0 && c <= 9) {
          final target = CheckersBoard.squareFromRowCol(r, c);
          if (target == null) break; // shouldn't happen on dark squares
          if (board.pieceAt(target) != null) break; // blocked
          moves.add(CheckersMove(from: square, to: target));
          r += dr;
          c += dc;
        }
      }
    }

    return moves;
  }

  // ── Capture sequences (DFS) ─────────────────────────────────────────

  static const _diagonals = [(-1, -1), (-1, 1), (1, -1), (1, 1)];

  /// Find all maximal capture sequences starting from [square].
  static List<CheckersMove> _findCaptures(CheckersBoard board, int square) {
    final piece = board.pieceAt(square);
    if (piece == null) return [];

    final results = <CheckersMove>[];
    _capturesDFS(
      board: board,
      piece: piece,
      currentSquare: square,
      startSquare: square,
      captured: [],
      path: [],
      results: results,
    );

    if (results.isEmpty) return [];

    // Keep only the longest capture sequences from this piece.
    final maxLen =
        results.map((m) => m.captureCount).reduce((a, b) => a > b ? a : b);
    return results.where((m) => m.captureCount == maxLen).toList();
  }

  /// Recursive DFS to enumerate all possible capture sequences.
  static void _capturesDFS({
    required CheckersBoard board,
    required CheckersPiece piece,
    required int currentSquare,
    required int startSquare,
    required List<int> captured,
    required List<int> path,
    required List<CheckersMove> results,
  }) {
    final row = CheckersBoard.rowOf(currentSquare);
    final col = CheckersBoard.colOf(currentSquare);
    bool foundMore = false;

    if (piece.isMan) {
      // Men can capture in all four diagonal directions.
      for (final (dr, dc) in _diagonals) {
        final midR = row + dr;
        final midC = col + dc;
        final midSq = CheckersBoard.squareFromRowCol(midR, midC);
        if (midSq == null) continue;

        final midPiece = board.pieceAt(midSq);
        if (midPiece == null || midPiece.color == piece.color) continue;
        if (captured.contains(midSq)) continue; // already captured this piece

        final landR = midR + dr;
        final landC = midC + dc;
        final landSq = CheckersBoard.squareFromRowCol(landR, landC);
        if (landSq == null) continue;
        if (board.pieceAt(landSq) != null && landSq != startSquare) continue;

        foundMore = true;
        captured.add(midSq);
        path.add(landSq);

        _capturesDFS(
          board: board,
          piece: piece,
          currentSquare: landSq,
          startSquare: startSquare,
          captured: captured,
          path: path,
          results: results,
        );

        path.removeLast();
        captured.removeLast();
      }
    } else {
      // Flying king captures: travel along diagonal, jump over exactly one
      // opponent piece, then can land on any empty square beyond it.
      for (final (dr, dc) in _diagonals) {
        var r = row + dr;
        var c = col + dc;
        int? enemySq;

        // Travel along the diagonal looking for an opponent piece to jump.
        while (r >= 0 && r <= 9 && c >= 0 && c <= 9) {
          final sq = CheckersBoard.squareFromRowCol(r, c);
          if (sq == null) break;

          final p = board.pieceAt(sq);
          if (p != null) {
            if (p.color == piece.color) break; // own piece blocks
            if (captured.contains(sq)) {
              // Already captured – cannot jump again, but can pass over the
              // square (the piece is "pending removal").
              r += dr;
              c += dc;
              continue;
            }
            if (enemySq != null) break; // two enemy pieces in a row – blocked
            enemySq = sq;
          } else if (sq == startSquare && captured.isNotEmpty) {
            // The starting square is treated as empty during multi-capture.
            if (enemySq == null) {
              r += dr;
              c += dc;
              continue;
            }
          }

          if (enemySq != null && p == null) {
            // We have jumped over an enemy piece and found an empty landing.
            foundMore = true;
            captured.add(enemySq);
            path.add(sq);

            _capturesDFS(
              board: board,
              piece: piece,
              currentSquare: sq,
              startSquare: startSquare,
              captured: captured,
              path: path,
              results: results,
            );

            path.removeLast();
            captured.removeLast();
          } else if (enemySq != null && p != null) {
            // A second piece blocks landing.
            break;
          }

          r += dr;
          c += dc;
        }
      }
    }

    // If no further captures were found, record the sequence (if non-empty).
    if (!foundMore && captured.isNotEmpty) {
      results.add(CheckersMove(
        from: startSquare,
        to: currentSquare,
        captures: List<int>.from(captured),
        path: path.length > 1
            ? List<int>.from(path.sublist(0, path.length - 1))
            : const [],
      ));
    }
  }
}
