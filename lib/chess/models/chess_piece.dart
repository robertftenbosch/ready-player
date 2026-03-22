enum PieceColor { white, black }

enum PieceType { pawn, knight, bishop, rook, queen, king }

class ChessPiece {
  final PieceType type;
  final PieceColor color;

  const ChessPiece(this.type, this.color);

  String get symbol {
    switch (color) {
      case PieceColor.white:
        switch (type) {
          case PieceType.king:
            return '♔';
          case PieceType.queen:
            return '♕';
          case PieceType.rook:
            return '♖';
          case PieceType.bishop:
            return '♗';
          case PieceType.knight:
            return '♘';
          case PieceType.pawn:
            return '♙';
        }
      case PieceColor.black:
        switch (type) {
          case PieceType.king:
            return '♚';
          case PieceType.queen:
            return '♛';
          case PieceType.rook:
            return '♜';
          case PieceType.bishop:
            return '♝';
          case PieceType.knight:
            return '♞';
          case PieceType.pawn:
            return '♟';
        }
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'color': color.name,
      };

  factory ChessPiece.fromJson(Map<String, dynamic> json) {
    return ChessPiece(
      PieceType.values.byName(json['type'] as String),
      PieceColor.values.byName(json['color'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChessPiece && type == other.type && color == other.color;

  @override
  int get hashCode => type.hashCode ^ color.hashCode;

  @override
  String toString() => '${color.name} ${type.name}';
}
