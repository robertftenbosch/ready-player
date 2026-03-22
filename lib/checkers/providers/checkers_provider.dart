import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/sound_service.dart';
import '../../core/llm/llm_service.dart';
import '../../core/models/game_mode.dart';
import '../../core/persistence/game_save_service.dart';
import '../llm/checkers_prompt_builder.dart';
import '../logic/checkers_rules.dart';
import '../models/checkers_board.dart';
import '../models/checkers_game_state.dart';
import '../models/checkers_move.dart';
import '../models/checkers_piece.dart';

class CheckersGameNotifier extends Notifier<CheckersGameState> {
  GameMode _gameMode = GameMode.vsAi;
  final List<CheckersGameState> _history = [];
  final List<CheckersGameState> _redoStack = [];

  @override
  CheckersGameState build() => CheckersGameState.initial(gameMode: _gameMode);

  bool get canUndo => _history.isNotEmpty && state.phase == CheckersPhase.playerTurn;
  bool get canRedo => _redoStack.isNotEmpty && state.phase == CheckersPhase.playerTurn;

  void undo() {
    if (!canUndo) return;

    if (_gameMode == GameMode.vsAi) {
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

    if (_gameMode == GameMode.vsAi) {
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

  /// Execute a player move (White in vsAi, or the current turn color in vsPlayer).
  void playerMove(CheckersMove move) {
    if (!state.isPlayerTurn) return;
    _history.add(state);
    _redoStack.clear();

    final newBoard = state.board.applyMove(move);
    final newHistory = [...state.moveHistory, move];
    final newNotations = [...state.moveNotations, move.toNotation()];

    // Play sound effects.
    try {
      final sound = ref.read(soundServiceProvider);
      if (move.isCapture) {
        sound.playCapture();
      } else {
        sound.playMove();
      }
    } catch (_) {}

    if (state.gameMode == GameMode.vsPlayer) {
      _handleVsPlayerMove(newBoard, newHistory, newNotations);
    } else {
      _handleVsAiMove(newBoard, newHistory, newNotations);
    }
  }

  void _handleVsPlayerMove(
    CheckersBoard newBoard,
    List<CheckersMove> newHistory,
    List<String> newNotations,
  ) {
    final currentColor = state.currentTurn;
    final nextColor = currentColor == CheckersColor.white
        ? CheckersColor.black
        : CheckersColor.white;

    // Check if current player won.
    if (CheckersRules.hasWon(newBoard, currentColor)) {
      try { ref.read(soundServiceProvider).playGameOver(); } catch (_) {}
      state = state.copyWith(
        board: newBoard,
        phase: CheckersPhase.gameOver,
        result: currentColor == CheckersColor.white
            ? CheckersResult.playerWins
            : CheckersResult.llmWins,
        moveHistory: newHistory,
        moveNotations: newNotations,
      );
      return;
    }

    // Check for draw (next player has no moves).
    if (CheckersRules.generateLegalMoves(newBoard, nextColor).isEmpty) {
      state = state.copyWith(
        board: newBoard,
        phase: CheckersPhase.gameOver,
        result: CheckersResult.draw,
        moveHistory: newHistory,
        moveNotations: newNotations,
      );
      return;
    }

    // Switch to the other player's turn.
    state = state.copyWith(
      board: newBoard,
      phase: CheckersPhase.playerTurn,
      currentTurn: nextColor,
      moveHistory: newHistory,
      moveNotations: newNotations,
    );
    // Auto-save after each completed move in vsPlayer mode
    saveGame();
  }

  void _handleVsAiMove(
    CheckersBoard newBoard,
    List<CheckersMove> newHistory,
    List<String> newNotations,
  ) {
    // Check for game over.
    if (CheckersRules.hasWon(newBoard, CheckersColor.white)) {
      try { ref.read(soundServiceProvider).playGameOver(); } catch (_) {}
      state = state.copyWith(
        board: newBoard,
        phase: CheckersPhase.gameOver,
        result: CheckersResult.playerWins,
        moveHistory: newHistory,
        moveNotations: newNotations,
      );
      return;
    }

    // Switch to LLM's turn.
    state = state.copyWith(
      board: newBoard,
      phase: CheckersPhase.llmThinking,
      moveHistory: newHistory,
      moveNotations: newNotations,
    );

    // Trigger LLM move asynchronously.
    _doLlmMove();
  }

  Future<void> _doLlmMove() async {
    _history.add(state);

    final llm = ref.read(llmServiceProvider);
    final legalMoves =
        CheckersRules.generateLegalMoves(state.board, CheckersColor.black);

    if (legalMoves.isEmpty) {
      state = state.copyWith(
        phase: CheckersPhase.gameOver,
        result: CheckersResult.playerWins,
      );
      return;
    }

    CheckersMove chosen;

    try {
      final prompt = CheckersPromptBuilder.buildPrompt(state);
      final response = await llm.generateResponse(prompt);
      chosen = _parseLlmMove(response.trim(), legalMoves) ??
          _randomMove(legalMoves);
    } catch (_) {
      chosen = _randomMove(legalMoves);
    }

    final newBoard = state.board.applyMove(chosen);
    final newHistory = [...state.moveHistory, chosen];
    final newNotations = [...state.moveNotations, chosen.toNotation()];

    // Play sound effects.
    try {
      final sound = ref.read(soundServiceProvider);
      if (chosen.isCapture) {
        sound.playCapture();
      } else {
        sound.playMove();
      }
    } catch (_) {}

    if (CheckersRules.hasWon(newBoard, CheckersColor.black)) {
      try { ref.read(soundServiceProvider).playGameOver(); } catch (_) {}
      state = state.copyWith(
        board: newBoard,
        phase: CheckersPhase.gameOver,
        result: CheckersResult.llmWins,
        moveHistory: newHistory,
        moveNotations: newNotations,
      );
      return;
    }

    // Check for draw.
    if (CheckersRules.generateLegalMoves(newBoard, CheckersColor.white)
        .isEmpty) {
      try { ref.read(soundServiceProvider).playGameOver(); } catch (_) {}
      state = state.copyWith(
        board: newBoard,
        phase: CheckersPhase.gameOver,
        result: CheckersResult.draw,
        moveHistory: newHistory,
        moveNotations: newNotations,
      );
      return;
    }

    state = state.copyWith(
      board: newBoard,
      phase: CheckersPhase.playerTurn,
      moveHistory: newHistory,
      moveNotations: newNotations,
    );
    // Auto-save after LLM move completes in vsAi mode
    saveGame();
  }

  /// Saves the current game state to persistent storage.
  Future<void> saveGame() async {
    if (state.phase == CheckersPhase.gameOver) return;
    await ref.read(gameSaveServiceProvider).saveCheckersGame(state);
  }

  /// Loads a saved game. Returns true if a game was loaded.
  Future<bool> loadGame() async {
    try {
      final saved =
          await ref.read(gameSaveServiceProvider).loadCheckersGame();
      if (saved == null) return false;
      _history.clear();
      _redoStack.clear();
      _gameMode = saved.gameMode;
      state = saved;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Deletes the saved game.
  Future<void> deleteSave() async {
    await ref.read(gameSaveServiceProvider).deleteCheckersGame();
  }

  void resetGame() {
    _history.clear();
    _redoStack.clear();
    state = CheckersGameState.initial(gameMode: _gameMode);
  }

  void setGameMode(GameMode mode) {
    _gameMode = mode;
    _history.clear();
    _redoStack.clear();
    state = CheckersGameState.initial(gameMode: mode);
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  CheckersMove _randomMove(List<CheckersMove> moves) {
    return moves[Random().nextInt(moves.length)];
  }

  /// Try to parse the LLM response into one of the legal moves.
  CheckersMove? _parseLlmMove(String raw, List<CheckersMove> legalMoves) {
    // Extract something that looks like a move notation from the response.
    final cleaned = raw
        .replaceAll(RegExp(r'[^0-9xX\-]'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .firstWhere(
          (s) => RegExp(r'^\d+[\-xX]\d+').hasMatch(s),
          orElse: () => '',
        );

    if (cleaned.isEmpty) return null;

    // Normalize separators.
    final notation = cleaned.replaceAll('X', 'x');

    for (final move in legalMoves) {
      if (move.toNotation() == notation) return move;
    }

    // Fallback: try matching just from-to if it's unambiguous.
    final parts = notation.split(RegExp(r'[\-x]'));
    if (parts.length >= 2) {
      final from = int.tryParse(parts.first);
      final to = int.tryParse(parts.last);
      if (from != null && to != null) {
        final matches =
            legalMoves.where((m) => m.from == from && m.to == to).toList();
        if (matches.length == 1) return matches.first;
      }
    }

    return null;
  }
}

final checkersGameProvider =
    NotifierProvider<CheckersGameNotifier, CheckersGameState>(
  () => CheckersGameNotifier(),
);
