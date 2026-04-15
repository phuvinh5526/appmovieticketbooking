import 'package:flutter/material.dart';
import 'package:movieticketbooking/View/admin/cinema_and_room_management_screen.dart';
import 'package:movieticketbooking/View/admin/data_import_screen.dart';
import 'package:movieticketbooking/View/admin/food_management_screen.dart';
import 'package:movieticketbooking/View/admin/movie_management_screen.dart';
import 'package:movieticketbooking/View/admin/revenue_statistics_screen.dart';
import 'package:movieticketbooking/View/admin/showtime_management_screen.dart';
import 'package:movieticketbooking/View/admin/user_management_screen.dart';
import 'package:movieticketbooking/View/admin/comment_management_screen.dart';

import '../../Components/sidebar_menu.dart';

class AdminMainScreen extends StatefulWidget {
  @override
  _AdminMainScreenState createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    "Quản lý phim",
    "Quản lý suất chiếu",
    "Quản lý rạp và phòng",
    "Quản lý người dùng ",
    "Quản lý đồ uống",
    "Quản lý bình luận",
    "Thống kê doanh thu",
  ];

  final List<Widget> _screens = [
    MovieManagementScreen(),
    ShowtimeManagementScreen(),
    CinemaAndRoomManagementScreen(),
    UserManagementScreen(),
    FoodManagementScreen(),
    CommentManagementScreen(),
    RevenueStatisticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]), // Cập nhật tiêu đề AppBar
        backgroundColor: Colors.orangeAccent,
      ),
      drawer: SidebarMenu(
        onMenuSelected: (index) {
          setState(() {
            _selectedIndex = index;
            Navigator.pop(context); // Đóng menu sau khi chọn
          });
        },
        selectedIndex: _selectedIndex,
      ),
      body: _screens[_selectedIndex],
    );
  }
}
