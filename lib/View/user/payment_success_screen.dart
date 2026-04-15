import 'package:flutter/material.dart';
import '../../Model/Showtime.dart';
import '../../Model/Ticket.dart';
import 'ticket_detail_screen.dart';
import '../../Services/ticket_service.dart';
import '../../Components/custom_image_widget.dart';
import '../../Services/email_service.dart';
import '../../Services/cinema_service.dart';
import '../../Services/room_service.dart';
import '../../Model/Cinema.dart';
import '../../Model/Room.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String movieTitle;
  final String moviePoster;
  final Showtime showtime;
  final String roomName;
  final String cinemaName;
  final List<String> selectedSeats;
  final double totalPrice;
  final Map<String, int> selectedFoods;
  final String userId;
  final String userEmail;
  final String userName;

  const PaymentSuccessScreen({
    Key? key,
    required this.movieTitle,
    required this.moviePoster,
    required this.showtime,
    required this.selectedSeats,
    required this.totalPrice,
    required this.roomName,
    required this.cinemaName,
    required this.selectedFoods,
    required this.userId,
    required this.userEmail,
    required this.userName,
  }) : super(key: key);

  @override
  _PaymentSuccessScreenState createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final TicketService _ticketService = TicketService();
  final EmailService _emailService = EmailService();
  final CinemaService _cinemaService = CinemaService();
  final RoomService _roomService = RoomService();
  bool _isSaving = false;
  bool _isSendingEmail = false;
  Ticket? _newTicket;
  Cinema? _cinema;
  Room? _room;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _controller.forward();
    _saveTicket();
  }

  Future<void> _saveTicket() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Tạo vé mới
      _newTicket = Ticket(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: widget.userId,
        showtime: widget.showtime,
        selectedSeats: widget.selectedSeats,
        selectedFoods: widget.selectedFoods,
        totalPrice: widget.totalPrice,
        isUsed: false,
      );

      // Lưu vé vào database
      await _ticketService.createTicket(_newTicket!);

      // Lấy thông tin rạp và phòng chiếu
      _cinema = await _cinemaService.getCinemaById(widget.showtime.cinemaId);
      _room = await _roomService.getRoomById(widget.showtime.roomId);

      if (_cinema != null && _room != null) {
        // Gửi email
        await _sendTicketEmail();
      }

      setState(() {
        _isSaving = false;
      });
    } catch (e) {
      print('Error saving ticket: $e');
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra khi lưu vé'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendTicketEmail() async {
    setState(() {
      _isSendingEmail = true;
    });

    try {
      await _emailService.sendTicketEmail(
        recipientEmail: widget.userEmail,
        recipientName: widget.userName,
        movieTitle: widget.movieTitle,
        ticket: _newTicket!,
        cinema: _cinema!,
        room: _room!,
      );

      setState(() {
        _isSendingEmail = false;
      });
    } catch (e) {
      print('Error sending email: $e');
      setState(() {
        _isSendingEmail = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra khi gửi email'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.95),
                  ],
                ).createShader(bounds);
              },
              blendMode: BlendMode.darken,
              child: CustomImageWidget(
                imagePath: widget.moviePoster,
                isBackground: true,
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Icon(
                          Icons.check_circle_outline,
                          size: 100,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 20),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Thanh Toán Thành Công!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Vé của bạn đã được đặt thành công',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      if (_isSendingEmail)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.orangeAccent),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Đang gửi thông tin vé đến email của bạn...',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isSaving || _newTicket == null
                                    ? null
                                    : () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TicketDetailScreen(
                                              movieTitle: widget.movieTitle,
                                              moviePoster: widget.moviePoster,
                                              ticket: _newTicket!,
                                            ),
                                          ),
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orangeAccent,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 5,
                                ),
                                child: Text(
                                  "Xem Chi Tiết Vé",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
