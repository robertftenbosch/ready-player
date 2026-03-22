import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/game_mode.dart';
import '../../core/theme/retro_colors.dart';
import '../../core/widgets/retro_scaffold.dart';
import '../../core/widgets/game_over_dialog.dart';
import '../providers/checkers_provider.dart';
import '../widgets/checkers_board_widget.dart';
import '../models/checkers_piece.dart';
import '../models/checkers_game_state.dart';

class CheckersScreen extends ConsumerStatefulWidget {
  final GameMode gameMode;
  final bool loadedFromSave;

  // ignore: prefer_const_constructors_in_immutables
  CheckersScreen({super.key, required this.gameMode, this.loadedFromSave = false});

  @override
  ConsumerState<CheckersScreen> createState() => _CheckersScreenState();
}

class _CheckersScreenState extends ConsumerState<CheckersScreen> {
  int? _selectedSquare;

  @override
  void initState() {
    super.initState();
    if (!widget.loadedFromSave) {
      // Set the game mode on the notifier after the first frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(checkersGameProvider.notifier).setGameMode(widget.gameMode);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(checkersGameProvider);

    ref.listen(checkersGameProvider, (prev, next) {
      if (prev?.phase != CheckersPhase.gameOver &&
          next.phase == CheckersPhase.gameOver) {
        final (title, msg, color) = _gameOverInfo(next);
        GameOverDialog.show(
          context,
          title: title,
          message: msg,
          color: color,
          onPlayAgain: () => ref.read(checkersGameProvider.notifier).resetGame(),
          onExit: () => Navigator.of(context).pop(),
        );
      }
    });

    final checkersNotifier = ref.read(checkersGameProvider.notifier);
    final canUndo = checkersNotifier.canUndo;
    final canRedo = checkersNotifier.canRedo;

    return RetroScaffold(
      title: 'DAMMEN',
      actions: [
        IconButton(
          icon: Icon(Icons.undo, color: canUndo ? RetroColors.primary : RetroColors.textMuted),
          onPressed: canUndo ? () => ref.read(checkersGameProvider.notifier).undo() : null,
        ),
        IconButton(
          icon: Icon(Icons.redo, color: canRedo ? RetroColors.primary : RetroColors.textMuted),
          onPressed: canRedo ? () => ref.read(checkersGameProvider.notifier).redo() : null,
        ),
        IconButton(
          icon: const Icon(Icons.save, color: RetroColors.primary),
          onPressed: () => ref.read(checkersGameProvider.notifier).saveGame(),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: RetroColors.primary),
          onPressed: () =>
              ref.read(checkersGameProvider.notifier).resetGame(),
        ),
      ],
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;
          final flipped = !isLandscape &&
              widget.gameMode == GameMode.vsPlayer &&
              gameState.currentTurn == CheckersColor.black;

          final boardWidget = CheckersBoardWidget(
            board: gameState.board,
            selectedSquare: _selectedSquare,
            legalMoves: _selectedSquare != null
                ? gameState.getLegalMovesFrom(_selectedSquare!)
                : [],
            onSquareTapped: (square) => _onSquareTapped(square, gameState),
            flipped: flipped,
            lastMove: gameState.moveHistory.isNotEmpty
                ? gameState.moveHistory.last
                : null,
          );

          final statusWidget = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              gameState.statusText,
              style: const TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 8,
                color: RetroColors.secondary,
              ),
            ),
          );

          final pieceCountWidget = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'White: ${gameState.board.whitePieceCount}',
                  style: const TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 8,
                    color: RetroColors.pieceWhite,
                  ),
                ),
                Text(
                  'Black: ${gameState.board.blackPieceCount}',
                  style: const TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 8,
                    color: RetroColors.textMuted,
                  ),
                ),
              ],
            ),
          );

          if (isLandscape) {
            return Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: boardWidget,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      statusWidget,
                      const SizedBox(height: 8),
                      pieceCountWidget,
                    ],
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              const SizedBox(height: 8),
              statusWidget,
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: boardWidget,
                ),
              ),
              const SizedBox(height: 8),
              pieceCountWidget,
            ],
          );
        },
      ),
    );
  }

  (String, String, Color) _gameOverInfo(CheckersGameState state) {
    if (widget.gameMode == GameMode.vsPlayer) {
      return switch (state.result) {
        CheckersResult.playerWins => ('White wins!', 'All pieces captured!', RetroColors.primary),
        CheckersResult.llmWins => ('Black wins!', 'All pieces captured!', RetroColors.accent),
        CheckersResult.draw => ('DRAW', 'No moves remaining', RetroColors.secondary),
        null => ('GAME OVER', '', RetroColors.textMuted),
      };
    }
    return switch (state.result) {
      CheckersResult.playerWins => ('YOU WIN!', 'All pieces captured!', RetroColors.primary),
      CheckersResult.llmWins => ('YOU LOSE!', 'LLM captured all pieces', RetroColors.accent),
      CheckersResult.draw => ('DRAW', 'No moves remaining', RetroColors.secondary),
      null => ('GAME OVER', '', RetroColors.textMuted),
    };
  }

  void _onSquareTapped(int square, CheckersGameState gameState) {
    if (!gameState.isPlayerTurn) return;
    final notifier = ref.read(checkersGameProvider.notifier);

    // Determine which color the current player controls.
    final activeColor = widget.gameMode == GameMode.vsPlayer
        ? gameState.currentTurn
        : CheckersColor.white;

    if (_selectedSquare == null) {
      final piece = gameState.board.pieceAt(square);
      if (piece != null && piece.color == activeColor) {
        setState(() => _selectedSquare = square);
      }
    } else {
      final legalMoves = gameState.getLegalMovesFrom(_selectedSquare!);
      final targetMove = legalMoves.where((m) => m.to == square).toList();

      if (targetMove.isNotEmpty) {
        notifier.playerMove(targetMove.first);
        setState(() => _selectedSquare = null);
      } else {
        final piece = gameState.board.pieceAt(square);
        if (piece != null && piece.color == activeColor) {
          setState(() => _selectedSquare = square);
        } else {
          setState(() => _selectedSquare = null);
        }
      }
    }
  }
}
