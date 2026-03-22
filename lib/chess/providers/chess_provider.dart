import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/sound_service.dart';
import '../../core/models/game_mode.dart';
import '../../core/llm/llm_service.dart';
import '../../core/persistence/game_save_service.dart';
import '../llm/chess_prompt_builder.dart';
import '../logic/chess_move_generator.dart';
import '../logic/chess_rules.dart';
import '../models/chess_board.dart';
import '../models/chess_game_state.dart';
import '../models/chess_move.dart';
import '../models/chess_piece.dart';

class ChessGameNotifier extends Notifier<ChessGameState> {
  final List<ChessGameState> _history = [];
  final List<ChessGameState> _redoStack = [];

  @override
  ChessGameState build() {
    return ChessGameState.initial();
  }

  /// Sets the game mode and resets the game.
  void setGameMode(GameMode mode) {
    _history.clear();
    _redoStack.clear();
    state = ChessGameState.initial(gameMode: mode);
  }

  bool get canUndo => _history.isNotEmpty && state.phase == GamePhase.playerTurn;
  bool get canRedo => _redoStack.isNotEmpty && state.phase == GamePhase.playerTurn;

  /// Executes a player move, validates it, applies it, checks for
  /// game-over conditions, and then triggers the LLM's turn (in vsAi mode)
  /// or switches to the next player's turn (in vsPlayer mode).
  void undo() {
    if (!canUndo) return;

    if (state.gameMode == GameMode.vsAi) {
      if (_history.length < 2) return;
      _redoStack.add(state);
      _redoStack.add(_history.removeLast());
      state = _history.removeLast();
    } else {
      _redoStack.add(state);
      state = _history.removeLast();
    }
  }

  void redo() {
    if (!canRedo) return;

    if (state.gameMode == GameMode.vsAi) {
      if (_redoStack.length < 2) return;
      _history.add(state);
      final afterPlayerMove = _redoStack.removeLast();
      _history.add(afterPlayerMove);
      state = _redoStack.removeLast();
    } else {
      _history.add(state);
      state = _redoStack.removeLast();
    }
  }

  Future<void> playerMove(ChessMove move) async {
    if (state.phase != GamePhase.playerTurn) return;
    _history.add(state);
    _redoStack.clear();

    // Validate that the move is legal
    final legalMoves = ChessMoveGenerator.generateLegalMovesFromSquare(
        state.board, move.from);
    final isLegal = legalMoves.any((m) =>
        m.from == move.from &&
        m.to == move.to &&
        m.promotion == move.promotion &&
        m.isCastling == move.isCastling &&
        m.isEnPassant == move.isEnPassant);
    if (!isLegal) return;

    // Detect capture before applying the move.
    final isCapture =
        state.board.pieceAt(move.to) != null || move.isEnPassant;

    final notation = move.toAlgebraic(state.board);
    final newBoard = state.board.applyMove(move);

    // Play sound effects.
    _playSoundsAfterMove(newBoard, isCapture);

    // Check game-over for the opponent after this move
    final opponentColor = newBoard.activeColor;
    final gameOverState = _checkGameOver(newBoard, opponentColor);
    if (gameOverState != null) {
      try { ref.read(soundServiceProvider).playGameOver(); } catch (_) {}
      state = state.copyWith(
        board: newBoard,
        phase: GamePhase.gameOver,
        result: gameOverState,
        moveHistory: [...state.moveHistory, move],
        moveNotations: [...state.moveNotations, notation],
      );
      return;
    }

    if (state.gameMode == GameMode.vsPlayer) {
      // In vs Player mode, just switch to the next player's turn
      state = state.copyWith(
        board: newBoard,
        phase: GamePhase.playerTurn,
        moveHistory: [...state.moveHistory, move],
        moveNotations: [...state.moveNotations, notation],
      );
      // Auto-save after each completed move in vsPlayer mode
      saveGame();
      return;
    }

    // Set LLM thinking phase (vsAi mode)
    state = state.copyWith(
      board: newBoard,
      phase: GamePhase.llmThinking,
      moveHistory: [...state.moveHistory, move],
      moveNotations: [...state.moveNotations, notation],
    );

    // Trigger LLM move
    await llmMove();
  }

  /// Builds a prompt, calls the LLM, parses the response, validates it,
  /// and falls back to a random legal move if anything fails.
  Future<void> llmMove() async {
    _history.add(state);

    final legalMoves =
        ChessMoveGenerator.generateLegalMoves(state.board, PieceColor.black);
    if (legalMoves.isEmpty) return;

    ChessMove? selectedMove;

    try {
      final llmService = ref.read(llmServiceProvider);
      final prompt = ChessPromptBuilder.buildPrompt(state);
      final response = await llmService.generateResponse(prompt);

      // Parse the LLM response - extract the move notation
      final cleanedResponse = response.trim().split('\n').first.trim();
      selectedMove = ChessMove.fromAlgebraic(cleanedResponse, state.board);
    } catch (_) {
      // LLM not available or failed - fall back to random
    }

    // Fall back to random legal move if LLM response was invalid
    selectedMove ??= legalMoves[Random().nextInt(legalMoves.length)];

    // Detect capture before applying the move.
    final isCapture =
        state.board.pieceAt(selectedMove.to) != null || selectedMove.isEnPassant;

    final notation = selectedMove.toAlgebraic(state.board);
    final newBoard = state.board.applyMove(selectedMove);

    // Play sound effects.
    _playSoundsAfterMove(newBoard, isCapture);

    // Check game-over for White after Black's move
    final gameOverState = _checkGameOver(newBoard, PieceColor.white);
    if (gameOverState != null) {
      try { ref.read(soundServiceProvider).playGameOver(); } catch (_) {}
      state = state.copyWith(
        board: newBoard,
        phase: GamePhase.gameOver,
        result: gameOverState,
        moveHistory: [...state.moveHistory, selectedMove],
        moveNotations: [...state.moveNotations, notation],
      );
      return;
    }

    state = state.copyWith(
      board: newBoard,
      phase: GamePhase.playerTurn,
      moveHistory: [...state.moveHistory, selectedMove],
      moveNotations: [...state.moveNotations, notation],
    );
    // Auto-save after LLM move completes in vsAi mode
    saveGame();
  }

  /// Saves the current game state to persistent storage.
  Future<void> saveGame() async {
    if (state.phase == GamePhase.gameOver) return;
    await ref.read(gameSaveServiceProvider).saveChessGame(state);
  }

  /// Loads a saved game. Returns true if a game was loaded.
  Future<bool> loadGame() async {
    try {
      final saved = await ref.read(gameSaveServiceProvider).loadChessGame();
      if (saved == null) return false;
      _history.clear();
      _redoStack.clear();
      state = saved;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Deletes the saved game.
  Future<void> deleteSave() async {
    await ref.read(gameSaveServiceProvider).deleteChessGame();
  }

  /// Resets the game to initial state, preserving the current game mode.
  void resetGame() {
    _history.clear();
    _redoStack.clear();
    state = ChessGameState.initial(gameMode: state.gameMode);
  }

  /// Plays the appropriate sound effects after a move has been applied.
  void _playSoundsAfterMove(ChessBoard newBoard, bool isCapture) {
    try {
      final sound = ref.read(soundServiceProvider);
      if (isCapture) {
        sound.playCapture();
      } else {
        sound.playMove();
      }
      // Check if the opponent's king is now in check.
      if (ChessRules.isInCheck(newBoard, newBoard.activeColor)) {
        sound.playCheck();
      }
    } catch (_) {
      // Never let audio errors crash the game.
    }
  }

  /// Checks if the game is over for the given color (the color whose turn it
  /// now is). Returns a GameResult if the game is over, null otherwise.
  GameResult? _checkGameOver(ChessBoard board, PieceColor colorToMove) {
    if (ChessRules.isCheckmate(board, colorToMove)) {
      return colorToMove == PieceColor.white
          ? GameResult.llmWins
          : GameResult.playerWins;
    }
    if (ChessRules.isStalemate(board, colorToMove) ||
        ChessRules.isDraw(board)) {
      return GameResult.draw;
    }
    return null;
  }
}

final chessGameProvider =
    NotifierProvider<ChessGameNotifier, ChessGameState>(
        () => ChessGameNotifier());
