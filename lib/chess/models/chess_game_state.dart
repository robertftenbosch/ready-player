import '../../core/models/game_mode.dart';
import 'chess_board.dart';
import 'chess_move.dart';
import 'chess_piece.dart';
import '../logic/chess_move_generator.dart';

enum GamePhase { playerTurn, llmThinking, gameOver }

enum GameResult { playerWins, llmWins, draw }

class ChessGameState {
  final ChessBoard board;
  final GamePhase phase;
  final GameResult? result;
  final List<ChessMove> moveHistory;
  final List<String> moveNotations;
  final GameMode gameMode;

  const ChessGameState({
    required this.board,
    required this.phase,
    this.result,
    this.moveHistory = const [],
    this.moveNotations = const [],
    this.gameMode = GameMode.vsAi,
  });

  factory ChessGameState.initial({GameMode gameMode = GameMode.vsAi}) {
    return ChessGameState(
      board: ChessBoard.initial(),
      phase: GamePhase.playerTurn,
      gameMode: gameMode,
    );
  }

  bool get isPlayerTurn => phase == GamePhase.playerTurn;

  String get statusText {
    switch (phase) {
      case GamePhase.playerTurn:
        if (gameMode == GameMode.vsPlayer) {
          return board.activeColor == PieceColor.white
              ? "White's turn"
              : "Black's turn";
        }
        return 'Your turn (White)';
      case GamePhase.llmThinking:
        return 'LLM is thinking...';
      case GamePhase.gameOver:
        switch (result) {
          case GameResult.playerWins:
            if (gameMode == GameMode.vsPlayer) {
              return 'Checkmate! White wins!';
            }
            return 'Checkmate! You win!';
          case GameResult.llmWins:
            if (gameMode == GameMode.vsPlayer) {
              return 'Checkmate! Black wins!';
            }
            return 'Checkmate! LLM wins!';
          case GameResult.draw:
            return 'Game drawn!';
          case null:
            return 'Game over';
        }
    }
  }

  List<ChessMove> getLegalMovesFrom(int square) {
    if (phase != GamePhase.playerTurn) return [];
    final piece = board.pieceAt(square);
    if (piece == null) return [];
    if (gameMode == GameMode.vsPlayer) {
      if (piece.color != board.activeColor) return [];
    } else {
      if (piece.color != PieceColor.white) return [];
    }
    return ChessMoveGenerator.generateLegalMovesFromSquare(board, square);
  }

  Map<String, dynamic> toJson() => {
        'board': board.toJson(),
        'phase': phase == GamePhase.llmThinking ? GamePhase.playerTurn.name : phase.name,
        'result': result?.name,
        'moveHistory': moveHistory.map((m) => m.toJson()).toList(),
        'moveNotations': moveNotations,
        'gameMode': gameMode.name,
      };

  factory ChessGameState.fromJson(Map<String, dynamic> json) {
    return ChessGameState(
      board: ChessBoard.fromJson(Map<String, dynamic>.from(json['board'] as Map)),
      phase: GamePhase.values.byName(json['phase'] as String),
      result: json['result'] != null
          ? GameResult.values.byName(json['result'] as String)
          : null,
      moveHistory: (json['moveHistory'] as List)
          .map((m) => ChessMove.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList(),
      moveNotations: (json['moveNotations'] as List).cast<String>(),
      gameMode: GameMode.values.byName(json['gameMode'] as String),
    );
  }

  ChessGameState copyWith({
    ChessBoard? board,
    GamePhase? phase,
    GameResult? result,
    List<ChessMove>? moveHistory,
    List<String>? moveNotations,
    GameMode? gameMode,
  }) {
    return ChessGameState(
      board: board ?? this.board,
      phase: phase ?? this.phase,
      result: result ?? this.result,
      moveHistory: moveHistory ?? this.moveHistory,
      moveNotations: moveNotations ?? this.moveNotations,
      gameMode: gameMode ?? this.gameMode,
    );
  }
}
