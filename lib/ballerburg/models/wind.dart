class Wind {
  final double speed;

  const Wind({required this.speed});

  Map<String, dynamic> toJson() => {'speed': speed};

  factory Wind.fromJson(Map<String, dynamic> json) {
    return Wind(speed: (json['speed'] as num).toDouble());
  }

  String get description {
    if (speed.abs() < 0.1) return 'CALM';
    final dir = speed < 0 ? 'LEFT' : 'RIGHT';
    return '${speed.abs().toStringAsFixed(1)} m/s $dir';
  }
}
