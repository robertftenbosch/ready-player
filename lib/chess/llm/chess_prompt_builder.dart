import '../logic/chess_fen_parser.dart';
import '../logic/chess_move_generator.dart';
import '../models/chess_game_state.dart';
import '../models/chess_piece.dart';

class ChessPromptBuilder {
  ChessPromptBuilder._();

  /// Builds a prompt for the LLM to generate a chess move.
  static String buildPrompt(ChessGameState state) {
    final fen = ChessFenParser.toFen(state.board);

    // Build move history string
    final moveHistoryStr = StringBuffer();
    for (int i = 0; i < state.moveNotations.length; i += 2) {
      final moveNum = (i ~/ 2) + 1;
      moveHistoryStr.write('$moveNum. ${state.moveNotations[i]}');
      if (i + 1 < state.moveNotations.length) {
        moveHistoryStr.write(' ${state.moveNotations[i + 1]}');
      }
      moveHistoryStr.write(' ');
    }

    // Generate all legal moves for Black
    final legalMoves =
        ChessMoveGenerator.generateLegalMoves(state.board, PieceColor.black);
    final legalMovesNotations = <String>{};
    for (final move in legalMoves) {
      legalMovesNotations.add(move.toAlgebraic(state.board));
    }
    final legalMovesStr = legalMovesNotations.join(', ');

    return '''You are playing chess as Black. Analyze the position and choose the best move.

Current position (FEN): $fen

Move history: ${moveHistoryStr.toString().trim()}

Legal moves available: $legalMovesStr

Respond with ONLY the move in standard algebraic notation (e.g., "Nf6", "e5", "O-O"). Do not include any explanation, commentary, or additional text. Just the move.

Your move:''';
  }
}
