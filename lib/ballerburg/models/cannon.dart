import 'dart:ui';

class Cannon {
  final double angle;
  final double powder;
  final Offset position;

  const Cannon({
    required this.angle,
    required this.powder,
    required this.position,
  });

  Cannon copyWith({
    double? angle,
    double? powder,
    Offset? position,
  }) {
    return Cannon(
      angle: (angle ?? this.angle).clamp(20.0, 80.0),
      powder: (powder ?? this.powder).clamp(10.0, 100.0),
      position: position ?? this.position,
    );
  }
}
