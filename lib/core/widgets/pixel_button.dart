import 'package:flutter/material.dart';
import '../theme/retro_colors.dart';
import 'pixel_border.dart';

class PixelButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color color;
  final double fontSize;

  const PixelButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color = RetroColors.primary,
    this.fontSize = 8,
  });

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: Transform.translate(
        offset: _pressed ? const Offset(2, 2) : Offset.zero,
        child: PixelBorder(
          color: widget.onPressed != null
              ? widget.color
              : widget.color.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            widget.text,
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: widget.fontSize,
              color: widget.onPressed != null
                  ? widget.color
                  : widget.color.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}
