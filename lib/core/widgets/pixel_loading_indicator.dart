import 'package:flutter/material.dart';
import '../theme/retro_colors.dart';

class PixelLoadingIndicator extends StatefulWidget {
  final Color color;
  final int blockCount;
  final double blockSize;

  const PixelLoadingIndicator({
    super.key,
    this.color = RetroColors.primary,
    this.blockCount = 5,
    this.blockSize = 8,
  });

  @override
  State<PixelLoadingIndicator> createState() => _PixelLoadingIndicatorState();
}

class _PixelLoadingIndicatorState extends State<PixelLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final activeIndex =
            (_controller.value * widget.blockCount).floor() % widget.blockCount;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.blockCount, (i) {
            return Container(
              width: widget.blockSize,
              height: widget.blockSize,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              color: i == activeIndex
                  ? widget.color
                  : widget.color.withValues(alpha: 0.2),
            );
          }),
        );
      },
    );
  }
}
