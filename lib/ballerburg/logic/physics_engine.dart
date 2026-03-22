import 'dart:math';
import 'dart:ui';

class PhysicsEngine {
  static const double gravity = 200.0;
  static const double dt = 0.02;

  static List<Offset> computeTrajectory({
    required Offset start,
    required double angleDeg,
    required double powder,
    required double windSpeed,
    required double canvasWidth,
    required double canvasHeight,
    required bool firingRight,
  }) {
    final v0 = powder * 3.0;
    final angleRad = angleDeg * pi / 180.0;

    // If firing right, vx is positive; if firing left, vx is negative
    double vx = v0 * cos(angleRad) * (firingRight ? 1.0 : -1.0);
    double vy = -v0 * sin(angleRad); // negative because screen y is inverted

    final windAccel = windSpeed * 15.0;

    double x = start.dx;
    double y = start.dy;

    final points = <Offset>[Offset(x, y)];

    for (int i = 0; i < 10000; i++) {
      x += vx * dt + 0.5 * windAccel * dt * dt;
      y += vy * dt + 0.5 * gravity * dt * dt;

      vx += windAccel * dt;
      vy += gravity * dt;

      points.add(Offset(x, y));

      // Stop if off screen
      if (y > canvasHeight + 50 || x < -50 || x > canvasWidth + 50) {
        break;
      }
    }

    return points;
  }
}
