import 'package:flutter/material.dart';

import '../../core/theme/retro_colors.dart';
import '../models/wind.dart';

class WindIndicator extends StatelessWidget {
  final Wind wind;

  const WindIndicator({super.key, required this.wind});

  @override
  Widget build(BuildContext context) {
    final arrow = wind.speed.abs() < 0.1
        ? '--'
        : wind.speed < 0
            ? '<< '
            : ' >>';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: RetroColors.surface,
        border: Border.all(color: RetroColors.wind, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'WIND: ',
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 7,
              color: RetroColors.wind,
            ),
          ),
          Text(
            arrow,
            style: const TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 7,
              color: RetroColors.wind,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            wind.description,
            style: const TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 7,
              color: RetroColors.wind,
            ),
          ),
        ],
      ),
    );
  }
}
