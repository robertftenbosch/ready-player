import 'package:flutter/material.dart';

import '../../core/theme/retro_colors.dart';
import '../models/checkers_board.dart';
import '../models/checkers_move.dart';
import '../models/checkers_piece.dart';
import 'checkers_piece_widget.dart';

class CheckersBoardWidget extends StatefulWidget {
  final CheckersBoard board;
  final int? selectedSquare;
  final List<CheckersMove> legalMoves;
  final ValueChanged<int> onSquareTapped;
  final bool flipped;
  final CheckersMove? lastMove;
  final VoidCallback? onAnimationComplete;

  const CheckersBoardWidget({
    super.key,
    required this.board,
    required this.selectedSquare,
    required this.legalMoves,
    required this.onSquareTapped,
    this.flipped = false,
    this.lastMove,
    this.onAnimationComplete,
  });

  @override
  State<CheckersBoardWidget> createState() => _CheckersBoardWidgetState();
}

class _CheckersBoardWidgetState extends State<CheckersBoardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  CheckersMove? _animatingMove;
  CheckersPiece? _animatingPiece;
  CheckersMove? _previousLastMove;

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
  void didUpdateWidget(covariant CheckersBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lastMove != oldWidget.lastMove &&
        widget.lastMove != null &&
        widget.lastMove != _previousLastMove) {
      _startAnimation(widget.lastMove!);
    }
    _previousLastMove = widget.lastMove;
  }

  void _startAnimation(CheckersMove move) {
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

  /// Convert a checkers square number (1-50) to visual pixel offset.
  Offset _squareToVisualOffset(int square, double cellSize) {
    final row = CheckersBoard.rowOf(square);
    final col = CheckersBoard.colOf(square);
    final visualRow = widget.flipped ? 9 - row : row;
    final visualCol = widget.flipped ? 9 - col : col;
    return Offset(visualCol * cellSize, visualRow * cellSize);
  }

  @override
  Widget build(BuildContext context) {
    final legalTargets = widget.legalMoves.map((m) => m.to).toSet();

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final cellSize = boardSize / 10;

        return SizedBox(
          width: boardSize,
          height: boardSize,
          child: Stack(
            children: [
              // Draw the 10x10 grid.
              for (var visualRow = 0; visualRow < 10; visualRow++)
                for (var visualCol = 0; visualCol < 10; visualCol++)
                  Positioned(
                    left: visualCol * cellSize,
                    top: visualRow * cellSize,
                    width: cellSize,
                    height: cellSize,
                    child: _buildCell(
                      widget.flipped ? 9 - visualRow : visualRow,
                      widget.flipped ? 9 - visualCol : visualCol,
                      cellSize,
                      legalTargets,
                    ),
                  ),
              // Animated piece overlay
              if (_animatingMove != null && _animatingPiece != null)
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final fromOffset = _squareToVisualOffset(
                        _animatingMove!.from, cellSize);
                    final toOffset = _squareToVisualOffset(
                        _animatingMove!.to, cellSize);
                    final currentOffset = Offset.lerp(
                        fromOffset, toOffset, _animation.value)!;
                    return Positioned(
                      left: currentOffset.dx,
                      top: currentOffset.dy,
                      width: cellSize,
                      height: cellSize,
                      child: IgnorePointer(
                        child: CheckersPieceWidget(
                          piece: _animatingPiece!,
                          size: cellSize,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCell(
    int row,
    int col,
    double cellSize,
    Set<int> legalTargets,
  ) {
    final squareNum = CheckersBoard.squareFromRowCol(row, col);
    final isDark = squareNum != null;

    // Check if this square is part of the last move
    final isLastMoveSquare = widget.lastMove != null &&
        squareNum != null &&
        (squareNum == widget.lastMove!.from ||
            squareNum == widget.lastMove!.to);

    // Hide piece on 'to' square during animation
    final hideForAnimation = _animatingMove != null &&
        squareNum != null &&
        squareNum == _animatingMove!.to;

    Color bgColor;
    if (!isDark) {
      bgColor = RetroColors.checkersLight;
    } else if (squareNum == widget.selectedSquare) {
      bgColor = RetroColors.primary.withValues(alpha: 0.5);
    } else if (legalTargets.contains(squareNum)) {
      bgColor = RetroColors.secondary.withValues(alpha: 0.35);
    } else if (isLastMoveSquare) {
      bgColor = RetroColors.primary.withValues(alpha: 0.22);
    } else {
      bgColor = RetroColors.checkersDark;
    }

    final piece = squareNum != null ? widget.board.pieceAt(squareNum) : null;

    return GestureDetector(
      onTap: squareNum != null ? () => widget.onSquareTapped(squareNum) : null,
      child: Container(
        color: bgColor,
        child: Stack(
          children: [
            // Legal move indicator (dot).
            if (squareNum != null &&
                legalTargets.contains(squareNum) &&
                piece == null)
              Center(
                child: Container(
                  width: cellSize * 0.28,
                  height: cellSize * 0.28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: RetroColors.secondary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            // Piece.
            if (piece != null && !hideForAnimation)
              CheckersPieceWidget(piece: piece, size: cellSize),
          ],
        ),
      ),
    );
  }
}
