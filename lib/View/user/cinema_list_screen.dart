import 'package:flutter/material.dart';
import 'package:movieticketbooking/Components/bottom_nav_bar.dart';
import 'package:movieticketbooking/Model/Cinema.dart';
import 'package:movieticketbooking/Model/Province.dart';
import 'package:movieticketbooking/Services/province_service.dart';
import 'cinema_booking_screen.dart';

class CinemaListScreen extends StatefulWidget {
  @override
  _CinemaListScreenState createState() => _CinemaListScreenState();
}

class _CinemaListScreenState extends State<CinemaListScreen> {
  String? selectedProvinceId;
  List<Province> provinces = [];
  List<Cinema> cinemas = [];
  bool isLoading = true;
  final ProvinceService _provinceService = ProvinceService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final provinceList = await _provinceService.getAllProvinces().first;
      final cinemaList = await _provinceService.getAllCinemas().first;

      if (mounted) {
        setState(() {
          provinces = provinceList;
          cinemas = cinemaList;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Chọn rạp",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xff252429),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => BottomNavBar()));
          },
        ),
      ),
      backgroundColor: const Color(0xff252429),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : provinces.isEmpty
              ? const Center(
                  child: Text(
                    "Không có dữ liệu",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provinces.length,
                  itemBuilder: (context, index) {
                    final province = provinces[index];
                    final isExpanded = selectedProvinceId == province.id;
                    final provinceCinemas = cinemas
                        .where((cinema) => cinema.provinceId == province.id)
                        .toList();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            title: Text(
                              province.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.orange,
                              size: 20,
                            ),
                            onTap: () {
                              setState(() {
                                selectedProvinceId =
                                    isExpanded ? null : province.id;
                              });
                            },
                          ),
                          if (isExpanded)
                            Column(
                              children: provinceCinemas.map((cinema) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 8),
                                    leading: const Icon(
                                      Icons.local_movies,
                                      color: Colors.orange,
                                      size: 24,
                                    ),
                                    title: Text(
                                      cinema.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      cinema.address,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CinemaBookingScreen(
                                                  cinema: cinema),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
