import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/game_mode.dart';
import '../../core/theme/retro_colors.dart';
import '../../core/widgets/retro_scaffold.dart';
import '../../core/widgets/game_over_dialog.dart';
import '../providers/chess_provider.dart';
import '../widgets/chess_board_widget.dart';
import '../widgets/chess_move_log.dart';
import '../widgets/chess_promotion_dialog.dart';
import '../models/chess_piece.dart';
import '../models/chess_move.dart';
import '../models/chess_game_state.dart';

class ChessScreen extends ConsumerStatefulWidget {
  final GameMode gameMode;
  final bool loadedFromSave;

  // ignore: prefer_const_constructors_in_immutables
  ChessScreen({super.key, required this.gameMode, this.loadedFromSave = false});

  @override
  ConsumerState<ChessScreen> createState() => _ChessScreenState();
}

class _ChessScreenState extends ConsumerState<ChessScreen> {
  int? _selectedSquare;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _initialized = true;
      if (!widget.loadedFromSave) {
        Future.microtask(() {
          ref.read(chessGameProvider.notifier).setGameMode(widget.gameMode);
        });
      }
    }
    final gameState = ref.watch(chessGameProvider);

    ref.listen(chessGameProvider, (prev, next) {
      if (prev?.phase != GamePhase.gameOver &&
          next.phase == GamePhase.gameOver) {
        final isVsPlayer = next.gameMode == GameMode.vsPlayer;
        final (title, msg, color) = switch (next.result) {
          GameResult.playerWins => isVsPlayer
              ? ('WHITE WINS!', 'Checkmate!', RetroColors.primary)
              : ('YOU WIN!', 'Checkmate!', RetroColors.primary),
          GameResult.llmWins => isVsPlayer
              ? ('BLACK WINS!', 'Checkmate!', RetroColors.accent)
              : ('YOU LOSE!', 'Checkmate by LLM', RetroColors.accent),
          GameResult.draw => ('DRAW', 'Game drawn', RetroColors.secondary),
          null => ('GAME OVER', '', RetroColors.textMuted),
        };
        GameOverDialog.show(
          context,
          title: title,
          message: msg,
          color: color,
          onPlayAgain: () => ref.read(chessGameProvider.notifier).resetGame(),
          onExit: () => Navigator.of(context).pop(),
        );
      }
    });

    final chessNotifier = ref.read(chessGameProvider.notifier);
    final canUndo = chessNotifier.canUndo;
    final canRedo = chessNotifier.canRedo;

    return RetroScaffold(
      title: 'CHESS',
      actions: [
        IconButton(
          icon: Icon(Icons.undo, color: canUndo ? RetroColors.primary : RetroColors.textMuted),
          onPressed: canUndo ? () => ref.read(chessGameProvider.notifier).undo() : null,
        ),
        IconButton(
          icon: Icon(Icons.redo, color: canRedo ? RetroColors.primary : RetroColors.textMuted),
          onPressed: canRedo ? () => ref.read(chessGameProvider.notifier).redo() : null,
        ),
        IconButton(
          icon: const Icon(Icons.save, color: RetroColors.primary),
          onPressed: () => ref.read(chessGameProvider.notifier).saveGame(),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: RetroColors.primary),
          onPressed: () =>
              ref.read(chessGameProvider.notifier).resetGame(),
        ),
      ],
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;
          final flipped = !isLandscape &&
              widget.gameMode == GameMode.vsPlayer &&
              gameState.board.activeColor == PieceColor.black;

          final isPvP = widget.gameMode == GameMode.vsPlayer;
          final rotatePieces = isLandscape && isPvP;

          final boardWidget = ChessBoardWidget(
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
            rotatePiecesToPlayer: rotatePieces,
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

          final moveLogWidget = Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ChessMoveLog(moves: gameState.moveNotations),
            ),
          );

          if (isLandscape) {
            final infoColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                statusWidget,
                const SizedBox(height: 8),
                moveLogWidget,
              ],
            );

            return Row(
              children: [
                // In PvP: black player's info (rotated 180°) on the left
                if (isPvP)
                  Expanded(
                    child: RotatedBox(
                      quarterTurns: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          statusWidget,
                          const SizedBox(height: 8),
                          moveLogWidget,
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: boardWidget,
                  ),
                ),
                // White player's info on the right (normal orientation)
                Expanded(child: infoColumn),
              ],
            );
          }

          return Column(
            children: [
              const SizedBox(height: 8),
              statusWidget,
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: boardWidget,
                ),
              ),
              const SizedBox(height: 8),
              moveLogWidget,
            ],
          );
        },
      ),
    );
  }

  void _onSquareTapped(int square, ChessGameState gameState) {
    if (!gameState.isPlayerTurn) return;

    final notifier = ref.read(chessGameProvider.notifier);
    final allowedColor = gameState.gameMode == GameMode.vsPlayer
        ? gameState.board.activeColor
        : PieceColor.white;

    if (_selectedSquare == null) {
      // Select a piece
      final piece = gameState.board.pieceAt(square);
      if (piece != null && piece.color == allowedColor) {
        setState(() => _selectedSquare = square);
      }
    } else {
      // Try to move
      final legalMoves = gameState.getLegalMovesFrom(_selectedSquare!);
      final targetMove = legalMoves
          .where((m) => m.to == square)
          .toList();

      if (targetMove.isNotEmpty) {
        if (targetMove.length > 1) {
          // Promotion - show dialog
          _showPromotionDialog(targetMove, allowedColor);
        } else {
          notifier.playerMove(targetMove.first);
        }
        setState(() => _selectedSquare = null);
      } else {
        // Select new piece or deselect
        final piece = gameState.board.pieceAt(square);
        if (piece != null && piece.color == allowedColor) {
          setState(() => _selectedSquare = square);
        } else {
          setState(() => _selectedSquare = null);
        }
      }
    }
  }

  void _showPromotionDialog(List<ChessMove> promotionMoves, PieceColor color) {
    final first = promotionMoves.first;
    ChessPromotionDialog.show(
      context,
      from: first.from,
      to: first.to,
      color: color,
    ).then((move) {
      if (move != null) {
        ref.read(chessGameProvider.notifier).playerMove(move);
      }
    });
  }
}
