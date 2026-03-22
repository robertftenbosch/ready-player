import 'chess_piece.dart';
import 'chess_move.dart';

class ChessBoard {
  final List<ChessPiece?> squares;
  final PieceColor activeColor;
  final bool whiteKingSide;
  final bool whiteQueenSide;
  final bool blackKingSide;
  final bool blackQueenSide;
  final int? enPassantSquare;
  final int halfMoveClock;
  final int fullMoveNumber;

  const ChessBoard({
    required this.squares,
    required this.activeColor,
    this.whiteKingSide = true,
    this.whiteQueenSide = true,
    this.blackKingSide = true,
    this.blackQueenSide = true,
    this.enPassantSquare,
    this.halfMoveClock = 0,
    this.fullMoveNumber = 1,
  });

  factory ChessBoard.initial() {
    final squares = List<ChessPiece?>.filled(64, null);

    // White pieces (rank 1)
    squares[0] = const ChessPiece(PieceType.rook, PieceColor.white);
    squares[1] = const ChessPiece(PieceType.knight, PieceColor.white);
    squares[2] = const ChessPiece(PieceType.bishop, PieceColor.white);
    squares[3] = const ChessPiece(PieceType.queen, PieceColor.white);
    squares[4] = const ChessPiece(PieceType.king, PieceColor.white);
    squares[5] = const ChessPiece(PieceType.bishop, PieceColor.white);
    squares[6] = const ChessPiece(PieceType.knight, PieceColor.white);
    squares[7] = const ChessPiece(PieceType.rook, PieceColor.white);

    // White pawns (rank 2)
    for (int i = 8; i < 16; i++) {
      squares[i] = const ChessPiece(PieceType.pawn, PieceColor.white);
    }

    // Black pawns (rank 7)
    for (int i = 48; i < 56; i++) {
      squares[i] = const ChessPiece(PieceType.pawn, PieceColor.black);
    }

    // Black pieces (rank 8)
    squares[56] = const ChessPiece(PieceType.rook, PieceColor.black);
    squares[57] = const ChessPiece(PieceType.knight, PieceColor.black);
    squares[58] = const ChessPiece(PieceType.bishop, PieceColor.black);
    squares[59] = const ChessPiece(PieceType.queen, PieceColor.black);
    squares[60] = const ChessPiece(PieceType.king, PieceColor.black);
    squares[61] = const ChessPiece(PieceType.bishop, PieceColor.black);
    squares[62] = const ChessPiece(PieceType.knight, PieceColor.black);
    squares[63] = const ChessPiece(PieceType.rook, PieceColor.black);

    return ChessBoard(squares: squares, activeColor: PieceColor.white);
  }

  ChessPiece? pieceAt(int square) {
    if (square < 0 || square > 63) return null;
    return squares[square];
  }

  ChessBoard clone() {
    return ChessBoard(
      squares: List<ChessPiece?>.from(squares),
      activeColor: activeColor,
      whiteKingSide: whiteKingSide,
      whiteQueenSide: whiteQueenSide,
      blackKingSide: blackKingSide,
      blackQueenSide: blackQueenSide,
      enPassantSquare: enPassantSquare,
      halfMoveClock: halfMoveClock,
      fullMoveNumber: fullMoveNumber,
    );
  }

  ChessBoard applyMove(ChessMove move) {
    final newSquares = List<ChessPiece?>.from(squares);
    final piece = newSquares[move.from];
    if (piece == null) return this;

    bool newWhiteKingSide = whiteKingSide;
    bool newWhiteQueenSide = whiteQueenSide;
    bool newBlackKingSide = blackKingSide;
    bool newBlackQueenSide = blackQueenSide;
    int? newEnPassant;
    int newHalfMove = halfMoveClock + 1;
    int newFullMove = fullMoveNumber;

    // Reset half-move clock on pawn move or capture
    if (piece.type == PieceType.pawn || newSquares[move.to] != null) {
      newHalfMove = 0;
    }

    // Handle castling
    if (move.isCastling) {
      newSquares[move.to] = piece;
      newSquares[move.from] = null;

      // Move the rook
      if (move.to == 6) {
        // White king-side
        newSquares[5] = newSquares[7];
        newSquares[7] = null;
      } else if (move.to == 2) {
        // White queen-side
        newSquares[3] = newSquares[0];
        newSquares[0] = null;
      } else if (move.to == 62) {
        // Black king-side
        newSquares[61] = newSquares[63];
        newSquares[63] = null;
      } else if (move.to == 58) {
        // Black queen-side
        newSquares[59] = newSquares[56];
        newSquares[56] = null;
      }
    } else if (move.isEnPassant) {
      // En passant: remove the captured pawn
      newSquares[move.to] = piece;
      newSquares[move.from] = null;
      // The captured pawn is on the same file as `to` but on the rank of `from`
      final capturedPawnSquare = (move.from ~/ 8) * 8 + (move.to % 8);
      newSquares[capturedPawnSquare] = null;
      newHalfMove = 0;
    } else if (move.promotion != null) {
      // Promotion
      newSquares[move.to] = ChessPiece(move.promotion!, piece.color);
      newSquares[move.from] = null;
      newHalfMove = 0;
    } else {
      // Normal move
      newSquares[move.to] = piece;
      newSquares[move.from] = null;
    }

    // Update castling rights
    if (piece.type == PieceType.king) {
      if (piece.color == PieceColor.white) {
        newWhiteKingSide = false;
        newWhiteQueenSide = false;
      } else {
        newBlackKingSide = false;
        newBlackQueenSide = false;
      }
    }
    if (piece.type == PieceType.rook) {
      if (move.from == 0) newWhiteQueenSide = false;
      if (move.from == 7) newWhiteKingSide = false;
      if (move.from == 56) newBlackQueenSide = false;
      if (move.from == 63) newBlackKingSide = false;
    }
    // Also revoke if rook is captured
    if (move.to == 0) newWhiteQueenSide = false;
    if (move.to == 7) newWhiteKingSide = false;
    if (move.to == 56) newBlackQueenSide = false;
    if (move.to == 63) newBlackKingSide = false;

    // Set en passant square for double pawn push
    if (piece.type == PieceType.pawn) {
      final diff = (move.to - move.from).abs();
      if (diff == 16) {
        newEnPassant = (move.from + move.to) ~/ 2;
      }
    }

    // Update full move number
    if (activeColor == PieceColor.black) {
      newFullMove++;
    }

    return ChessBoard(
      squares: newSquares,
      activeColor:
          activeColor == PieceColor.white ? PieceColor.black : PieceColor.white,
      whiteKingSide: newWhiteKingSide,
      whiteQueenSide: newWhiteQueenSide,
      blackKingSide: newBlackKingSide,
      blackQueenSide: newBlackQueenSide,
      enPassantSquare: newEnPassant,
      halfMoveClock: newHalfMove,
      fullMoveNumber: newFullMove,
    );
  }

  /// Converts square notation like "e4" to index (e.g., 28).
  static int squareFromNotation(String notation) {
    if (notation.length != 2) return -1;
    final col = notation.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = notation.codeUnitAt(1) - '1'.codeUnitAt(0);
    if (col < 0 || col > 7 || row < 0 || row > 7) return -1;
    return row * 8 + col;
  }

  /// Converts square index to notation (e.g., 28 -> "e4").
  static String notationFromSquare(int square) {
    final col = square % 8;
    final row = square ~/ 8;
    return '${String.fromCharCode('a'.codeUnitAt(0) + col)}${row + 1}';
  }

  Map<String, dynamic> toJson() => {
        'squares': squares.map((p) => p?.toJson()).toList(),
        'activeColor': activeColor.name,
        'whiteKingSide': whiteKingSide,
        'whiteQueenSide': whiteQueenSide,
        'blackKingSide': blackKingSide,
        'blackQueenSide': blackQueenSide,
        'enPassantSquare': enPassantSquare,
        'halfMoveClock': halfMoveClock,
        'fullMoveNumber': fullMoveNumber,
      };

  factory ChessBoard.fromJson(Map<String, dynamic> json) {
    final squaresList = (json['squares'] as List).map((s) {
      if (s == null) return null;
      return ChessPiece.fromJson(Map<String, dynamic>.from(s as Map));
    }).toList();

    return ChessBoard(
      squares: squaresList,
      activeColor: PieceColor.values.byName(json['activeColor'] as String),
      whiteKingSide: json['whiteKingSide'] as bool? ?? true,
      whiteQueenSide: json['whiteQueenSide'] as bool? ?? true,
      blackKingSide: json['blackKingSide'] as bool? ?? true,
      blackQueenSide: json['blackQueenSide'] as bool? ?? true,
      enPassantSquare: json['enPassantSquare'] as int?,
      halfMoveClock: json['halfMoveClock'] as int? ?? 0,
      fullMoveNumber: json['fullMoveNumber'] as int? ?? 1,
    );
  }

  /// Find the king square for the given color.
  int findKing(PieceColor color) {
    for (int i = 0; i < 64; i++) {
      final p = squares[i];
      if (p != null && p.type == PieceType.king && p.color == color) {
        return i;
      }
    }
    return -1;
  }
}
