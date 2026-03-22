import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ballerburg_game_state.dart';
import '../providers/ballerburg_provider.dart';
import '../rendering/ballerburg_painter.dart';

class BallerburgCanvas extends ConsumerStatefulWidget {
  final BallerburgGameState gameState;

  const BallerburgCanvas({super.key, required this.gameState});

  @override
  ConsumerState<BallerburgCanvas> createState() => _BallerburgCanvasState();
}

class _BallerburgCanvasState extends ConsumerState<BallerburgCanvas> {
  bool _sizeInitialized = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        if (!_sizeInitialized && width > 0 && height > 0) {
          _sizeInitialized = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref
                .read(ballerburgGameProvider.notifier)
                .updateCanvasSize(width, height);
          });
        }

        return ClipRect(
          child: CustomPaint(
            size: Size(width, height),
            painter: BallerburgPainter(gameState: widget.gameState),
          ),
        );
      },
    );
  }
}
