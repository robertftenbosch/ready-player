import 'dart:ui';

import '../../core/models/game_mode.dart';
import 'castle.dart';
import 'mountain.dart';
import 'projectile.dart';
import 'wind.dart';

enum BallerburgPhase {
  playerTurn,
  playerShooting,
  player2Turn,
  llmThinking,
  llmShooting,
  gameOver,
}

enum BallerburgResult { playerWins, llmWins }

class ShotRecord {
  final double angle;
  final double powder;
  final bool isPlayer;
  final Offset? hitPoint;

  const ShotRecord({
    required this.angle,
    required this.powder,
    required this.isPlayer,
    this.hitPoint,
  });

  Map<String, dynamic> toJson() => {
        'angle': angle,
        'powder': powder,
        'isPlayer': isPlayer,
        'hitPointDx': hitPoint?.dx,
        'hitPointDy': hitPoint?.dy,
      };

  factory ShotRecord.fromJson(Map<String, dynamic> json) {
    return ShotRecord(
      angle: (json['angle'] as num).toDouble(),
      powder: (json['powder'] as num).toDouble(),
      isPlayer: json['isPlayer'] as bool,
      hitPoint: json['hitPointDx'] != null
          ? Offset(
              (json['hitPointDx'] as num).toDouble(),
              (json['hitPointDy'] as num).toDouble(),
            )
          : null,
    );
  }
}

class BallerburgGameState {
  final Castle leftCastle;
  final Castle rightCastle;
  final Mountain mountain;
  final Wind wind;
  final BallerburgPhase phase;
  final BallerburgResult? result;
  final Projectile? projectile;
  final List<ShotRecord> shotHistory;
  final double canvasWidth;
  final double canvasHeight;
  final Offset? explosionPoint;
  final double explosionProgress;
  final GameMode gameMode;

  const BallerburgGameState({
    required this.leftCastle,
    required this.rightCastle,
    required this.mountain,
    required this.wind,
    required this.phase,
    this.result,
    this.projectile,
    required this.shotHistory,
    required this.canvasWidth,
    required this.canvasHeight,
    this.explosionPoint,
    this.explosionProgress = 0.0,
    this.gameMode = GameMode.vsAi,
  });

  bool get isPlayerTurn =>
      phase == BallerburgPhase.playerTurn ||
      phase == BallerburgPhase.player2Turn;

  bool get isPlayer2Turn => phase == BallerburgPhase.player2Turn;

  String get statusText {
    final isVsPlayer = gameMode == GameMode.vsPlayer;
    switch (phase) {
      case BallerburgPhase.playerTurn:
        return isVsPlayer ? 'PLAYER 1 - FIRE!' : 'YOUR TURN - AIM AND FIRE!';
      case BallerburgPhase.playerShooting:
        return 'FIRING...';
      case BallerburgPhase.player2Turn:
        return 'PLAYER 2 - FIRE!';
      case BallerburgPhase.llmThinking:
        return 'ENEMY IS THINKING...';
      case BallerburgPhase.llmShooting:
        return 'ENEMY FIRES!';
      case BallerburgPhase.gameOver:
        if (isVsPlayer) {
          return result == BallerburgResult.playerWins
              ? 'PLAYER 1 WINS!'
              : 'PLAYER 2 WINS!';
        }
        if (result == BallerburgResult.playerWins) {
          return 'VICTORY! THE ENEMY CASTLE FALLS!';
        } else {
          return 'DEFEAT! YOUR CASTLE HAS FALLEN!';
        }
    }
  }

  factory BallerburgGameState.initial() {
    const w = 400.0;
    const h = 300.0;

    final leftCastle = Castle.createDefault(
      x: w * 0.15,
      y: h * 0.75,
      isLeft: true,
    );
    final rightCastle = Castle.createDefault(
      x: w * 0.85,
      y: h * 0.75,
      isLeft: false,
    );

    return BallerburgGameState(
      leftCastle: leftCastle,
      rightCastle: rightCastle,
      mountain: const Mountain(heightMap: []),
      wind: const Wind(speed: 0.0),
      phase: BallerburgPhase.playerTurn,
      shotHistory: const [],
      canvasWidth: w,
      canvasHeight: h,
    );
  }

  Map<String, dynamic> toJson() {
    // Save phase as playerTurn or player2Turn (not animation/thinking states)
    String savedPhase;
    switch (phase) {
      case BallerburgPhase.playerTurn:
      case BallerburgPhase.playerShooting:
        savedPhase = BallerburgPhase.playerTurn.name;
      case BallerburgPhase.player2Turn:
      case BallerburgPhase.llmThinking:
      case BallerburgPhase.llmShooting:
        savedPhase = BallerburgPhase.player2Turn.name;
      case BallerburgPhase.gameOver:
        savedPhase = BallerburgPhase.gameOver.name;
    }

    return {
      'leftCastle': leftCastle.toJson(),
      'rightCastle': rightCastle.toJson(),
      'mountain': mountain.toJson(),
      'wind': wind.toJson(),
      'phase': savedPhase,
      'result': result?.name,
      'shotHistory': shotHistory.map((s) => s.toJson()).toList(),
      'canvasWidth': canvasWidth,
      'canvasHeight': canvasHeight,
      'gameMode': gameMode.name,
    };
  }

  factory BallerburgGameState.fromJson(Map<String, dynamic> json) {
    return BallerburgGameState(
      leftCastle:
          Castle.fromJson(Map<String, dynamic>.from(json['leftCastle'] as Map)),
      rightCastle: Castle.fromJson(
          Map<String, dynamic>.from(json['rightCastle'] as Map)),
      mountain:
          Mountain.fromJson(Map<String, dynamic>.from(json['mountain'] as Map)),
      wind: Wind.fromJson(Map<String, dynamic>.from(json['wind'] as Map)),
      phase: BallerburgPhase.values.byName(json['phase'] as String),
      result: json['result'] != null
          ? BallerburgResult.values.byName(json['result'] as String)
          : null,
      shotHistory: (json['shotHistory'] as List)
          .map(
              (s) => ShotRecord.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList(),
      canvasWidth: (json['canvasWidth'] as num).toDouble(),
      canvasHeight: (json['canvasHeight'] as num).toDouble(),
      gameMode: GameMode.values.byName(json['gameMode'] as String),
    );
  }

  BallerburgGameState copyWith({
    Castle? leftCastle,
    Castle? rightCastle,
    Mountain? mountain,
    Wind? wind,
    BallerburgPhase? phase,
    BallerburgResult? result,
    Projectile? projectile,
    bool clearProjectile = false,
    List<ShotRecord>? shotHistory,
    double? canvasWidth,
    double? canvasHeight,
    Offset? explosionPoint,
    bool clearExplosion = false,
    double? explosionProgress,
    GameMode? gameMode,
  }) {
    return BallerburgGameState(
      leftCastle: leftCastle ?? this.leftCastle,
      rightCastle: rightCastle ?? this.rightCastle,
      mountain: mountain ?? this.mountain,
      wind: wind ?? this.wind,
      phase: phase ?? this.phase,
      result: result ?? this.result,
      projectile: clearProjectile ? null : (projectile ?? this.projectile),
      shotHistory: shotHistory ?? this.shotHistory,
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      explosionPoint:
          clearExplosion ? null : (explosionPoint ?? this.explosionPoint),
      explosionProgress: explosionProgress ?? this.explosionProgress,
      gameMode: gameMode ?? this.gameMode,
    );
  }
}
