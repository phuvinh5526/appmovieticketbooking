import 'package:flutter/material.dart';
import 'package:movieticketbooking/View/user/payment_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Model/Room.dart';
import '../../Model/Showtime.dart';
import '../../Model/Seat.dart';
import '../../Utils/seat_selection_validator.dart';
import '../../Components/custom_image_widget.dart';
import 'food_selection_screen.dart';
import 'dart:io';

class SeatSelectionScreen extends StatefulWidget {
  final Showtime showtime;
  final String movieTitle;
  final String moviePoster;

  const SeatSelectionScreen({
    Key? key,
    required this.showtime,
    required this.movieTitle,
    required this.moviePoster,
  }) : super(key: key);

  @override
  _SeatSelectionScreenState createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  late Room selectedRoom;
  final double vipSeatPrice = 50000;
  final double normalSeatPrice = 45000;
  bool isLoading = true;
  List<Seat> seatLayout = [];
  Set<String> bookedSeats = {};

  @override
  void initState() {
    super.initState();
    _loadRoomAndSeats();
  }

  Future<void> _loadRoomAndSeats() async {
    try {
      // Load room data
      final roomDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.showtime.roomId)
          .get();

      if (roomDoc.exists) {
        final roomData = roomDoc.data() as Map<String, dynamic>;
        selectedRoom = Room(
          id: roomDoc.id,
          cinemaId: roomData['cinemaId'] ?? '',
          name: roomData['name'] ?? '',
          rows: roomData['rows'] ?? 0,
          cols: roomData['cols'] ?? 0,
          seatLayout: [], // We'll load seats separately
        );

        // Load seat layout
        final seatLayoutData = roomData['seatLayout'] as List<dynamic>;
        seatLayout = seatLayoutData.map((seatData) {
          return Seat(
            id: seatData['id'] ?? '',
            row: seatData['row'] ?? '',
            column: seatData['column'] ?? 0,
            isVip: seatData['isVip'] ?? false,
            isBooked: seatData['isBooked'] ?? false,
          );
        }).toList();

        // Update booked seats from showtime
        setState(() {
          bookedSeats = widget.showtime.bookedSeats.toSet();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading room and seats: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  List<String> selectedSeats = [];

  void toggleSeat(String seatId) {
    setState(() {
      if (selectedSeats.contains(seatId)) {
        selectedSeats.remove(seatId);
      } else {
        selectedSeats.add(seatId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Chọn Ghế',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: widget.moviePoster.startsWith('http')
                    ? NetworkImage(widget.moviePoster)
                    : FileImage(File(widget.moviePoster)) as ImageProvider,
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.8),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 120),
              _buildScreenIndicator(),
              const SizedBox(height: 30),
              Expanded(
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: Colors.orange))
                    : _buildSeatGrid(),
              ),
              _buildLegend(),
              SizedBox(height: 10),
              _buildBottomBar()
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeatGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: selectedRoom.cols,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        childAspectRatio: 1,
      ),
      itemCount: selectedRoom.rows * selectedRoom.cols,
      itemBuilder: (context, index) {
        int rowNumber = index ~/ selectedRoom.cols;
        int colNumber = index % selectedRoom.cols + 1;
        String rowLetter = String.fromCharCode(65 + rowNumber);
        String seatId = '$rowLetter$colNumber';

        // Find the seat in the seat layout
        Seat? seat = seatLayout.firstWhere(
          (s) => s.row == rowLetter && s.column == colNumber,
          orElse: () => Seat(
            id: seatId,
            row: rowLetter,
            column: colNumber,
            isVip: rowNumber < selectedRoom.rows / 3,
            isBooked: false,
          ),
        );

        bool isSelected = selectedSeats.contains(seatId);
        bool isBooked = bookedSeats.contains(seatId) || seat.isBooked;
        bool isVip = seat.isVip;
        double price = isVip ? vipSeatPrice : normalSeatPrice;

        Color seatColor = isBooked
            ? Colors.black
            : isSelected
                ? Colors.grey
                : isVip
                    ? const Color.fromARGB(255, 220, 181, 130)
                    : const Color.fromARGB(255, 255, 166, 0);

        return GestureDetector(
          onTap: isBooked ? null : () => toggleSeat(seatId),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: seatColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Center(
              child: Text(
                seatId,
                style: TextStyle(
                  color: isBooked ? Colors.white54 : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    // Get rows from selectedRoom
    final rows = selectedRoom.rows;
    double totalPrice = selectedSeats.fold(0, (sum, seatId) {
      // Find the seat in the seat layout
      Seat? seat = seatLayout.firstWhere(
        (s) => s.id == seatId,
        orElse: () => Seat(
          id: seatId,
          row: seatId.substring(0, 1),
          column: int.parse(seatId.substring(1)),
          isVip: seatId.codeUnitAt(0) - 65 < rows / 3,
          isBooked: false,
        ),
      );
      int rowNumber = seatId.codeUnitAt(0) - 65;
      double price = rowNumber < rows / 3 ? normalSeatPrice : vipSeatPrice;
      return sum + price;
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tổng tiền",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  "${totalPrice.toStringAsFixed(0)}đ",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 7,
            child: ElevatedButton(
              onPressed: () {
                if (selectedSeats.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text("Vui lòng chọn ghế trước khi thanh toán!")),
                  );
                  return;
                }

                // Kiểm tra tính hợp lệ của ghế đã chọn
                Map<String, List<String>> errors =
                    SeatSelectionValidator.validateSeats(
                  selectedSeats,
                  widget.showtime.bookedSeats,
                  selectedRoom.cols,
                );

                if (errors.isNotEmpty) {
                  // Hiển thị dialog với tất cả các lỗi
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Lỗi chọn ghế'),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...errors.entries.map((entry) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (entry.key != 'general')
                                      Text(
                                        'Hàng ${entry.key}:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ...entry.value.map((error) => Padding(
                                          padding: const EdgeInsets.only(
                                              left: 8.0, bottom: 4.0),
                                          child: Text('• $error'),
                                        )),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Đóng'),
                          ),
                        ],
                      );
                    },
                  );
                  return;
                }

                // Nếu không có lỗi, chuyển sang màn hình tiếp theo
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FoodSelectionScreen(
                      movieTitle: widget.movieTitle,
                      moviePoster: widget.moviePoster,
                      showtime: widget.showtime,
                      selectedSeats: selectedSeats,
                      totalPrice: totalPrice,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Tiếp tục',
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem(const Color.fromARGB(255, 220, 181, 130), 'Ghế thường'),
          _legendItem(Colors.orange, 'Ghế VIP'),
          _legendItem(Colors.black, 'Ghế đã đặt'),
          _legendItem(Colors.grey, 'Ghế đã chọn'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5), // Bo tròn góc
            border: Border.all(color: Colors.white, width: 2), // Viền trắng
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

Widget _buildScreenIndicator() {
  return Stack(
    children: [
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 25),
        height: 40, // Chiều cao của màn hình
        child: CustomPaint(
          painter: _ScreenPainter(),
          child: Center(
            child: Text(
              'MÀN HÌNH',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _ScreenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = const Color.fromARGB(58, 212, 206, 191) // Màu của màn hình
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4); // Hiệu ứng bóng nhẹ

    Path path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(
        size.width / 2, size.height * 0.2, size.width, size.height * 0.8);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
