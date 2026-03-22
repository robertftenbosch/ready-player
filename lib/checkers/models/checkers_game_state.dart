import 'checkers_board.dart';
import 'checkers_move.dart';
import 'checkers_piece.dart';
import '../logic/checkers_rules.dart';
import '../../core/models/game_mode.dart';

enum CheckersPhase { playerTurn, llmThinking, gameOver }

enum CheckersResult { playerWins, llmWins, draw }

class CheckersGameState {
  final CheckersBoard board;
  final CheckersPhase phase;
  final CheckersResult? result;
  final List<CheckersMove> moveHistory;
  final List<String> moveNotations;
  final GameMode gameMode;
  final CheckersColor currentTurn;

  const CheckersGameState({
    required this.board,
    required this.phase,
    this.result,
    this.moveHistory = const [],
    this.moveNotations = const [],
    this.gameMode = GameMode.vsAi,
    this.currentTurn = CheckersColor.white,
  });

  factory CheckersGameState.initial({GameMode gameMode = GameMode.vsAi}) =>
      CheckersGameState(
        board: CheckersBoard.initial(),
        phase: CheckersPhase.playerTurn,
        gameMode: gameMode,
        currentTurn: CheckersColor.white,
      );

  bool get isPlayerTurn {
    if (gameMode == GameMode.vsPlayer) {
      return phase == CheckersPhase.playerTurn;
    }
    return phase == CheckersPhase.playerTurn;
  }

  bool get isGameOver => phase == CheckersPhase.gameOver;

  String get statusText {
    if (gameMode == GameMode.vsPlayer) {
      switch (phase) {
        case CheckersPhase.playerTurn:
          return currentTurn == CheckersColor.white
              ? "WHITE'S TURN"
              : "BLACK'S TURN";
        case CheckersPhase.llmThinking:
          return 'THINKING...';
        case CheckersPhase.gameOver:
          switch (result) {
            case CheckersResult.playerWins:
              return 'WHITE WINS!';
            case CheckersResult.llmWins:
              return 'BLACK WINS!';
            case CheckersResult.draw:
              return 'DRAW';
            case null:
              return 'GAME OVER';
          }
      }
    }
    switch (phase) {
      case CheckersPhase.playerTurn:
        return 'YOUR TURN (WHITE)';
      case CheckersPhase.llmThinking:
        return 'LLM THINKING...';
      case CheckersPhase.gameOver:
        switch (result) {
          case CheckersResult.playerWins:
            return 'YOU WIN!';
          case CheckersResult.llmWins:
            return 'LLM WINS!';
          case CheckersResult.draw:
            return 'DRAW';
          case null:
            return 'GAME OVER';
        }
    }
  }

  /// Returns the subset of legal moves originating from [square] for the
  /// current player. In vsAi mode, only White moves are returned. In vsPlayer
  /// mode, moves for whichever color's turn it is are returned.
  List<CheckersMove> getLegalMovesFrom(int square) {
    if (!isPlayerTurn) return [];
    final piece = board.pieceAt(square);
    if (piece == null) return [];

    final activeColor =
        gameMode == GameMode.vsPlayer ? currentTurn : CheckersColor.white;
    if (piece.color != activeColor) return [];

    return CheckersRules.generateLegalMovesFromSquare(board, square);
  }

  Map<String, dynamic> toJson() => {
        'board': board.toJson(),
        'phase': phase == CheckersPhase.llmThinking
            ? CheckersPhase.playerTurn.name
            : phase.name,
        'result': result?.name,
        'moveHistory': moveHistory.map((m) => m.toJson()).toList(),
        'moveNotations': moveNotations,
        'gameMode': gameMode.name,
        'currentTurn': currentTurn.name,
      };

  factory CheckersGameState.fromJson(Map<String, dynamic> json) {
    return CheckersGameState(
      board: CheckersBoard.fromJson(
          Map<String, dynamic>.from(json['board'] as Map)),
      phase: CheckersPhase.values.byName(json['phase'] as String),
      result: json['result'] != null
          ? CheckersResult.values.byName(json['result'] as String)
          : null,
      moveHistory: (json['moveHistory'] as List)
          .map((m) =>
              CheckersMove.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList(),
      moveNotations: (json['moveNotations'] as List).cast<String>(),
      gameMode: GameMode.values.byName(json['gameMode'] as String),
      currentTurn:
          CheckersColor.values.byName(json['currentTurn'] as String),
    );
  }

  CheckersGameState copyWith({
    CheckersBoard? board,
    CheckersPhase? phase,
    CheckersResult? result,
    List<CheckersMove>? moveHistory,
    List<String>? moveNotations,
    GameMode? gameMode,
    CheckersColor? currentTurn,
  }) {
    return CheckersGameState(
      board: board ?? this.board,
      phase: phase ?? this.phase,
      result: result ?? this.result,
      moveHistory: moveHistory ?? this.moveHistory,
      moveNotations: moveNotations ?? this.moveNotations,
      gameMode: gameMode ?? this.gameMode,
      currentTurn: currentTurn ?? this.currentTurn,
    );
  }
}
