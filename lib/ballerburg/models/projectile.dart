import 'dart:ui';

class Projectile {
  final List<Offset> trajectory;
  final int currentIndex;

  const Projectile({
    required this.trajectory,
    this.currentIndex = 0,
  });

  Offset get currentPosition {
    if (trajectory.isEmpty) return Offset.zero;
    return trajectory[currentIndex.clamp(0, trajectory.length - 1)];
  }

  bool get isFinished => currentIndex >= trajectory.length - 1;

  Projectile advance([int steps = 1]) {
    return Projectile(
      trajectory: trajectory,
      currentIndex: (currentIndex + steps).clamp(0, trajectory.length - 1),
    );
  }
}
