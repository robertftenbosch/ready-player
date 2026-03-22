import 'checkers_piece.dart';
import 'checkers_move.dart';

/// 10x10 international draughts board.
///
/// Uses standard square numbering 1-50 where:
///   Row 0 (top):    .  1  .  2  .  3  .  4  .  5
///   Row 1:          6  .  7  .  8  .  9  . 10  .
///   Row 2:          . 11  . 12  . 13  . 14  . 15
///   Row 3:         16  . 17  . 18  . 19  . 20  .
///   Row 4:          . 21  . 22  . 23  . 24  . 25
///   Row 5:         26  . 27  . 28  . 29  . 30  .
///   Row 6:          . 31  . 32  . 33  . 34  . 35
///   Row 7:         36  . 37  . 38  . 39  . 40  .
///   Row 8:          . 41  . 42  . 43  . 44  . 45
///   Row 9 (bottom): 46  . 47  . 48  . 49  . 50  .
///
/// Internal storage: `squares[0]` = square 1, `squares[49]` = square 50.
class CheckersBoard {
  /// 50 playable squares. Index 0 = square 1, index 49 = square 50.
  final List<CheckersPiece?> squares;

  CheckersBoard(this.squares) : assert(squares.length == 50);

  /// Initial setup: Black on 1-20 (top), White on 31-50 (bottom).
  factory CheckersBoard.initial() {
    final sq = List<CheckersPiece?>.filled(50, null);
    for (var i = 0; i < 20; i++) {
      sq[i] = const CheckersPiece(CheckersColor.black, CheckersPieceType.man);
    }
    for (var i = 30; i < 50; i++) {
      sq[i] = const CheckersPiece(CheckersColor.white, CheckersPieceType.man);
    }
    return CheckersBoard(sq);
  }

  /// Returns the piece on [squareNum] (1-50), or null if empty.
  CheckersPiece? pieceAt(int squareNum) {
    assert(squareNum >= 1 && squareNum <= 50);
    return squares[squareNum - 1];
  }

  CheckersBoard clone() => CheckersBoard(List<CheckersPiece?>.from(squares));

  /// Returns a new board with [move] applied.
  CheckersBoard applyMove(CheckersMove move) {
    final newSquares = List<CheckersPiece?>.from(squares);
    var piece = newSquares[move.from - 1]!;

    // Remove the moving piece from its origin.
    newSquares[move.from - 1] = null;

    // Remove captured pieces.
    for (final cap in move.captures) {
      newSquares[cap - 1] = null;
    }

    // Promotion: a man reaching the opposite back row becomes a king,
    // but only if the destination is the final landing square.
    if (piece.isMan) {
      if (piece.color == CheckersColor.white && _rowOfSquare(move.to) == 0) {
        piece = piece.promoted();
      } else if (piece.color == CheckersColor.black &&
          _rowOfSquare(move.to) == 9) {
        piece = piece.promoted();
      }
    }

    // Place piece at destination.
    newSquares[move.to - 1] = piece;

    return CheckersBoard(newSquares);
  }

  Map<String, dynamic> toJson() => {
        'squares': squares.map((p) => p?.toJson()).toList(),
      };

  factory CheckersBoard.fromJson(Map<String, dynamic> json) {
    final squaresList = (json['squares'] as List).map((s) {
      if (s == null) return null;
      return CheckersPiece.fromJson(Map<String, dynamic>.from(s as Map));
    }).toList();
    return CheckersBoard(squaresList);
  }

  // ── Coordinate helpers ──────────────────────────────────────────────

  /// Row (0-9) of a square number (1-50). Row 0 is top.
  static int _rowOfSquare(int sq) => (sq - 1) ~/ 5;

  /// Column (0-9) of a square number (1-50).
  static int _colOfSquare(int sq) {
    final row = _rowOfSquare(sq);
    final posInRow = (sq - 1) % 5; // 0..4
    if (row.isEven) {
      // Even rows (0,2,4,6,8): dark squares at cols 1,3,5,7,9
      return posInRow * 2 + 1;
    } else {
      // Odd rows (1,3,5,7,9): dark squares at cols 0,2,4,6,8
      return posInRow * 2;
    }
  }

  /// Row of a square (public).
  static int rowOf(int sq) => _rowOfSquare(sq);

  /// Column of a square (public).
  static int colOf(int sq) => _colOfSquare(sq);

  /// Convert (row, col) to square number, or null if not a playable square.
  static int? squareFromRowCol(int row, int col) {
    if (row < 0 || row > 9 || col < 0 || col > 9) return null;
    // Only dark squares are playable.
    if (row.isEven) {
      // Even rows: dark squares at odd columns.
      if (col.isOdd) {
        return row * 5 + (col ~/ 2) + 1;
      }
    } else {
      // Odd rows: dark squares at even columns.
      if (col.isEven) {
        return row * 5 + (col ~/ 2) + 1;
      }
    }
    return null;
  }

  // ── Piece counts ──────────────────────────────────────────────────

  int get whitePieceCount =>
      squares.where((p) => p != null && p.color == CheckersColor.white).length;

  int get blackPieceCount =>
      squares.where((p) => p != null && p.color == CheckersColor.black).length;

  /// All square numbers occupied by [color].
  List<int> squaresFor(CheckersColor color) {
    final result = <int>[];
    for (var i = 0; i < 50; i++) {
      if (squares[i] != null && squares[i]!.color == color) {
        result.add(i + 1);
      }
    }
    return result;
  }

  @override
  String toString() {
    final buf = StringBuffer();
    for (var row = 0; row < 10; row++) {
      for (var col = 0; col < 10; col++) {
        final sq = squareFromRowCol(row, col);
        if (sq == null) {
          buf.write(' . ');
        } else {
          final p = pieceAt(sq);
          if (p == null) {
            buf.write(' _ ');
          } else if (p.color == CheckersColor.white) {
            buf.write(p.isKing ? ' W ' : ' w ');
          } else {
            buf.write(p.isKing ? ' B ' : ' b ');
          }
        }
      }
      buf.writeln();
    }
    return buf.toString();
  }
}
