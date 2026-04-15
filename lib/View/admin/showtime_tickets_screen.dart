import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Model/Movie.dart';
import '../../Model/Showtime.dart';
import '../../Model/Cinema.dart';
import '../../Model/Room.dart';
import '../../Model/Ticket.dart';
import '../../Services/ticket_service.dart';
import '../../Model/User.dart';
import '../../Services/user_service.dart';
import '../../Model/Food.dart';

class ShowtimeTicketsScreen extends StatefulWidget {
  final Showtime showtime;
  final Movie movie;
  final Room room;
  final Cinema cinema;

  const ShowtimeTicketsScreen({
    Key? key,
    required this.showtime,
    required this.movie,
    required this.room,
    required this.cinema,
  }) : super(key: key);

  @override
  State<ShowtimeTicketsScreen> createState() => _ShowtimeTicketsScreenState();
}

class _ShowtimeTicketsScreenState extends State<ShowtimeTicketsScreen> {
  final TicketService _ticketService = TicketService();
  final UserService _userService = UserService();
  List<Ticket> tickets = [];
  bool isLoading = true;
  List<Food> foodItems = [];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      final ticketList =
          await _ticketService.getTicketsByShowtimeId(widget.showtime.id);
      final foodList = await _ticketService.getFoodItems();
      setState(() {
        tickets = ticketList;
        foodItems = foodList;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading tickets: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff252429),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Danh sách vé',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thông tin suất chiếu
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.movie.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rạp: ${widget.cinema.name}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            'Phòng: ${widget.room.name}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            'Thời gian: ${DateFormat('HH:mm - dd/MM/yyyy').format(widget.showtime.startTime)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Thống kê
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                              'Tổng số ghế',
                              '${widget.room.rows * widget.room.cols}',
                              Colors.white),
                          _buildStatItem(
                              'Đã đặt',
                              '${widget.showtime.bookedSeats.length}',
                              Colors.orange),
                          _buildStatItem(
                            'Còn trống',
                            '${(widget.room.rows * widget.room.cols) - widget.showtime.bookedSeats.length}',
                            Colors.green,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Danh sách vé
                    const Text(
                      'Danh sách vé đã đặt:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (tickets.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Chưa có vé nào được đặt',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tickets.length,
                        itemBuilder: (context, index) {
                          final ticket = tickets[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mã vé: ${ticket.id}',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Thông tin người đặt:',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                FutureBuilder<User?>(
                                  future:
                                      _userService.getUserById(ticket.userId),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const CircularProgressIndicator(
                                          color: Colors.orange);
                                    }
                                    if (snapshot.hasError) {
                                      return const Text(
                                        'Không thể tải thông tin người dùng',
                                        style: TextStyle(color: Colors.red),
                                      );
                                    }
                                    final user = snapshot.data;
                                    if (user == null) {
                                      return const Text(
                                        'Không tìm thấy thông tin người dùng',
                                        style: TextStyle(color: Colors.red),
                                      );
                                    }
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Họ tên: ${user.fullName}',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        Text(
                                          'Email: ${user.email}',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        Text(
                                          'Số điện thoại: ${user.phoneNumber}',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Thông tin vé:',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Ghế: ${ticket.selectedSeats.join(", ")}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Text(
                                  'Giá vé: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(ticket.totalPrice)}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                if (ticket.selectedFoods.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Đồ ăn đã chọn:',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ...ticket.selectedFoods.entries.map((entry) {
                                    Food? food = foodItems.firstWhere(
                                      (f) => f.id == entry.key,
                                      orElse: () => Food(
                                        id: entry.key,
                                        name: "Không xác định",
                                        price: 0,
                                        image: "assets/images/bapnuoc.png",
                                        description: "",
                                      ),
                                    );
                                    return Text(
                                      '${food.name}: ${entry.value}',
                                      style: const TextStyle(
                                          color: Colors.white70),
                                    );
                                  }).toList(),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  'Trạng thái: ${ticket.isUsed ? "Đã sử dụng" : "Chưa sử dụng"}',
                                  style: TextStyle(
                                    color: ticket.isUsed
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
