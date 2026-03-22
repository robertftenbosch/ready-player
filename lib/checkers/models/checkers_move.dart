class CheckersMove {
  /// Starting square number (1-50).
  final int from;

  /// Ending square number (1-50).
  final int to;

  /// Square numbers of captured pieces (empty for simple moves).
  final List<int> captures;

  /// Intermediate landing squares during a multi-capture (excluding [from]
  /// and [to]).
  final List<int> path;

  const CheckersMove({
    required this.from,
    required this.to,
    this.captures = const [],
    this.path = const [],
  });

  bool get isCapture => captures.isNotEmpty;
  bool get isSimple => captures.isEmpty;
  int get captureCount => captures.length;

  /// Standard draughts notation.
  /// Simple move: "16-21"
  /// Capture: "16x27" or multi-capture "16x27x38"
  String toNotation() {
    if (isSimple) {
      return '$from-$to';
    }
    final allSquares = [from, ...path, to];
    return allSquares.join('x');
  }

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'captures': captures,
        'path': path,
      };

  factory CheckersMove.fromJson(Map<String, dynamic> json) {
    return CheckersMove(
      from: json['from'] as int,
      to: json['to'] as int,
      captures: (json['captures'] as List?)?.cast<int>() ?? const [],
      path: (json['path'] as List?)?.cast<int>() ?? const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckersMove &&
          from == other.from &&
          to == other.to &&
          _listEquals(captures, other.captures) &&
          _listEquals(path, other.path);

  @override
  int get hashCode => from.hashCode ^ to.hashCode ^ captures.length;

  @override
  String toString() => toNotation();

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
