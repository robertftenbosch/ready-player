import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/game_mode.dart';
import '../../core/theme/retro_colors.dart';
import '../../core/widgets/retro_scaffold.dart';
import '../../core/widgets/pixel_button.dart';
import '../../core/widgets/game_over_dialog.dart';
import '../providers/ballerburg_provider.dart';
import '../models/ballerburg_game_state.dart';
import '../widgets/ballerburg_canvas.dart';
import '../widgets/angle_selector.dart';
import '../widgets/powder_selector.dart';
import '../widgets/wind_indicator.dart';

class BallerburgScreen extends ConsumerStatefulWidget {
  final GameMode gameMode;
  final bool loadedFromSave;

  BallerburgScreen({super.key, required this.gameMode, this.loadedFromSave = false}); // ignore: prefer_const_constructors_in_immutables

  @override
  ConsumerState<BallerburgScreen> createState() => _BallerburgScreenState();
}

class _BallerburgScreenState extends ConsumerState<BallerburgScreen> {
  double _angle = 45;
  double _powder = 50;
  bool _gameModeSet = false;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(ballerburgGameProvider);

    if (!_gameModeSet) {
      _gameModeSet = true;
      if (!widget.loadedFromSave) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(ballerburgGameProvider.notifier).setGameMode(widget.gameMode);
        });
      }
    }

    ref.listen(ballerburgGameProvider, (prev, next) {
      if (prev?.phase != BallerburgPhase.gameOver &&
          next.phase == BallerburgPhase.gameOver) {
        final bool isVsPlayer = next.gameMode == GameMode.vsPlayer;
        final (title, msg, color) = switch (next.result) {
          BallerburgResult.playerWins => (
              isVsPlayer ? 'PLAYER 1 WINS!' : 'VICTORY!',
              isVsPlayer ? 'Player 1 destroyed the enemy castle!' : 'Enemy castle destroyed!',
              RetroColors.primary,
            ),
          BallerburgResult.llmWins => (
              isVsPlayer ? 'PLAYER 2 WINS!' : 'DEFEATED!',
              isVsPlayer ? 'Player 2 destroyed the enemy castle!' : 'Your castle fell!',
              RetroColors.accent,
            ),
          null => ('GAME OVER', '', RetroColors.textMuted),
        };
        GameOverDialog.show(
          context,
          title: title,
          message: msg,
          color: color,
          onPlayAgain: () => ref.read(ballerburgGameProvider.notifier).resetGame(),
          onExit: () => Navigator.of(context).pop(),
        );
      }
    });

    final bool showControls = gameState.isPlayerTurn;
    final String fireButtonText = gameState.isPlayer2Turn
        ? 'PLAYER 2 - FIRE!'
        : (gameState.gameMode == GameMode.vsPlayer
            ? 'PLAYER 1 - FIRE!'
            : 'FIRE!');

    final ballerburgNotifier = ref.read(ballerburgGameProvider.notifier);
    final canUndo = ballerburgNotifier.canUndo;
    final canRedo = ballerburgNotifier.canRedo;

    return RetroScaffold(
      title: 'BALLERBURG',
      actions: [
        IconButton(
          icon: Icon(Icons.undo, color: canUndo ? RetroColors.primary : RetroColors.textMuted),
          onPressed: canUndo ? () => ref.read(ballerburgGameProvider.notifier).undo() : null,
        ),
        IconButton(
          icon: Icon(Icons.redo, color: canRedo ? RetroColors.primary : RetroColors.textMuted),
          onPressed: canRedo ? () => ref.read(ballerburgGameProvider.notifier).redo() : null,
        ),
        IconButton(
          icon: const Icon(Icons.save, color: RetroColors.primary),
          onPressed: () => ref.read(ballerburgGameProvider.notifier).saveGame(),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: RetroColors.primary),
          onPressed: () =>
              ref.read(ballerburgGameProvider.notifier).resetGame(),
        ),
      ],
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;

          final canvasWidget = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: BallerburgCanvas(gameState: gameState),
          );

          final windWidget = WindIndicator(wind: gameState.wind);

          final controlsOrStatus = showControls
              ? _buildControls(fireButtonText, gameState, ref, isLandscape)
              : _buildStatusText(gameState, isLandscape);

          if (isLandscape) {
            return Row(
              children: [
                // Left side: game canvas
                Expanded(
                  flex: 3,
                  child: canvasWidget,
                ),
                // Right side: wind + controls
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        windWidget,
                        const SizedBox(height: 8),
                        ...controlsOrStatus,
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          // Portrait layout (unchanged)
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: windWidget,
              ),
              Expanded(
                flex: 3,
                child: canvasWidget,
              ),
              ...controlsOrStatus,
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildControls(
    String fireButtonText,
    BallerburgGameState gameState,
    WidgetRef ref,
    bool isLandscape,
  ) {
    if (isLandscape) {
      return [
        AngleSelector(
          value: _angle,
          onChanged: (v) => setState(() => _angle = v),
        ),
        const SizedBox(height: 4),
        PowderSelector(
          value: _powder,
          onChanged: (v) => setState(() => _powder = v),
        ),
        const SizedBox(height: 8),
        PixelButton(
          text: fireButtonText,
          color: RetroColors.accent,
          onPressed: () => _fire(gameState, ref),
        ),
        const SizedBox(height: 8),
      ];
    }
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AngleSelector(
          value: _angle,
          onChanged: (v) => setState(() => _angle = v),
        ),
      ),
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: PowderSelector(
          value: _powder,
          onChanged: (v) => setState(() => _powder = v),
        ),
      ),
      const SizedBox(height: 8),
      PixelButton(
        text: fireButtonText,
        color: RetroColors.accent,
        onPressed: () => _fire(gameState, ref),
      ),
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _buildStatusText(BallerburgGameState gameState, bool isLandscape) {
    return [
      Padding(
        padding: isLandscape
            ? const EdgeInsets.all(8)
            : const EdgeInsets.all(16),
        child: Text(
          gameState.statusText,
          style: const TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 8,
            color: RetroColors.secondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ];
  }

  void _fire(BallerburgGameState gameState, WidgetRef ref) {
    if (gameState.isPlayer2Turn) {
      ref.read(ballerburgGameProvider.notifier).player2Shoot(
            angle: _angle,
            powder: _powder,
          );
    } else {
      ref.read(ballerburgGameProvider.notifier).playerShoot(
            angle: _angle,
            powder: _powder,
          );
    }
  }
}
