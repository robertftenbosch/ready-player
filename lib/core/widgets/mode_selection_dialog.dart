import 'package:flutter/material.dart';
import '../theme/retro_colors.dart';
import '../models/game_mode.dart';
import 'pixel_border.dart';

class ModeSelectionDialog extends StatelessWidget {
  final String gameTitle;

  const ModeSelectionDialog({super.key, required this.gameTitle});

  static Future<GameMode?> show(BuildContext context, {required String gameTitle}) {
    return showDialog<GameMode>(
      context: context,
      builder: (_) => ModeSelectionDialog(gameTitle: gameTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: PixelBorder(
        color: RetroColors.primary,
        padding: const EdgeInsets.all(24),
        child: Container(
          color: RetroColors.background,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                gameTitle,
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 12,
                  color: RetroColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'SELECT MODE',
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 8,
                  color: RetroColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              _ModeButton(
                icon: Icons.smart_toy,
                label: 'VS AI',
                description: 'Play against LLM',
                color: RetroColors.primary,
                onTap: () => Navigator.of(context).pop(GameMode.vsAi),
              ),
              const SizedBox(height: 12),
              _ModeButton(
                icon: Icons.people,
                label: 'VS PLAYER',
                description: 'Local multiplayer',
                color: RetroColors.secondary,
                onTap: () => Navigator.of(context).pop(GameMode.vsPlayer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ModeButton> createState() => _ModeButtonState();
}

class _ModeButtonState extends State<_ModeButton> {
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
        offset: _pressed ? const Offset(2, 2) : Offset.zero,
        child: PixelBorder(
          color: widget.color,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: widget.color, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 10,
                      color: widget.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.description,
                    style: TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 5,
                      color: widget.color.withValues(alpha: 0.6),
                    ),
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
