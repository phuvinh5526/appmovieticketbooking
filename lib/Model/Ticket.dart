import 'Showtime.dart';

class Ticket {
  final String id;
  final String userId;
  final Showtime showtime;
  final List<String> selectedSeats;
  final Map<String, int> selectedFoods;
  final double totalPrice;
  final bool isUsed;

  Ticket({
    required this.id,
    required this.userId,
    required this.showtime,
    required this.selectedSeats,
    required this.selectedFoods,
    required this.totalPrice,
    required this.isUsed,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      userId: json['userId'],
      showtime: Showtime.fromJson(json['showtime']),
      selectedSeats: List<String>.from(json['selectedSeats'] ?? []),
      selectedFoods: Map<String, int>.from(json['selectedFoods'] ?? {}),
      totalPrice: json['totalPrice'].toDouble(),
      isUsed: json['isUsed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'showtime': showtime.toJson(),
      'selectedSeats': selectedSeats,
      'selectedFoods': selectedFoods, // Truyền Map<String, int> vào JSON
      'totalPrice': totalPrice,
      'isUsed': isUsed,
    };
  }
}
