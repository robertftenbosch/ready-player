import 'package:flutter/material.dart';

import '../../core/theme/retro_colors.dart';

class PowderSelector extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const PowderSelector({
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
            'POWDER:',
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
              activeTrackColor: RetroColors.accent,
              inactiveTrackColor: RetroColors.accentDim,
              thumbColor: RetroColors.cannonBall,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 6,
              ),
              trackHeight: 4,
              overlayColor: RetroColors.primaryGlow,
            ),
            child: Slider(
              value: value,
              min: 10,
              max: 100,
              divisions: 90,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '${value.toInt()}%',
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
