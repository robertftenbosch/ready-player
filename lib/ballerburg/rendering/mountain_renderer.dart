import 'dart:ui';

import 'package:flutter/painting.dart';

import '../../core/theme/retro_colors.dart';
import '../models/mountain.dart';

class MountainRenderer {
  static void paint(Canvas canvas, Mountain mountain, Size size) {
    if (mountain.heightMap.isEmpty) return;

    final path = Path();
    path.moveTo(0, size.height);

    for (int i = 0; i < mountain.heightMap.length; i++) {
      path.lineTo(i.toDouble(), mountain.heightMap[i]);
    }

    path.lineTo(size.width, size.height);
    path.close();

    final mountainPaint = Paint()
      ..isAntiAlias = false
      ..color = RetroColors.mountain;
    canvas.drawPath(path, mountainPaint);

    // Add some pixel texture lines for depth
    final texturePaint = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFF1A3300)
      ..strokeWidth = 1.0;

    for (int i = 0; i < mountain.heightMap.length; i += 6) {
      final h = mountain.heightMap[i];
      if (h < size.height - 10) {
        canvas.drawRect(
          Rect.fromLTWH(i.toDouble(), h + 3, 3, 1),
          texturePaint,
        );
      }
    }
  }
}
