class Seat {
  final String id; // ID của ghế (vd: "A-1", "B-2")
  final String row; // Hàng ghế (A, B, C, ...)
  final int column; // Số cột ghế (1, 2, 3, ...)
  final bool isVip; // Ghế VIP hay không
  bool isBooked; // Ghế đã đặt hay chưa (có thể thay đổi)

  Seat({
    required this.id,
    required this.row,
    required this.column,
    required this.isVip,
    required this.isBooked,
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      id: json['id'],
      row: json['row'],
      column: json['column'],
      isVip: json['isVip'],
      isBooked: json['isBooked'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'row': row,
      'column': column,
      'isVip': isVip,
      'isBooked': isBooked,
    };
  }
}
