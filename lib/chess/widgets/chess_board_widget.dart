import 'package:flutter/material.dart';

import '../../core/theme/retro_colors.dart';
import '../models/chess_board.dart';
import '../models/chess_move.dart';
import '../models/chess_piece.dart';
import 'chess_piece_widget.dart';

class ChessBoardWidget extends StatefulWidget {
  final ChessBoard board;
  final int? selectedSquare;
  final List<ChessMove> legalMoves;
  final ValueChanged<int> onSquareTapped;
  final bool flipped;
  final ChessMove? lastMove;
  final VoidCallback? onAnimationComplete;

  /// When true, black pieces are rotated 180° to face the opponent player
  /// (for tabletop PvP in landscape).
  final bool rotatePiecesToPlayer;

  const ChessBoardWidget({
    super.key,
    required this.board,
    required this.selectedSquare,
    required this.legalMoves,
    required this.onSquareTapped,
    this.flipped = false,
    this.lastMove,
    this.onAnimationComplete,
    this.rotatePiecesToPlayer = false,
  });

  @override
  State<ChessBoardWidget> createState() => _ChessBoardWidgetState();
}

class _ChessBoardWidgetState extends State<ChessBoardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  /// The move currently being animated (null if no animation in progress).
  ChessMove? _animatingMove;

  /// The piece that is being animated (the piece that moved).
  ChessPiece? _animatingPiece;

  /// The last move we've seen, used to detect new moves.
  ChessMove? _previousLastMove;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _animatingMove = null;
          _animatingPiece = null;
        });
        widget.onAnimationComplete?.call();
      }
    });
    _previousLastMove = widget.lastMove;
  }

  @override
  void didUpdateWidget(covariant ChessBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lastMove != oldWidget.lastMove &&
        widget.lastMove != null &&
        widget.lastMove != _previousLastMove) {
      _startAnimation(widget.lastMove!);
    }
    _previousLastMove = widget.lastMove;
  }

  void _startAnimation(ChessMove move) {
    // The piece is already at the 'to' square in the board state.
    // We grab it from there to animate.
    final piece = widget.board.pieceAt(move.to);
    if (piece == null) return;

    setState(() {
      _animatingMove = move;
      _animatingPiece = piece;
    });
    _animationController.forward(from: 0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Convert a board square index to visual (col, row) position in pixels,
  /// given squareSize and the flipped state.
  Offset _squareToVisualOffset(int square, double squareSize) {
    final row = square ~/ 8;
    final col = square % 8;
    final visualCol = widget.flipped ? 7 - col : col;
    final visualRow = widget.flipped ? row : 7 - row;
    return Offset(visualCol * squareSize, visualRow * squareSize);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final squareSize = constraints.maxWidth / 8;
          return Stack(
            children: [
              // The board grid
              Column(
                children: List.generate(8, (visualRow) {
                  final row =
                      widget.flipped ? visualRow : 7 - visualRow;
                  return Row(
                    children: List.generate(8, (visualCol) {
                      final col =
                          widget.flipped ? 7 - visualCol : visualCol;
                      final square = row * 8 + col;
                      final piece = widget.board.pieceAt(square);
                      final isLight = (row + col) % 2 == 0;
                      final isSelected = square == widget.selectedSquare;
                      final isLegalTarget =
                          widget.legalMoves.any((m) => m.to == square);

                      // Highlight last move squares
                      final isLastMoveSquare = widget.lastMove != null &&
                          (square == widget.lastMove!.from ||
                              square == widget.lastMove!.to);

                      // Hide the piece on the 'to' square while animating
                      final hideForAnimation = _animatingMove != null &&
                          square == _animatingMove!.to;

                      Color bgColor;
                      if (isSelected) {
                        bgColor =
                            RetroColors.primary.withValues(alpha: 0.5);
                      } else if (isLegalTarget) {
                        bgColor = isLight
                            ? RetroColors.boardLight
                                .withValues(alpha: 0.7)
                            : RetroColors.boardDark
                                .withValues(alpha: 0.7);
                      } else if (isLastMoveSquare) {
                        bgColor = isLight
                            ? RetroColors.primary.withValues(alpha: 0.18)
                            : RetroColors.primary.withValues(alpha: 0.25);
                      } else {
                        bgColor = isLight
                            ? RetroColors.boardLight
                            : RetroColors.boardDark;
                      }

                      return GestureDetector(
                        onTap: () => widget.onSquareTapped(square),
                        child: Container(
                          width: squareSize,
                          height: squareSize,
                          color: bgColor,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (piece != null && !hideForAnimation)
                                ChessPieceWidget(
                                  piece: piece,
                                  size: squareSize * 0.7,
                                  quarterTurns: widget.rotatePiecesToPlayer &&
                                          piece.color == PieceColor.black
                                      ? 2
                                      : 0,
                                ),
                              if (isLegalTarget && piece == null)
                                Container(
                                  width: squareSize * 0.25,
                                  height: squareSize * 0.25,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: RetroColors.primary
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                              if (isLegalTarget && piece != null)
                                Container(
                                  width: squareSize * 0.9,
                                  height: squareSize * 0.9,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: RetroColors.accent
                                          .withValues(alpha: 0.6),
                                      width: 3,
                                    ),
                                  ),
                                ),
                              // File labels on bottom visual row
                              if (visualRow == 7)
                                Positioned(
                                  bottom: 1,
                                  right: 3,
                                  child: Text(
                                    String.fromCharCode(
                                        'a'.codeUnitAt(0) + col),
                                    style: TextStyle(
                                      fontSize: squareSize * 0.15,
                                      color: isLight
                                          ? RetroColors.boardDark
                                          : RetroColors.boardLight,
                                    ),
                                  ),
                                ),
                              // Rank labels on left visual column
                              if (visualCol == 0)
                                Positioned(
                                  top: 1,
                                  left: 3,
                                  child: Text(
                                    '${row + 1}',
                                    style: TextStyle(
                                      fontSize: squareSize * 0.15,
                                      color: isLight
                                          ? RetroColors.boardDark
                                          : RetroColors.boardLight,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
              // Animated piece overlay
              if (_animatingMove != null && _animatingPiece != null)
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final fromOffset = _squareToVisualOffset(
                        _animatingMove!.from, squareSize);
                    final toOffset = _squareToVisualOffset(
                        _animatingMove!.to, squareSize);
                    final currentOffset = Offset.lerp(
                        fromOffset, toOffset, _animation.value)!;
                    return Positioned(
                      left: currentOffset.dx,
                      top: currentOffset.dy,
                      width: squareSize,
                      height: squareSize,
                      child: IgnorePointer(
                        child: Center(
                          child: ChessPieceWidget(
                            piece: _animatingPiece!,
                            size: squareSize * 0.7,
                            quarterTurns: widget.rotatePiecesToPlayer &&
                                    _animatingPiece!.color == PieceColor.black
                                ? 2
                                : 0,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
