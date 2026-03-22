import 'package:flutter/material.dart';
import '../theme/retro_colors.dart';
import 'pixel_border.dart';

class GameOverDialog extends StatelessWidget {
  final String title;
  final String message;
  final Color color;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const GameOverDialog({
    super.key,
    required this.title,
    required this.message,
    this.color = RetroColors.primary,
    required this.onPlayAgain,
    required this.onExit,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    Color color = RetroColors.primary,
    required VoidCallback onPlayAgain,
    required VoidCallback onExit,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameOverDialog(
        title: title,
        message: message,
        color: color,
        onPlayAgain: onPlayAgain,
        onExit: onExit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: PixelBorder(
        color: color,
        padding: const EdgeInsets.all(24),
        child: Container(
          color: RetroColors.background,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GAME OVER',
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 14,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 10,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 6,
                  color: RetroColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RetroButton(
                    text: 'AGAIN',
                    color: RetroColors.primary,
                    onTap: () {
                      Navigator.of(context).pop();
                      onPlayAgain();
                    },
                  ),
                  const SizedBox(width: 16),
                  _RetroButton(
                    text: 'EXIT',
                    color: RetroColors.accent,
                    onTap: () {
                      Navigator.of(context).pop();
                      onExit();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RetroButton extends StatefulWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;

  const _RetroButton({
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  State<_RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<_RetroButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: Transform.translate(
        offset: _pressed ? const Offset(1, 1) : Offset.zero,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: widget.color, width: 2),
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 8,
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}
