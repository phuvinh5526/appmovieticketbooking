import 'package:cloud_firestore/cloud_firestore.dart';
import '../Model/Showtime.dart';
import '../Model/Room.dart';
import '../Model/Cinema.dart';
import '../Model/Seat.dart';
import 'package:intl/intl.dart';

class ShowtimeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tạo lịch chiếu mới
  Future<void> createShowtime(Showtime showtime) async {
    try {
      await _firestore
          .collection('showtimes')
          .doc(showtime.id)
          .set(showtime.toJson());
    } catch (e) {
      print('Error creating showtime: $e');
      throw e;
    }
  }

  // Lấy thông tin lịch chiếu theo ID
  Future<Showtime?> getShowtimeById(String showtimeId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('showtimes').doc(showtimeId).get();
      if (doc.exists) {
        return Showtime.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting showtime: $e');
      throw e;
    }
  }

  // Cập nhật thông tin lịch chiếu
  Future<void> updateShowtime(
      String showtimeId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('showtimes').doc(showtimeId).update(data);
    } catch (e) {
      print('Error updating showtime: $e');
      throw e;
    }
  }

  // Xóa lịch chiếu
  Future<void> deleteShowtime(String showtimeId) async {
    try {
      await _firestore.collection('showtimes').doc(showtimeId).delete();
    } catch (e) {
      print('Error deleting showtime: $e');
      throw e;
    }
  }

  // Lấy tất cả suất chiếu từ Firebase
  Stream<List<Showtime>> getAllShowtimes() {
    try {
      return _firestore.collection('showtimes').snapshots().map((snapshot) {
        List<Showtime> showtimeList = [];
        for (var doc in snapshot.docs) {
          try {
            final data = doc.data();
            // Chuyển đổi timestamp sang DateTime
            DateTime startTime;
            try {
              if (data['startTime'] is Timestamp) {
                startTime = (data['startTime'] as Timestamp).toDate();
              } else {
                // Nếu không phải timestamp, thử parse từ chuỗi hoặc số
                startTime = DateTime.parse(data['startTime'].toString());
              }
            } catch (e) {
              print("Lỗi khi parse startTime: $e");
              startTime = DateTime.now(); // Giá trị mặc định
            }

            // Chuyển đổi bookedSeats từ List dynamic sang List<String>
            List<String> bookedSeats = [];
            if (data['bookedSeats'] != null) {
              bookedSeats = List<String>.from(data['bookedSeats']);
            }

            showtimeList.add(Showtime(
              totalSeats: data['totalSeats'] ?? 0,
              id: doc.id,
              movieId: data['movieId'] ?? '',
              cinemaId: data['cinemaId'] ?? '',
              roomId: data['roomId'] ?? '',
              startTime: startTime,
              bookedSeats: bookedSeats,
            ));
          } catch (e) {
            print('Lỗi khi parse showtime: $e');
          }
        }
        print('Đã tải ${showtimeList.length} suất chiếu từ Firebase');

        // Sắp xếp theo thời gian
        showtimeList.sort((a, b) => a.startTime.compareTo(b.startTime));

        return showtimeList;
      }).handleError((error) {
        print('Lỗi khi lấy dữ liệu suất chiếu: $error');
        // Trả về danh sách rỗng khi có lỗi, để stream không bị đóng
        return <Showtime>[];
      });
    } catch (e) {
      print('Lỗi nghiêm trọng khi tạo stream cho showtimes: $e');
      // Tạo stream trả về danh sách rỗng
      return Stream.value(<Showtime>[]);
    }
  }

  // Lấy danh sách lịch chiếu theo phim
  Stream<List<Showtime>> getShowtimesByMovie(String movieId) {
    return _firestore
        .collection('showtimes')
        .where('movieId', isEqualTo: movieId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Showtime.fromJson(doc.data());
      }).toList();
    });
  }

  // Lấy danh sách lịch chiếu theo rạp
  Stream<List<Showtime>> getShowtimesByCinema(String cinemaId) {
    return _firestore
        .collection('showtimes')
        .where('cinemaId', isEqualTo: cinemaId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Showtime.fromJson(doc.data());
      }).toList();
    });
  }

  // Lấy danh sách lịch chiếu theo phòng chiếu
  Stream<List<Showtime>> getShowtimesByRoom(String roomId) {
    return _firestore
        .collection('showtimes')
        .where('roomId', isEqualTo: roomId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Showtime.fromJson(doc.data());
      }).toList();
    });
  }

  // Lấy danh sách lịch chiếu theo ngày
  Future<List<Showtime>> getShowtimesByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final showtimesSnapshot = await _firestore
          .collection('showtimes')
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      return await Future.wait(showtimesSnapshot.docs.map((doc) async {
        final data = doc.data();
        final roomDoc =
            await _firestore.collection('rooms').doc(data['roomId']).get();
        final roomData = roomDoc.data();
        return Showtime(
          id: doc.id,
          movieId: data['movieId'] as String,
          cinemaId: roomData?['cinemaId'] as String,
          roomId: data['roomId'] as String,
          startTime: (data['startTime'] as Timestamp).toDate(),
          bookedSeats: List<String>.from(data['bookedSeats'] ?? []),
          totalSeats: roomData?['rows'] * roomData?['cols'] ?? 0,
        );
      }));
    } catch (e) {
      print('Error getting showtimes: $e');
      return [];
    }
  }

  // Kiểm tra xem suất chiếu có quá 1 giờ không
  bool _isWithinOneHour(DateTime startTime) {
    final now = DateTime.now();
    final difference = now.difference(startTime);
    print(
        'Kiểm tra suất chiếu: ${startTime.toString()} - Khoảng cách: ${difference.inHours} giờ');
    return difference.inHours < 1;
  }

  // Lấy danh sách suất chiếu theo ID phim và ngày
  Stream<List<Showtime>> getShowtimesByMovieAndDate(
      String movieId, DateTime date) {
    try {
      // Tạo DateTime cho đầu ngày và cuối ngày để lọc
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      print('Tìm suất chiếu từ $startOfDay đến $endOfDay');

      return _firestore
          .collection('showtimes')
          .where('movieId', isEqualTo: movieId)
          .snapshots()
          .asyncMap((snapshot) async {
        List<Showtime> filteredShowtimes = [];

        for (var doc in snapshot.docs) {
          try {
            final data = doc.data();

            // Xử lý trường startTime
            DateTime startTime;
            try {
              if (data['startTime'] is Timestamp) {
                startTime = (data['startTime'] as Timestamp).toDate();
              } else if (data['startTime'] is String) {
                startTime = DateTime.parse(data['startTime']);
              } else {
                print(
                    'Định dạng startTime không xác định: ${data['startTime']}');
                continue;
              }
            } catch (e) {
              print('Lỗi khi parse startTime: $e');
              continue;
            }

            // Chỉ lọc suất chiếu trong ngày được chọn và trong vòng 1 giờ
            bool isInSelectedDate = startTime.year == date.year &&
                startTime.month == date.month &&
                startTime.day == date.day;

            bool isWithinOneHour = _isWithinOneHour(startTime);

            if (!isInSelectedDate || !isWithinOneHour) {
              continue;
            }

            // Chuyển đổi bookedSeats từ List dynamic sang List<String>
            List<String> bookedSeats = [];
            if (data['bookedSeats'] != null) {
              bookedSeats = List<String>.from(data['bookedSeats']);
            }

            // Lấy thông tin phòng
            final roomDoc =
                await _firestore.collection('rooms').doc(data['roomId']).get();
            final roomData = roomDoc.data();

            filteredShowtimes.add(Showtime(
              id: doc.id,
              movieId: data['movieId'] ?? '',
              cinemaId: data['cinemaId'] ?? '',
              roomId: data['roomId'] ?? '',
              startTime: startTime,
              bookedSeats: bookedSeats,
              totalSeats: roomData?['rows'] * roomData?['cols'] ?? 0,
            ));
          } catch (e) {
            print('Lỗi khi parse showtime: $e');
          }
        }

        print(
            'Tìm thấy ${filteredShowtimes.length} suất chiếu cho phim $movieId vào ngày ${DateFormat('dd/MM/yyyy').format(date)}');

        // Sắp xếp theo thời gian
        filteredShowtimes.sort((a, b) => a.startTime.compareTo(b.startTime));

        return filteredShowtimes;
      }).handleError((error) {
        print('Lỗi khi lấy dữ liệu suất chiếu theo phim và ngày: $error');
        return <Showtime>[];
      });
    } catch (e) {
      print('Lỗi nghiêm trọng trong getShowtimesByMovieAndDate: $e');
      return Stream.value(<Showtime>[]);
    }
  }

  // Lấy thông tin phòng chiếu theo ID
  Future<Room> getRoomById(String roomId) async {
    final doc = await _firestore.collection('rooms').doc(roomId).get();
    final data = doc.data();
    if (data == null) {
      throw Exception('Không tìm thấy phòng chiếu');
    }

    List<dynamic> seatLayoutJson = data['seatLayout'] ?? [];
    List<Seat> seatLayout = seatLayoutJson.map((seat) {
      return Seat(
        id: seat['id'] ?? '',
        row: seat['row'] ?? '',
        column: seat['column'] ?? 0,
        isVip: seat['isVip'] ?? false,
        isBooked: seat['isBooked'] ?? false,
      );
    }).toList();

    return Room(
      id: doc.id,
      cinemaId: data['cinemaId'] ?? '',
      name: data['name'] ?? '',
      rows: data['rows'] ?? 0,
      cols: data['cols'] ?? 0,
      seatLayout: seatLayout,
    );
  }

  // Lấy danh sách rạp phim theo tỉnh thành
  Stream<List<Cinema>> getCinemasByProvince(String provinceId) {
    final query = provinceId.isEmpty
        ? _firestore.collection('cinemas')
        : _firestore
            .collection('cinemas')
            .where('provinceId', isEqualTo: provinceId);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Cinema(
          id: doc.id,
          name: data['name'] ?? '',
          provinceId: data['provinceId'] ?? '',
          address: data['address'] ?? '',
        );
      }).toList();
    });
  }

  // Lấy thông tin rạp phim theo ID
  Future<Cinema> getCinemaById(String cinemaId) async {
    final doc = await _firestore.collection('cinemas').doc(cinemaId).get();
    final data = doc.data();
    if (data == null) {
      throw Exception('Không tìm thấy rạp phim');
    }

    return Cinema(
      id: doc.id,
      name: data['name'] ?? '',
      provinceId: data['provinceId'] ?? '',
      address: data['address'] ?? '',
    );
  }

  Future<List<Showtime>> getShowtimesByDateAndCinema(
      DateTime date, String cinemaId) async {
    try {
      // Lấy danh sách phòng của rạp
      final roomsSnapshot = await _firestore
          .collection('rooms')
          .where('cinemaId', isEqualTo: cinemaId)
          .get();

      final roomIds = roomsSnapshot.docs.map((doc) => doc.id).toList();
      if (roomIds.isEmpty) {
        print('No rooms found for cinema: $cinemaId');
        return [];
      }

      // Tạo timestamp cho đầu và cuối ngày
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Lấy danh sách suất chiếu theo thời gian
      final showtimesSnapshot = await _firestore
          .collection('showtimes')
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      print('Found ${showtimesSnapshot.docs.length} showtimes for date: $date');

      // Lọc suất chiếu theo phòng và xử lý dữ liệu
      final showtimes = showtimesSnapshot.docs
          .where((doc) => roomIds.contains(doc.data()['roomId']))
          .map((doc) {
            try {
              final data = doc.data();
              final startTime = data['startTime'] is Timestamp
                  ? (data['startTime'] as Timestamp).toDate()
                  : DateTime.parse(data['startTime'] as String);

              final bookedSeats = List<String>.from(data['bookedSeats'] ?? []);
              return Showtime(
                totalSeats: data['totalSeats'] ?? 0,
                cinemaId: data['cinemaId'] as String,
                id: doc.id,
                movieId: data['movieId'] as String,
                roomId: data['roomId'] as String,
                startTime: startTime,
                bookedSeats: bookedSeats,
              );
            } catch (e) {
              print('Error processing showtime document ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Showtime>()
          .toList();

      // Sắp xếp theo thời gian bắt đầu
      showtimes.sort((a, b) => a.startTime.compareTo(b.startTime));

      print('Processed ${showtimes.length} valid showtimes');
      return showtimes;
    } catch (e) {
      print('Error getting showtimes: $e');
      return [];
    }
  }

  // Cập nhật danh sách ghế đã đặt - Hỗ trợ Transaction
  Future<void> updateBookedSeats(
      String showtimeId, List<String> selectedSeats, {Transaction? transaction}) async {
    try {
      DocumentReference showtimeRef = _firestore.collection('showtimes').doc(showtimeId);
      
      DocumentSnapshot showtimeDoc;
      if (transaction != null) {
        showtimeDoc = await transaction.get(showtimeRef);
      } else {
        showtimeDoc = await showtimeRef.get();
      }

      if (!showtimeDoc.exists) {
        throw Exception('Không tìm thấy suất chiếu');
      }

      Map<String, dynamic> data = showtimeDoc.data() as Map<String, dynamic>;
      List<String> currentBookedSeats =
          List<String>.from(data['bookedSeats'] ?? []);

      // Kiểm tra xem có ghế nào đã được đặt chưa
      for (String seat in selectedSeats) {
        if (currentBookedSeats.contains(seat)) {
          throw Exception('Ghế $seat đã được đặt bởi người khác');
        }
      }

      // Thêm các ghế mới vào danh sách
      currentBookedSeats.addAll(selectedSeats);

      // Cập nhật lại showtime
      if (transaction != null) {
        transaction.update(showtimeRef, {'bookedSeats': currentBookedSeats});
      } else {
        await showtimeRef.update({'bookedSeats': currentBookedSeats});
      }
    } catch (e) {
      print('Error updating booked seats: $e');
      throw e;
    }
  }
}
