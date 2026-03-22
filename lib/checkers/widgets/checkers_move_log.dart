import 'package:flutter/material.dart';

import '../../core/theme/retro_colors.dart';

class CheckersMoveLog extends StatefulWidget {
  final List<String> moves;

  const CheckersMoveLog({super.key, required this.moves});

  @override
  State<CheckersMoveLog> createState() => _CheckersMoveLogState();
}

class _CheckersMoveLogState extends State<CheckersMoveLog> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant CheckersMoveLog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.moves.length != oldWidget.moves.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.moves.isEmpty) {
      return const Center(
        child: Text(
          'NO MOVES YET',
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 8,
            color: RetroColors.textMuted,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: RetroColors.surface,
        border: Border.all(color: RetroColors.primaryDim, width: 1),
      ),
      padding: const EdgeInsets.all(8),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: (widget.moves.length + 1) ~/ 2,
        itemBuilder: (context, index) {
          final moveNum = index + 1;
          final whiteIdx = index * 2;
          final blackIdx = index * 2 + 1;

          final whiteMove = widget.moves[whiteIdx];
          final blackMove =
              blackIdx < widget.moves.length ? widget.moves[blackIdx] : '';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '$moveNum.',
                    style: const TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 7,
                      color: RetroColors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    whiteMove,
                    style: const TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 7,
                      color: RetroColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    blackMove,
                    style: const TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 7,
                      color: RetroColors.secondary,
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
