import 'package:flutter/material.dart';

import '../../core/theme/retro_colors.dart';

class AngleSelector extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const AngleSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 70,
          child: Text(
            'ANGLE:',
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 8,
              color: RetroColors.primary,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: RetroColors.primary,
              inactiveTrackColor: RetroColors.primaryDim,
              thumbColor: RetroColors.cannonBall,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 6,
              ),
              trackHeight: 4,
              overlayColor: RetroColors.primaryGlow,
            ),
            child: Slider(
              value: value,
              min: 20,
              max: 80,
              divisions: 60,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '${value.toInt()}°',
            style: const TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 8,
              color: RetroColors.secondary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
