import '../models/ballerburg_game_state.dart';

class BallerburgPromptBuilder {
  static String buildPrompt(BallerburgGameState state) {
    final playerCastle = state.leftCastle;
    final llmCastle = state.rightCastle;
    final distance = (llmCastle.x - playerCastle.x).abs();
    final wind = state.wind;

    final recentShots = state.shotHistory
        .where((s) => !s.isPlayer)
        .toList()
        .reversed
        .take(3)
        .toList();

    final shotHistoryText = recentShots.isEmpty
        ? 'No previous shots.'
        : recentShots
            .map((s) =>
                'ANGLE=${s.angle.toStringAsFixed(1)} POWDER=${s.powder.toStringAsFixed(1)} -> hit at (${s.hitPoint?.dx.toStringAsFixed(0) ?? "miss"}, ${s.hitPoint?.dy.toStringAsFixed(0) ?? "miss"})')
            .join('\n');

    return '''You are the AI cannon operator in a Ballerburg artillery game.
You are on the RIGHT side, firing LEFT at the enemy castle.

GAME STATE:
- Your castle health: ${(llmCastle.health * 100).toStringAsFixed(0)}%
- Enemy castle health: ${(playerCastle.health * 100).toStringAsFixed(0)}%
- Distance between castles: ${distance.toStringAsFixed(0)} pixels
- Wind: ${wind.description}
- Enemy castle center X: ${playerCastle.x.toStringAsFixed(0)}
- Your castle center X: ${llmCastle.x.toStringAsFixed(0)}
- Canvas width: ${state.canvasWidth.toStringAsFixed(0)}
- Canvas height: ${state.canvasHeight.toStringAsFixed(0)}

YOUR RECENT SHOTS:
$shotHistoryText

Choose an angle (20-80 degrees) and powder (10-100).
Higher angle = more arc. Higher powder = more force.
Wind positive = pushes right, negative = pushes left.
You are firing LEFT, so wind pushing left helps you.

Respond with EXACTLY this format, nothing else:
ANGLE=XX POWDER=YY''';
  }
}
