import 'package:intl/intl.dart';
import 'package:movieticketbooking/Model/Room.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Showtime {
  final String id;
  final String movieId;
  final String cinemaId;
  final String roomId;
  final DateTime startTime;
  final List<String> bookedSeats;
  final int totalSeats;

  Showtime({
    required this.id,
    required this.movieId,
    required this.cinemaId,
    required this.roomId,
    required this.startTime,
    required this.bookedSeats,
    required this.totalSeats,
  });

  // Getter để định dạng ngày giờ theo "dd/MM/yyyy HH:mm"
  String get formattedTime {
    return DateFormat('HH:mm').format(startTime);
  }

  String get formattedDate {
    return DateFormat('dd/MM/yyyy').format(startTime);
  }

  // Số ghế đã đặt
  int get bookedSeatsCount {
    return bookedSeats.length;
  }

  // Tính số ghế còn trống
  int get remainingSeats {
    // Chỉ trả về số ghế đã đặt, giá trị âm không cần dùng với UI
    return bookedSeats.length;
  }

  int get availableSeatsCount => totalSeats - bookedSeats.length;

  // Phương thức để lấy thông tin phòng từ Firebase
  Future<Room?> getRoom() async {
    try {
      DocumentSnapshot roomDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .get();

      if (roomDoc.exists) {
        Map<String, dynamic> data = roomDoc.data() as Map<String, dynamic>;
        return Room(
          id: roomDoc.id,
          cinemaId: data['cinemaId'] ?? '',
          name: data['name'] ?? '',
          rows: data['rows'] ?? 0,
          cols: data['cols'] ?? 0,
          seatLayout: [], // Không cần thiết cho hiển thị
        );
      }
      return null;
    } catch (e) {
      print('Lỗi khi lấy thông tin phòng: $e');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movieId': movieId,
      'cinemaId': cinemaId,
      'roomId': roomId,
      'startTime': startTime.toIso8601String(),
      'bookedSeats': bookedSeats,
    };
  }

  factory Showtime.fromJson(Map<String, dynamic> json) {
    DateTime parseStartTime(dynamic startTime) {
      if (startTime is Timestamp) {
        return startTime.toDate();
      } else if (startTime is String) {
        return DateTime.parse(startTime);
      }
      throw FormatException('Invalid startTime format');
    }

    return Showtime(
      id: json['id'] ?? '',
      movieId: json['movieId'] ?? '',
      cinemaId: json['cinemaId'] ?? '',
      roomId: json['roomId'] ?? '',
      startTime: parseStartTime(json['startTime']),
      bookedSeats: List<String>.from(json['bookedSeats'] ?? []),
      totalSeats: json['totalSeats'] ?? 0,
    );
  }

  Showtime copyWith({
    String? id,
    String? movieId,
    String? cinemaId,
    String? roomId,
    DateTime? startTime,
    List<String>? bookedSeats,
    int? totalSeats,
  }) {
    return Showtime(
      id: id ?? this.id,
      movieId: movieId ?? this.movieId,
      cinemaId: cinemaId ?? this.cinemaId,
      roomId: roomId ?? this.roomId,
      startTime: startTime ?? this.startTime,
      bookedSeats: bookedSeats ?? this.bookedSeats,
      totalSeats: totalSeats ?? this.totalSeats,
    );
  }
}
