enum CheckersColor { white, black }

enum CheckersPieceType { man, king }

class CheckersPiece {
  final CheckersColor color;
  final CheckersPieceType type;

  const CheckersPiece(this.color, this.type);

  CheckersPiece promoted() => CheckersPiece(color, CheckersPieceType.king);

  bool get isKing => type == CheckersPieceType.king;
  bool get isMan => type == CheckersPieceType.man;

  Map<String, dynamic> toJson() => {
        'color': color.name,
        'type': type.name,
      };

  factory CheckersPiece.fromJson(Map<String, dynamic> json) {
    return CheckersPiece(
      CheckersColor.values.byName(json['color'] as String),
      CheckersPieceType.values.byName(json['type'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckersPiece && color == other.color && type == other.type;

  @override
  int get hashCode => color.hashCode ^ type.hashCode;

  @override
  String toString() => '${color.name} ${type.name}';
}
