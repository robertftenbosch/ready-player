/// Utilities for parsing LLM responses into game moves.
class LlmResponseParser {
  LlmResponseParser._();

  /// Extracts the first line from a response, trimmed.
  static String firstLine(String response) {
    return response.trim().split('\n').first.trim();
  }

  /// Tries to match a chess move from the response.
  /// Returns null if no valid pattern found.
  static String? parseChessMove(String response) {
    final line = firstLine(response);
    // Standard algebraic notation: e4, Nf3, O-O, O-O-O, exd5, Qh4+, e8=Q
    final regex = RegExp(
      r'\b(O-O-O|O-O|[KQRBN]?[a-h]?[1-8]?x?[a-h][1-8](?:=[QRBN])?[+#]?)\b',
    );
    final match = regex.firstMatch(line);
    return match?.group(1);
  }

  /// Tries to parse a checkers move (e.g., "16-21" or "16x27x38").
  static String? parseCheckersMove(String response) {
    final line = firstLine(response);
    final regex = RegExp(r'\b(\d{1,2}(?:[x-]\d{1,2})+)\b');
    final match = regex.firstMatch(line);
    return match?.group(1);
  }

  /// Tries to parse Ballerburg angle and powder.
  /// Returns (angle, powder) or null.
  static ({int angle, int powder})? parseBallerburgShot(String response) {
    final line = firstLine(response);
    final regex = RegExp(r'ANGLE\s*=\s*(\d+)\s+POWDER\s*=\s*(\d+)', caseSensitive: false);
    final match = regex.firstMatch(line);
    if (match == null) return null;
    final angle = int.tryParse(match.group(1)!);
    final powder = int.tryParse(match.group(2)!);
    if (angle == null || powder == null) return null;
    return (angle: angle.clamp(20, 80), powder: powder.clamp(10, 100));
  }
}
