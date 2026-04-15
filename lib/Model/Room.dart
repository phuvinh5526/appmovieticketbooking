import 'Seat.dart';

class Room {
  final String id;
  final String cinemaId; // Thuộc rạp nào
  final String name; // Tên phòng (phòng 1, phòng 2, ...)
  final int rows; // Số hàng ghế
  final int cols; // Số cột ghế
  final List<Seat> seatLayout; // Danh sách ghế

  Room({
    required this.id,
    required this.cinemaId,
    required this.name,
    required this.rows,
    required this.cols,
    required this.seatLayout,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      cinemaId: json['cinemaId'],
      name: json['name'],
      rows: json['rows'],
      cols: json['cols'],
      seatLayout: (json['seatLayout'] as List)
          .map((seat) => Seat.fromJson(seat))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cinemaId': cinemaId,
      'name': name,
      'rows': rows,
      'cols': cols,
      'seatLayout': seatLayout.map((seat) => seat.toJson()).toList(),
    };
  }
}

List<Seat> generateSeats(int rows, int cols) {
  List<Seat> seats = [];
  List<String> rowLabels =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split(""); // Tạo danh sách A-Z

  for (int r = 0; r < rows; r++) {
    for (int c = 1; c <= cols; c++) {
      seats.add(Seat(
        id: "${r + 1}-$c",
        row: rowLabels[r],
        column: c,
        isVip: r < r - r / 3, // 3 hàng đầu là VIP
        isBooked: false, // Mặc định tất cả ghế chưa được đặt
      ));
    }
  }
  return seats;
}
