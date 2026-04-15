import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/user_provider.dart';
import 'package:movieticketbooking/View/user/cinema_list_screen.dart';
import 'package:movieticketbooking/View/user/home_screen.dart';
import 'package:movieticketbooking/View/user/login_screen.dart';
import 'package:movieticketbooking/View/user/profile_screen.dart';
import 'package:movieticketbooking/View/user/movie_list_screen.dart';
import 'package:movieticketbooking/View/user/register_screen.dart';
import 'package:movieticketbooking/View/user/my_ticket_list_screen.dart';
import 'package:movieticketbooking/View/user/showtime_picker_screen.dart';
import 'package:movieticketbooking/Services/user_service.dart';
import 'package:movieticketbooking/Services/ticket_service.dart';
import 'package:movieticketbooking/Model/User.dart';
import 'package:movieticketbooking/Model/Ticket.dart';

class BottomNavBar extends StatefulWidget {
  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int currentIndex = 0;
  bool isBottomNavBarVisible = true;
  List<Ticket> userTickets = [];
  final TicketService _ticketService = TicketService();

  @override
  void initState() {
    super.initState();
  }

  setBottomBarIndex(index) {
    final userProvider = context.read<UserProvider>();
    if ((index == 3 || index == 4) && userProvider.currentUser == null) {
      // Nếu nhấn vào tab Vé của tôi hoặc Profile và chưa đăng nhập
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
      );
      return;
    }

    setState(() {
      currentIndex = index;
    });
  }

  void _showPurchaseOptions() {
    final userProvider = context.read<UserProvider>();
    if (userProvider.currentUser == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          height: 220,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Chọn cách mua vé',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                  ),
                ),
              ),
              SizedBox(height: 20),
              buildTicketOption(
                icon: Icons.movie,
                text: 'Mua vé theo phim',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieListScreen(),
                    ),
                  );
                },
              ),
              SizedBox(height: 10),
              buildTicketOption(
                icon: Icons.theater_comedy,
                text: 'Mua vé theo rạp',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CinemaListScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final currentUser = userProvider.currentUser;

    if (currentIndex == 1 ||
        currentIndex == 2 ||
        currentIndex == 3 ||
        currentIndex == 4) {
      isBottomNavBarVisible = false;
    } else {
      isBottomNavBarVisible = true;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          IndexedStack(
            index: currentIndex,
            children: [
              HomeScreen(),
              MovieListScreen(),
              CinemaListScreen(),
              if (currentUser != null)
                MyTicketListScreen(userId: currentUser.id)
              else
                Center(child: Text('Vui lòng đăng nhập để xem vé của bạn')),
              if (currentUser != null)
                ProfileScreen(user: currentUser)
              else
                Center(
                    child:
                        CircularProgressIndicator(color: Colors.orangeAccent)),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Visibility(
              visible: isBottomNavBarVisible,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 80,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      size: Size(MediaQuery.of(context).size.width, 80),
                      painter: BNBCustomPainter(),
                    ),
                    Center(
                      heightFactor: 0.6,
                      child: FloatingActionButton(
                        backgroundColor: Colors.orangeAccent,
                        child: Image.asset(
                          'assets/icons/buyticket.png',
                          height: 40.0,
                          width: 40.0,
                          fit: BoxFit.contain,
                        ),
                        elevation: 0.1,
                        onPressed: () {
                          _showPurchaseOptions();
                        },
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: 80,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 15),
                              GestureDetector(
                                onTap: () => setBottomBarIndex(1),
                                child: Container(
                                  child: Image.asset(
                                    'assets/icons/film.png',
                                    height: 35.0,
                                    width: 35.0,
                                    color: currentIndex == 1
                                        ? Colors.orangeAccent
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              Text(
                                'Phim',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: currentIndex == 1
                                      ? Colors.orangeAccent
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: 80),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => setBottomBarIndex(2),
                                  child: Container(
                                    child: Image.asset(
                                      'assets/icons/theater.png',
                                      height: 35.0,
                                      width: 35.0,
                                      color: currentIndex == 2
                                          ? Colors.orangeAccent
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Rạp',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: currentIndex == 2
                                        ? Colors.orangeAccent
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => setBottomBarIndex(3),
                                child: Container(
                                  child: Image.asset(
                                    'assets/icons/myticket.png',
                                    height: 35.0,
                                    width: 35.0,
                                    color: currentIndex == 3
                                        ? Colors.orangeAccent
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              Text(
                                'Vé',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: currentIndex == 3
                                      ? Colors.orangeAccent
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 15),
                              GestureDetector(
                                onTap: () => setBottomBarIndex(4),
                                child: Container(
                                  child: Image.asset(
                                    'assets/icons/user.png',
                                    height: 35.0,
                                    width: 35.0,
                                    color: currentIndex == 4
                                        ? Colors.orangeAccent
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              Text(
                                'Tôi',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: currentIndex == 4
                                      ? Colors.orangeAccent
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class BNBCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    Path path = Path();
    path.moveTo(0, 20);
    path.quadraticBezierTo(size.width * 0.20, 0, size.width * 0.35, 0);
    path.quadraticBezierTo(size.width * 0.40, 0, size.width * 0.40, 20);
    path.arcToPoint(Offset(size.width * 0.60, 20),
        radius: Radius.circular(20.0), clockwise: false);
    path.quadraticBezierTo(size.width * 0.60, 0, size.width * 0.65, 0);
    path.quadraticBezierTo(size.width * 0.80, 0, size.width, 20);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, 20);
    canvas.drawShadow(path, Colors.black, 5, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

Widget buildTicketOption({
  required IconData icon,
  required String text,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orangeAccent, size: 28),
          SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.orangeAccent, size: 20),
        ],
      ),
    ),
  );
}
