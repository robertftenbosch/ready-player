import '../models/chess_board.dart';
import '../models/chess_piece.dart';

class ChessFenParser {
  ChessFenParser._();

  /// Converts a ChessBoard to a FEN string.
  static String toFen(ChessBoard board) {
    final buffer = StringBuffer();

    // Piece placement (rank 8 to rank 1)
    for (int rank = 7; rank >= 0; rank--) {
      int emptyCount = 0;
      for (int file = 0; file < 8; file++) {
        final piece = board.pieceAt(rank * 8 + file);
        if (piece == null) {
          emptyCount++;
        } else {
          if (emptyCount > 0) {
            buffer.write(emptyCount);
            emptyCount = 0;
          }
          buffer.write(_pieceToFenChar(piece));
        }
      }
      if (emptyCount > 0) buffer.write(emptyCount);
      if (rank > 0) buffer.write('/');
    }

    // Active color
    buffer.write(' ');
    buffer.write(board.activeColor == PieceColor.white ? 'w' : 'b');

    // Castling availability
    buffer.write(' ');
    String castling = '';
    if (board.whiteKingSide) castling += 'K';
    if (board.whiteQueenSide) castling += 'Q';
    if (board.blackKingSide) castling += 'k';
    if (board.blackQueenSide) castling += 'q';
    buffer.write(castling.isEmpty ? '-' : castling);

    // En passant
    buffer.write(' ');
    if (board.enPassantSquare != null) {
      buffer.write(ChessBoard.notationFromSquare(board.enPassantSquare!));
    } else {
      buffer.write('-');
    }

    // Half-move clock
    buffer.write(' ${board.halfMoveClock}');

    // Full move number
    buffer.write(' ${board.fullMoveNumber}');

    return buffer.toString();
  }

  /// Parses a FEN string into a ChessBoard.
  static ChessBoard fromFen(String fen) {
    final parts = fen.trim().split(RegExp(r'\s+'));
    if (parts.length < 4) {
      throw FormatException('Invalid FEN: $fen');
    }

    // Parse piece placement
    final squares = List<ChessPiece?>.filled(64, null);
    final ranks = parts[0].split('/');
    if (ranks.length != 8) {
      throw FormatException('Invalid FEN piece placement: ${parts[0]}');
    }

    for (int rank = 0; rank < 8; rank++) {
      int file = 0;
      for (final c in ranks[7 - rank].split('')) {
        if (int.tryParse(c) != null) {
          file += int.parse(c);
        } else {
          squares[rank * 8 + file] = _fenCharToPiece(c);
          file++;
        }
      }
    }

    // Active color
    final activeColor =
        parts[1] == 'b' ? PieceColor.black : PieceColor.white;

    // Castling
    final castling = parts[2];
    final whiteKingSide = castling.contains('K');
    final whiteQueenSide = castling.contains('Q');
    final blackKingSide = castling.contains('k');
    final blackQueenSide = castling.contains('q');

    // En passant
    int? enPassant;
    if (parts[3] != '-') {
      enPassant = ChessBoard.squareFromNotation(parts[3]);
      if (enPassant < 0) enPassant = null;
    }

    // Half-move and full-move
    final halfMove = parts.length > 4 ? int.tryParse(parts[4]) ?? 0 : 0;
    final fullMove = parts.length > 5 ? int.tryParse(parts[5]) ?? 1 : 1;

    return ChessBoard(
      squares: squares,
      activeColor: activeColor,
      whiteKingSide: whiteKingSide,
      whiteQueenSide: whiteQueenSide,
      blackKingSide: blackKingSide,
      blackQueenSide: blackQueenSide,
      enPassantSquare: enPassant,
      halfMoveClock: halfMove,
      fullMoveNumber: fullMove,
    );
  }

  static String _pieceToFenChar(ChessPiece piece) {
    String c;
    switch (piece.type) {
      case PieceType.pawn:
        c = 'p';
      case PieceType.knight:
        c = 'n';
      case PieceType.bishop:
        c = 'b';
      case PieceType.rook:
        c = 'r';
      case PieceType.queen:
        c = 'q';
      case PieceType.king:
        c = 'k';
    }
    return piece.color == PieceColor.white ? c.toUpperCase() : c;
  }

  static ChessPiece? _fenCharToPiece(String c) {
    final color =
        c.toUpperCase() == c ? PieceColor.white : PieceColor.black;
    switch (c.toLowerCase()) {
      case 'p':
        return ChessPiece(PieceType.pawn, color);
      case 'n':
        return ChessPiece(PieceType.knight, color);
      case 'b':
        return ChessPiece(PieceType.bishop, color);
      case 'r':
        return ChessPiece(PieceType.rook, color);
      case 'q':
        return ChessPiece(PieceType.queen, color);
      case 'k':
        return ChessPiece(PieceType.king, color);
      default:
        return null;
    }
  }
}
