import 'package:flutter/foundation.dart';
import 'package:movieticketbooking/Model/Ticket.dart';
import 'package:movieticketbooking/Services/ticket_service.dart';

class TicketProvider with ChangeNotifier {
  final TicketService _ticketService = TicketService();
  List<Ticket> _tickets = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Ticket> get tickets => _tickets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Kiểm tra và cập nhật trạng thái vé dựa trên thời gian chiếu
  Future<void> checkAndUpdateTicketStatus() async {
    try {
      DateTime now = DateTime.now();
      for (var ticket in _tickets) {
        if (!ticket.isUsed && now.isAfter(ticket.showtime.startTime)) {
          await updateTicketStatus(ticket.id, true);
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Lấy danh sách vé theo userId
  Future<void> loadUserTickets(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final ticketStream = _ticketService.getTicketsByUserId(userId);
      ticketStream.listen(
        (ticketList) {
          _tickets = ticketList;
          _isLoading = false;
          notifyListeners();

          // Kiểm tra và cập nhật trạng thái vé sau khi load
          checkAndUpdateTicketStatus();
        },
        onError: (error) {
          _error = error.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tạo vé mới
  Future<void> createTicket(Ticket ticket) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _ticketService.createTicket(ticket);
      _tickets.add(ticket);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cập nhật trạng thái vé
  Future<void> updateTicketStatus(String ticketId, bool isUsed) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _ticketService.updateTicketStatus(ticketId, isUsed);

      // Cập nhật trạng thái vé trong danh sách local
      final index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
      if (index != -1) {
        _tickets[index] = Ticket(
          id: _tickets[index].id,
          userId: _tickets[index].userId,
          showtime: _tickets[index].showtime,
          selectedSeats: _tickets[index].selectedSeats,
          selectedFoods: _tickets[index].selectedFoods,
          totalPrice: _tickets[index].totalPrice,
          isUsed: isUsed,
        );
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lấy thống kê doanh thu
  Future<Map<String, dynamic>> getRevenueStats(
      DateTime startDate, DateTime endDate) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final stats = await _ticketService.getRevenueStats(startDate, endDate);

      _isLoading = false;
      notifyListeners();
      return stats;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {
        'totalRevenue': 0.0,
        'ticketCount': 0,
        'dailyRevenue': {},
      };
    }
  }

  // Xóa vé
  Future<void> deleteTicket(String ticketId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _ticketService.deleteTicket(ticketId);
      _tickets.removeWhere((ticket) => ticket.id == ticketId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset state
  void reset() {
    _tickets = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
