import '../models/checkers_board.dart';
import '../models/checkers_game_state.dart';
import '../models/checkers_piece.dart';
import '../logic/checkers_rules.dart';

class CheckersPromptBuilder {
  CheckersPromptBuilder._();

  /// Builds a prompt for the LLM to choose a move as Black.
  static String buildPrompt(CheckersGameState state) {
    final board = state.board;
    final buf = StringBuffer();

    buf.writeln('You are playing International Draughts (10x10) as Black.');
    buf.writeln('Standard square numbering 1-50 is used.');
    buf.writeln();

    // Describe piece positions.
    buf.writeln('Current position:');
    _describePieces(buf, board, CheckersColor.black, 'Black');
    _describePieces(buf, board, CheckersColor.white, 'White');
    buf.writeln();

    // Move history.
    if (state.moveNotations.isNotEmpty) {
      buf.writeln('Move history: ${state.moveNotations.join(", ")}');
      buf.writeln();
    }

    // Legal moves.
    final legalMoves =
        CheckersRules.generateLegalMoves(board, CheckersColor.black);
    buf.writeln('Your legal moves:');
    for (var i = 0; i < legalMoves.length; i++) {
      buf.writeln('  ${i + 1}. ${legalMoves[i].toNotation()}');
    }
    buf.writeln();

    buf.writeln(
      'Choose the best move. Reply with ONLY the move in notation '
      '(e.g. "16-21" or "16x27x38"). Do not include any other text.',
    );

    return buf.toString();
  }

  static void _describePieces(
    StringBuffer buf,
    CheckersBoard board,
    CheckersColor color,
    String label,
  ) {
    final squares = board.squaresFor(color);
    final men = <int>[];
    final kings = <int>[];
    for (final sq in squares) {
      final piece = board.pieceAt(sq);
      if (piece != null && piece.isKing) {
        kings.add(sq);
      } else {
        men.add(sq);
      }
    }
    buf.write('  $label men: ');
    buf.writeln(men.isEmpty ? 'none' : men.join(', '));
    if (kings.isNotEmpty) {
      buf.writeln('  $label kings: ${kings.join(', ')}');
    }
  }
}
