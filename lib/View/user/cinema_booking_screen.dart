import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Components/time_picker.dart';
import '../../Components/custom_image_widget.dart';
import '../../Model/Movie.dart';
import '../../Model/Showtime.dart';
import '../../Model/Cinema.dart';
import '../../Model/Genre.dart';
import '../../Services/showtime_service.dart';
import '../../Services/movie_service.dart';
import 'seat_selection_screen.dart';
import 'package:provider/provider.dart';
import '../../Providers/user_provider.dart';
import 'login_screen.dart';
import '../../Model/Room.dart';

class CinemaBookingScreen extends StatefulWidget {
  final Cinema cinema;

  const CinemaBookingScreen({Key? key, required this.cinema}) : super(key: key);

  @override
  State<CinemaBookingScreen> createState() => _CinemaBookingScreenState();
}

class _CinemaBookingScreenState extends State<CinemaBookingScreen> {
  DateTime selectedDate = DateTime.now();
  Showtime? selectedShowtime;
  List<Showtime> availableShowtimes = [];
  List<Movie> moviesShowing = [];
  Map<String, bool> selectedTimeStates = {};
  Map<String, Room> roomsMap = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DateTime> get dateList {
    final now = DateTime.now();
    return List.generate(7, (index) => now.add(Duration(days: index)));
  }

  @override
  void initState() {
    super.initState();
    _fetchShowtimesAndMovies();
  }

  Future<void> _fetchShowtimesAndMovies() async {
    try {
      final now = DateTime.now();
      
      // CHỈ LỌC THEO cinemaId (Truy vấn đơn giản, không cần Index)
      final showtimesSnapshot = await _firestore
          .collection('showtimes')
          .where('cinemaId', isEqualTo: widget.cinema.id)
          .get();

      // Lấy thông tin phòng
      final roomsSnapshot = await _firestore
          .collection('rooms')
          .where('cinemaId', isEqualTo: widget.cinema.id)
          .get();

      roomsMap.clear();
      for (var doc in roomsSnapshot.docs) {
        final data = doc.data();
        roomsMap[doc.id] = Room(
          id: doc.id,
          cinemaId: data['cinemaId'] as String,
          name: data['name'] as String,
          rows: data['rows'] as int,
          cols: data['cols'] as int,
          seatLayout: [],
        );
      }

      // Lọc dữ liệu thủ công bằng code Dart để tránh lỗi Index
      final showtimes = showtimesSnapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              final startTime = data['startTime'] is Timestamp 
                  ? (data['startTime'] as Timestamp).toDate()
                  : DateTime.parse(data['startTime'].toString());
              
              // Lọc theo ngày được chọn
              bool isSameDay = startTime.year == selectedDate.year &&
                               startTime.month == selectedDate.month &&
                               startTime.day == selectedDate.day;
              
              if (!isSameDay) return null;

              final bookedSeats = List<String>.from(data['bookedSeats'] ?? []);
              final roomId = data['roomId'] as String;
              final room = roomsMap[roomId];

              if (room == null) return null;

              return Showtime(
                id: doc.id,
                movieId: data['movieId'] as String,
                cinemaId: widget.cinema.id,
                roomId: roomId,
                startTime: startTime,
                bookedSeats: bookedSeats,
                totalSeats: room.rows * room.cols,
              );
            } catch (e) {
              return null;
            }
          })
          .whereType<Showtime>()
          .toList();

      // Lọc bỏ suất chiếu quá 1 giờ
      final filteredShowtimes = showtimes.where((showtime) {
        return now.isBefore(showtime.startTime.add(const Duration(hours: 1)));
      }).toList();

      // Lấy danh sách phim
      final movieIds = filteredShowtimes.map((s) => s.movieId).toSet();
      final movieDocs = await Future.wait(
        movieIds.map((id) => _firestore.collection('movies').doc(id).get()),
      );

      final validMovies = movieDocs.where((doc) => doc.exists).map((doc) {
        final data = doc.data()!;
        return Movie.fromJson({...data, 'id': doc.id});
      }).toList();

      setState(() {
        availableShowtimes = filteredShowtimes;
        moviesShowing = validMovies;
      });
    } catch (e) {
      print('Error fetching showtimes: $e');
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      selectedDate = date;
      selectedShowtime = null;
      selectedTimeStates.clear();
    });
    _fetchShowtimesAndMovies();
  }

  Widget _buildDatePicker() {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dateList.length,
        itemBuilder: (context, index) {
          final date = dateList[index];
          final isSelected = DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(selectedDate);

          return GestureDetector(
            onTap: () => _onDateSelected(date),
            child: Container(
              width: 70,
              margin: EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.orange : Colors.black38,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? Colors.orangeAccent : Colors.grey,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    DateFormat('dd').format(date),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    DateFormat('MM').format(date),
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff252429),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 50.0, left: 20, right: 20, bottom: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    widget.cinema.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            _buildDatePicker(),
            const SizedBox(height: 20),
            if (availableShowtimes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "Không có suất chiếu khả dụng",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              )
            else
              for (var movie in moviesShowing)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CustomImageWidget(
                            imagePath: movie.imagePath,
                            width: 80,
                            height: 120,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: TimePicker(
                              availableShowtimes: availableShowtimes
                                  .where((s) => s.movieId == movie.id)
                                  .toList(),
                              onTimeSelected: (Showtime showtime) {
                                setState(() {
                                  selectedTimeStates.clear();
                                  selectedTimeStates[showtime.id] = true;
                                  selectedShowtime = showtime;
                                });
                              },
                              height: 30,
                              selectedTimeStates: selectedTimeStates,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: selectedShowtime != null
              ? () {
                  final selectedMovie = moviesShowing.firstWhere(
                    (movie) => movie.id == selectedShowtime!.movieId,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SeatSelectionScreen(
                        showtime: selectedShowtime!,
                        movieTitle: selectedMovie.title,
                        moviePoster: selectedMovie.imagePath,
                      ),
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Text("Tiếp tục", style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
