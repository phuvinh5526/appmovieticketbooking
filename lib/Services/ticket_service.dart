import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movieticketbooking/Model/Ticket.dart';
import 'package:movieticketbooking/Services/showtime_service.dart';
import 'package:intl/intl.dart';
import 'package:movieticketbooking/Model/Food.dart';

class TicketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _ticketsCollection =
      FirebaseFirestore.instance.collection('tickets');
  final ShowtimeService _showtimeService = ShowtimeService();

  // Tạo vé mới và cập nhật ghế đã đặt
  Future<void> createTicket(Ticket ticket) async {
    try {
      // Bắt đầu transaction để đảm bảo tính nhất quán của dữ liệu
      await _firestore.runTransaction((transaction) async {
        // 1. Cập nhật danh sách ghế đã đặt trong showtime bằng transaction
        await _showtimeService.updateBookedSeats(
          ticket.showtime.id,
          ticket.selectedSeats,
          transaction: transaction,
        );

        // 2. Tạo vé mới
        transaction.set(
          _firestore.collection('tickets').doc(ticket.id),
          ticket.toJson(),
        );
      });
    } catch (e) {
      print('Error creating ticket: $e');
      rethrow;
    }
  }

  // Lấy thông tin vé theo ID
  Future<Ticket?> getTicketById(String ticketId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('tickets').doc(ticketId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Ticket.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting ticket: $e');
      throw e;
    }
  }

  // Cập nhật thông tin vé
  Future<void> updateTicket(String ticketId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('tickets').doc(ticketId).update(data);
    } catch (e) {
      print('Error updating ticket: $e');
      rethrow;
    }
  }

  // Xóa vé
  Future<void> deleteTicket(String ticketId) async {
    try {
      await _firestore.collection('tickets').doc(ticketId).delete();
    } catch (e) {
      print('Error deleting ticket: $e');
      rethrow;
    }
  }

  // Lấy danh sách tất cả vé
  Stream<List<Ticket>> getAllTickets() {
    return _firestore.collection('tickets').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Ticket.fromJson(data);
      }).toList();
    });
  }

  // Lấy danh sách vé theo người dùng
  Stream<List<Ticket>> getTicketsByUserId(String userId) {
    return _ticketsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      List<Ticket> tickets = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Ticket.fromJson(data);
      }).toList();
      
      // Sắp xếp thủ công nếu không có index trong Firestore
      tickets.sort((a, b) => b.showtime.startTime.compareTo(a.showtime.startTime));
      return tickets;
    });
  }

  // Cập nhật trạng thái vé
  Future<void> updateTicketStatus(String ticketId, bool isUsed) async {
    try {
      await _firestore.collection('tickets').doc(ticketId).update({
        'isUsed': isUsed,
      });
    } catch (e) {
      print('Error updating ticket status: $e');
      throw e;
    }
  }

  // Lấy thống kê doanh thu theo khoảng thời gian
  Future<Map<String, dynamic>> getRevenueStats(
      DateTime startDate, DateTime endDate) async {
    try {
      print('Querying tickets from ${startDate} to ${endDate}'); // Debug log

      // Lấy tất cả tickets và lọc theo thời gian
      final QuerySnapshot ticketsSnapshot = await _ticketsCollection.get();

      print('Found total ${ticketsSnapshot.docs.length} tickets'); // Debug log

      double totalRevenue = 0;
      int ticketCount = 0;
      Map<String, double> dailyRevenue = {};

      for (var doc in ticketsSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          print('Processing ticket: ${doc.id}'); // Debug log
          print('Ticket data: ${data}'); // Debug log

          // Kiểm tra cấu trúc dữ liệu
          if (data['showtime'] == null) {
            print('Ticket ${doc.id} has no showtime data');
            continue;
          }

          final showtime = data['showtime'] as Map<String, dynamic>;
          if (showtime['startTime'] == null) {
            print('Ticket ${doc.id} has no startTime');
            continue;
          }

          // Xử lý startTime dạng String
          DateTime startTime;
          try {
            if (showtime['startTime'] is String) {
              startTime = DateTime.parse(showtime['startTime']);
            } else if (showtime['startTime'] is Timestamp) {
              startTime = (showtime['startTime'] as Timestamp).toDate();
            } else {
              print('Invalid startTime format for ticket ${doc.id}');
              continue;
            }
          } catch (e) {
            print('Error parsing startTime for ticket ${doc.id}: $e');
            continue;
          }

          // Chỉ xử lý tickets trong khoảng thời gian
          if (startTime.isBefore(startDate) || startTime.isAfter(endDate)) {
            continue;
          }

          // Lấy tổng tiền từ totalPrice hoặc totalAmount
          double totalAmount = 0;
          if (data['totalPrice'] != null) {
            totalAmount = (data['totalPrice'] as num).toDouble();
          } else if (data['totalAmount'] != null) {
            totalAmount = (data['totalAmount'] as num).toDouble();
          }

          // Tính tổng doanh thu
          totalRevenue += totalAmount;
          ticketCount++;

          // Thống kê theo ngày
          String dateKey = DateFormat('dd/MM').format(startTime);
          dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0) + totalAmount;

          print(
              'Processed ticket: ${doc.id}, amount: ${totalAmount}, date: ${dateKey}'); // Debug log
        } catch (e) {
          print('Error processing ticket ${doc.id}: $e');
          continue;
        }
      }

      print(
          'Total revenue: ${totalRevenue}, Ticket count: ${ticketCount}'); // Debug log
      print('Daily revenue: ${dailyRevenue}'); // Debug log

      return {
        'totalRevenue': totalRevenue,
        'ticketCount': ticketCount,
        'dailyRevenue': dailyRevenue,
      };
    } catch (e) {
      print('Error getting revenue stats: $e');
      return {
        'totalRevenue': 0.0,
        'ticketCount': 0,
        'dailyRevenue': {},
      };
    }
  }

  // Lấy thống kê doanh thu theo ngày
  Future<Map<String, dynamic>> getDailyRevenue(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      print(
          'Getting daily revenue for ${DateFormat('dd/MM/yyyy').format(date)}');

      final result = await getRevenueStats(startOfDay, endOfDay);

      // Đảm bảo kết quả có định dạng đúng cho thống kê theo ngày
      return {
        'totalRevenue': result['totalRevenue'] ?? 0.0,
        'ticketCount': result['ticketCount'] ?? 0,
        'dailyRevenue': result['dailyRevenue'] ?? {},
      };
    } catch (e) {
      print('Error in getDailyRevenue: $e');
      return {
        'totalRevenue': 0.0,
        'ticketCount': 0,
        'dailyRevenue': {},
      };
    }
  }

  // Lấy thống kê doanh thu theo tháng
  Future<Map<String, dynamic>> getMonthlyRevenue(DateTime date) async {
    try {
      final startOfMonth = DateTime(date.year, date.month, 1);
      final endOfMonth = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
      print(
          'Getting monthly revenue for ${DateFormat('MM/yyyy').format(date)}');

      final result = await getRevenueStats(startOfMonth, endOfMonth);

      // Đảm bảo kết quả có định dạng đúng cho thống kê theo tháng
      return {
        'totalRevenue': result['totalRevenue'] ?? 0.0,
        'ticketCount': result['ticketCount'] ?? 0,
        'monthlyRevenue': result['dailyRevenue'] ?? {},
      };
    } catch (e) {
      print('Error in getMonthlyRevenue: $e');
      return {
        'totalRevenue': 0.0,
        'ticketCount': 0,
        'monthlyRevenue': {},
      };
    }
  }

  // Lấy thống kê doanh thu theo năm
  Future<Map<String, dynamic>> getYearlyRevenue(DateTime date) async {
    try {
      final startOfYear = DateTime(date.year, 1, 1);
      final endOfYear = DateTime(date.year, 12, 31, 23, 59, 59);
      print('Getting yearly revenue for ${date.year}');

      final result = await getRevenueStats(startOfYear, endOfYear);

      // Tổ chức lại dữ liệu theo tháng cho thống kê năm
      Map<String, double> yearlyRevenue = {};
      if (result['dailyRevenue'] != null) {
        final dailyData = result['dailyRevenue'] as Map<String, double>;
        dailyData.forEach((dateKey, amount) {
          final parts = dateKey.split('/');
          final monthKey = parts[1]; // Chỉ lấy tháng
          yearlyRevenue[monthKey] = (yearlyRevenue[monthKey] ?? 0) + amount;
        });
      }

      return {
        'totalRevenue': result['totalRevenue'] ?? 0.0,
        'ticketCount': result['ticketCount'] ?? 0,
        'yearlyRevenue': yearlyRevenue,
      };
    } catch (e) {
      print('Error in getYearlyRevenue: $e');
      return {
        'totalRevenue': 0.0,
        'ticketCount': 0,
        'yearlyRevenue': {},
      };
    }
  }

  Future<List<Ticket>> getTicketsByShowtimeId(String showtimeId) async {
    try {
      // Lấy danh sách vé từ collection tickets
      final QuerySnapshot snapshot = await _firestore
          .collection('tickets')
          .where('showtime.id', isEqualTo: showtimeId)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Ticket.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting tickets: $e');
      rethrow;
    }
  }

  Future<List<Food>> getFoodItems() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('foods').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Food.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting food items: $e');
      rethrow;
    }
  }
}
