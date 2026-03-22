import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/sound_service.dart';
import '../../core/models/game_mode.dart';
import '../../core/llm/llm_service.dart';
import '../../core/persistence/game_save_service.dart';
import '../llm/ballerburg_prompt_builder.dart';
import '../logic/collision_detector.dart';
import '../logic/damage_calculator.dart';
import '../logic/physics_engine.dart';
import '../logic/terrain_generator.dart';
import '../models/ballerburg_game_state.dart';
import '../models/castle.dart';
import '../models/projectile.dart';
import '../models/wind.dart';

class BallerburgGameNotifier extends Notifier<BallerburgGameState> {
  Timer? _animationTimer;
  GameMode _gameMode = GameMode.vsAi;
  final List<BallerburgGameState> _history = [];
  final List<BallerburgGameState> _redoStack = [];

  @override
  BallerburgGameState build() {
    ref.onDispose(() => _animationTimer?.cancel());
    return _createInitialState(400, 300);
  }

  bool get canUndo =>
      _history.isNotEmpty &&
      (state.phase == BallerburgPhase.playerTurn ||
          state.phase == BallerburgPhase.player2Turn);

  bool get canRedo =>
      _redoStack.isNotEmpty &&
      (state.phase == BallerburgPhase.playerTurn ||
          state.phase == BallerburgPhase.player2Turn);

  void undo() {
    if (!canUndo) return;
    _animationTimer?.cancel();

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
      final afterPlayerShot = _redoStack.removeLast();
      _history.add(afterPlayerShot);
      state = _redoStack.removeLast();
    } else {
      _history.add(state);
      state = _redoStack.removeLast();
    }
  }

  void setGameMode(GameMode mode) {
    _gameMode = mode;
    _history.clear();
    _redoStack.clear();
    state = state.copyWith(gameMode: mode);
  }

  BallerburgGameState _createInitialState(double w, double h) {
    final leftCastle = Castle.createDefault(
      x: w * 0.15,
      y: h * 0.78,
      isLeft: true,
    );
    final rightCastle = Castle.createDefault(
      x: w * 0.85,
      y: h * 0.78,
      isLeft: false,
    );

    final mountain = TerrainGenerator.generate(
      w,
      h * 0.85,
      h * 0.35,
    );

    final rng = Random();
    final windSpeed = (rng.nextDouble() * 6.0) - 3.0;

    return BallerburgGameState(
      leftCastle: leftCastle,
      rightCastle: rightCastle,
      mountain: mountain,
      wind: Wind(speed: windSpeed),
      phase: BallerburgPhase.playerTurn,
      shotHistory: const [],
      canvasWidth: w,
      canvasHeight: h,
      gameMode: _gameMode,
    );
  }

  void updateCanvasSize(double width, double height) {
    if ((state.canvasWidth - width).abs() > 1 ||
        (state.canvasHeight - height).abs() > 1) {
      // Only rebuild if this is the initial default size
      if (state.canvasWidth == 400.0 && state.canvasHeight == 300.0) {
        state = _createInitialState(width, height);
      }
    }
  }

  void playerShoot({required double angle, required double powder}) {
    if (state.phase != BallerburgPhase.playerTurn) return;
    _history.add(state);
    _redoStack.clear();

    try { ref.read(soundServiceProvider).playCannon(); } catch (_) {}

    final castle = state.leftCastle;
    final cannonPos = Offset(
      castle.x + Castle.gridWidth * Castle.blockSize / 2 + 4,
      castle.topLeft.dy + 2 * Castle.blockSize,
    );

    final trajectory = PhysicsEngine.computeTrajectory(
      start: cannonPos,
      angleDeg: angle,
      powder: powder,
      windSpeed: state.wind.speed,
      canvasWidth: state.canvasWidth,
      canvasHeight: state.canvasHeight,
      firingRight: true,
    );

    state = state.copyWith(
      phase: BallerburgPhase.playerShooting,
      projectile: Projectile(trajectory: trajectory),
      clearExplosion: true,
    );

    _animateProjectile(angle, powder, true);
  }

  void player2Shoot({required double angle, required double powder}) {
    if (state.phase != BallerburgPhase.player2Turn) return;
    _history.add(state);
    _redoStack.clear();

    try { ref.read(soundServiceProvider).playCannon(); } catch (_) {}

    final castle = state.rightCastle;
    final cannonPos = Offset(
      castle.x - Castle.gridWidth * Castle.blockSize / 2 - 4,
      castle.topLeft.dy + 2 * Castle.blockSize,
    );

    final trajectory = PhysicsEngine.computeTrajectory(
      start: cannonPos,
      angleDeg: angle,
      powder: powder,
      windSpeed: state.wind.speed,
      canvasWidth: state.canvasWidth,
      canvasHeight: state.canvasHeight,
      firingRight: false,
    );

    state = state.copyWith(
      phase: BallerburgPhase.llmShooting,
      projectile: Projectile(trajectory: trajectory),
      clearExplosion: true,
    );

    _animateProjectile(angle, powder, false);
  }

  void _animateProjectile(double angle, double powder, bool isPlayer) {
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (timer) {
        final proj = state.projectile;
        if (proj == null || proj.isFinished) {
          timer.cancel();
          _onProjectileDone(angle, powder, isPlayer, null);
          return;
        }

        // Advance by 3 steps for visible speed
        final newProj = proj.advance(3);
        final pos = newProj.currentPosition;

        // Check collision at current position
        final collision = CollisionDetector.checkCollision(pos, state);
        if (collision != null) {
          timer.cancel();
          state = state.copyWith(
            projectile: newProj,
            explosionPoint: collision.point,
            explosionProgress: 0.0,
          );
          _animateExplosion(angle, powder, isPlayer, collision);
          return;
        }

        state = state.copyWith(projectile: newProj);
      },
    );
  }

  void _animateExplosion(double angle, double powder, bool isPlayer,
      CollisionResult collision) {
    _animationTimer?.cancel();
    try { ref.read(soundServiceProvider).playExplosion(); } catch (_) {}
    double progress = 0.0;
    _animationTimer = Timer.periodic(
      const Duration(milliseconds: 30),
      (timer) {
        progress += 0.1;
        if (progress >= 1.0) {
          timer.cancel();
          state = state.copyWith(explosionProgress: 1.0);
          _onProjectileDone(angle, powder, isPlayer, collision);
          return;
        }
        state = state.copyWith(explosionProgress: progress);
      },
    );
  }

  void _onProjectileDone(
      double angle, double powder, bool isPlayer, CollisionResult? collision) {
    var newLeft = state.leftCastle;
    var newRight = state.rightCastle;
    BallerburgResult? result;

    if (collision != null) {
      switch (collision.type) {
        case CollisionType.leftCastle:
          newLeft = DamageCalculator.applyDamage(newLeft, collision.point);
          if (newLeft.health <= 0) {
            result = BallerburgResult.llmWins;
          }
        case CollisionType.rightCastle:
          newRight = DamageCalculator.applyDamage(newRight, collision.point);
          if (newRight.health <= 0) {
            result = BallerburgResult.playerWins;
          }
        case CollisionType.leftKingHit:
          result = BallerburgResult.llmWins;
          newLeft = Castle(
            x: newLeft.x,
            y: newLeft.y,
            health: 0.0,
            blocks: newLeft.blocks,
            kingPosition: newLeft.kingPosition,
            isLeft: true,
          );
        case CollisionType.rightKingHit:
          result = BallerburgResult.playerWins;
          newRight = Castle(
            x: newRight.x,
            y: newRight.y,
            health: 0.0,
            blocks: newRight.blocks,
            kingPosition: newRight.kingPosition,
            isLeft: false,
          );
        case CollisionType.mountain:
        case CollisionType.ground:
          break;
      }
    }

    final newHistory = [
      ...state.shotHistory,
      ShotRecord(
        angle: angle,
        powder: powder,
        isPlayer: isPlayer,
        hitPoint: collision?.point,
      ),
    ];

    // Generate new wind each turn
    final rng = Random();
    final newWind = Wind(speed: (rng.nextDouble() * 6.0) - 3.0);

    if (result != null) {
      try { ref.read(soundServiceProvider).playGameOver(); } catch (_) {}
      state = state.copyWith(
        leftCastle: newLeft,
        rightCastle: newRight,
        phase: BallerburgPhase.gameOver,
        result: result,
        clearProjectile: true,
        shotHistory: newHistory,
        wind: newWind,
      );
      return;
    }

    if (isPlayer) {
      if (_gameMode == GameMode.vsPlayer) {
        state = state.copyWith(
          leftCastle: newLeft,
          rightCastle: newRight,
          phase: BallerburgPhase.player2Turn,
          clearProjectile: true,
          shotHistory: newHistory,
          wind: newWind,
          clearExplosion: true,
        );
        // Auto-save between turns in vsPlayer mode
        saveGame();
      } else {
        state = state.copyWith(
          leftCastle: newLeft,
          rightCastle: newRight,
          phase: BallerburgPhase.llmThinking,
          clearProjectile: true,
          shotHistory: newHistory,
          wind: newWind,
          clearExplosion: true,
        );
        _llmTurn();
      }
    } else {
      state = state.copyWith(
        leftCastle: newLeft,
        rightCastle: newRight,
        phase: BallerburgPhase.playerTurn,
        clearProjectile: true,
        shotHistory: newHistory,
        wind: newWind,
        clearExplosion: true,
      );
      // Auto-save after opponent's turn completes
      saveGame();
    }
  }

  Future<void> _llmTurn() async {
    _history.add(state);

    double angle;
    double powder;

    try {
      final llm = ref.read(llmServiceProvider);
      final prompt = BallerburgPromptBuilder.buildPrompt(state);
      final response = await llm.generateResponse(prompt);
      final parsed = _parseLlmResponse(response);
      angle = parsed.$1;
      powder = parsed.$2;
    } catch (_) {
      // Fallback to random
      final rng = Random();
      angle = 30.0 + rng.nextDouble() * 40.0;
      powder = 30.0 + rng.nextDouble() * 50.0;
    }

    angle = angle.clamp(20.0, 80.0);
    powder = powder.clamp(10.0, 100.0);

    final castle = state.rightCastle;
    final cannonPos = Offset(
      castle.x - Castle.gridWidth * Castle.blockSize / 2 - 4,
      castle.topLeft.dy + 2 * Castle.blockSize,
    );

    final trajectory = PhysicsEngine.computeTrajectory(
      start: cannonPos,
      angleDeg: angle,
      powder: powder,
      windSpeed: state.wind.speed,
      canvasWidth: state.canvasWidth,
      canvasHeight: state.canvasHeight,
      firingRight: false,
    );

    state = state.copyWith(
      phase: BallerburgPhase.llmShooting,
      projectile: Projectile(trajectory: trajectory),
      clearExplosion: true,
    );

    _animateProjectile(angle, powder, false);
  }

  (double, double) _parseLlmResponse(String response) {
    final angleMatch = RegExp(r'ANGLE\s*=\s*(\d+\.?\d*)').firstMatch(response);
    final powderMatch =
        RegExp(r'POWDER\s*=\s*(\d+\.?\d*)').firstMatch(response);

    if (angleMatch == null || powderMatch == null) {
      throw const FormatException('Could not parse LLM response');
    }

    return (
      double.parse(angleMatch.group(1)!),
      double.parse(powderMatch.group(1)!),
    );
  }

  /// Saves the current game state to persistent storage.
  Future<void> saveGame() async {
    if (state.phase == BallerburgPhase.gameOver) return;
    // Don't save during animation
    if (state.phase == BallerburgPhase.playerShooting ||
        state.phase == BallerburgPhase.llmShooting) {
      return;
    }
    await ref.read(gameSaveServiceProvider).saveBallerburgGame(state);
  }

  /// Loads a saved game. Returns true if a game was loaded.
  Future<bool> loadGame() async {
    try {
      final saved =
          await ref.read(gameSaveServiceProvider).loadBallerburgGame();
      if (saved == null) return false;
      _animationTimer?.cancel();
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
    await ref.read(gameSaveServiceProvider).deleteBallerburgGame();
  }

  void resetGame() {
    _animationTimer?.cancel();
    _history.clear();
    _redoStack.clear();
    state = _createInitialState(state.canvasWidth, state.canvasHeight);
  }
}

final ballerburgGameProvider =
    NotifierProvider<BallerburgGameNotifier, BallerburgGameState>(
  () => BallerburgGameNotifier(),
);
