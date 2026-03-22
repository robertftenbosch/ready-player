import 'dart:math';

import '../models/mountain.dart';

class TerrainGenerator {
  static Mountain generate(double width, double baseHeight, double peakHeight) {
    final rng = Random();
    final numPoints = width.toInt();
    final heightMap = List<double>.filled(numPoints, 0.0);

    final center = width / 2;
    final spread = width * 0.25;

    // Sum of sine waves for natural look
    final phase1 = rng.nextDouble() * pi;
    final phase2 = rng.nextDouble() * pi;
    final phase3 = rng.nextDouble() * pi;

    for (int i = 0; i < numPoints; i++) {
      final x = i.toDouble();
      final distFromCenter = (x - center).abs();

      // Gaussian-ish envelope so mountain peaks in center
      final envelope = exp(-0.5 * pow(distFromCenter / spread, 2));

      // Sine wave layers for texture
      final wave1 = sin(x / width * pi * 2 + phase1) * 0.3;
      final wave2 = sin(x / width * pi * 4 + phase2) * 0.15;
      final wave3 = sin(x / width * pi * 8 + phase3) * 0.05;

      // Small random noise
      final noise = (rng.nextDouble() - 0.5) * 0.05;

      final normalizedHeight = envelope * (1.0 + wave1 + wave2 + wave3 + noise);
      final mountainHeight = normalizedHeight * (peakHeight - baseHeight);

      // Height is measured from top of canvas, so subtract from canvas height
      heightMap[i] = baseHeight - mountainHeight.clamp(0.0, peakHeight);
    }

    return Mountain(heightMap: heightMap);
  }
}
