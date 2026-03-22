import 'package:flutter/material.dart';

import '../../core/theme/retro_colors.dart';

class ChessMoveLog extends StatelessWidget {
  final List<String> moves;

  const ChessMoveLog({
    super.key,
    required this.moves,
  });

  @override
  Widget build(BuildContext context) {
    final moveCount = (moves.length + 1) ~/ 2;

    return Container(
      decoration: BoxDecoration(
        color: RetroColors.surface,
        border: Border.all(color: RetroColors.primaryDim, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(8),
      child: moves.isEmpty
          ? Text(
              'No moves yet',
              style: TextStyle(
                color: RetroColors.textMuted,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              itemCount: moveCount,
              itemBuilder: (context, index) {
                final whiteIdx = index * 2;
                final blackIdx = index * 2 + 1;
                final moveNum = index + 1;
                final whiteMove = moves[whiteIdx];
                final blackMove =
                    blackIdx < moves.length ? moves[blackIdx] : '';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(
                          '$moveNum.',
                          style: const TextStyle(
                            color: RetroColors.textMuted,
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 64,
                        child: Text(
                          whiteMove,
                          style: const TextStyle(
                            color: RetroColors.textPrimary,
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 64,
                        child: Text(
                          blackMove,
                          style: const TextStyle(
                            color: RetroColors.secondary,
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
