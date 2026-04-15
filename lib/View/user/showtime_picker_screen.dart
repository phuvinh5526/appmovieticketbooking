import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../Components/time_picker.dart';
import '../../Model/Movie.dart';
import '../../Model/Province.dart';
import '../../Model/Room.dart';
import '../../Model/Showtime.dart';
import '../../Model/Cinema.dart';
import '../../Services/showtime_service.dart';
import '../../Services/province_service.dart';
import 'seat_selection_screen.dart';
import 'province_list_screen.dart';
import '../../Components/custom_image_widget.dart';
import 'package:provider/provider.dart';
import '../../Providers/user_provider.dart';
import 'login_screen.dart';

class ShowtimePickerScreen extends StatefulWidget {
  final Movie movie;

  const ShowtimePickerScreen({Key? key, required this.movie}) : super(key: key);

  @override
  State<ShowtimePickerScreen> createState() => _ShowtimePickerScreenState();
}

class _ShowtimePickerScreenState extends State<ShowtimePickerScreen>
    with WidgetsBindingObserver {
  DateTime selectedDate = DateTime.now();
  Showtime? selectedShowtime;
  Cinema? selectedCinema;
  List<Cinema> availableCinemas = [];
  Map<String, List<Showtime>> cinemaShowtimes = {};
  Province? selectedProvince;
  Map<String, bool> selectedTimeStates = {};
  bool isLoading = true;
  List<DateTime> dateList = [];

  final ShowtimeService _showtimeService = ShowtimeService();

  // Thêm biến để quản lý stream subscription
  StreamSubscription? _showtimesSubscription;

  Map<String, Room> roomData = {}; // Thêm map để lưu thông tin phòng

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _generateDateList();
    _fetchCinemasAndShowtimes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Hủy stream subscription khi widget bị dispose
    _showtimesSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Tải lại dữ liệu khi app quay trở lại foreground
      _refreshData();
    }
  }

  // Hàm tải lại dữ liệu
  void _refreshData() {
    if (!mounted) return;
    print('Tải lại dữ liệu suất chiếu...');
    _fetchCinemasAndShowtimes();
  }

  // Tạo danh sách ngày từ hiện tại đến 7 ngày tiếp theo
  void _generateDateList() {
    final now = DateTime.now();
    dateList = List.generate(
        7, (index) => DateTime(now.year, now.month, now.day + index));
  }

  void _fetchCinemasAndShowtimes({bool forceRefresh = false}) {
    // Hủy subscription cũ nếu có
    _showtimesSubscription?.cancel();

    if (!mounted) return;

    setState(() {
      isLoading = true;
      cinemaShowtimes.clear();
      availableCinemas.clear();
      roomData.clear(); // Xóa dữ liệu phòng cũ
      if (forceRefresh) {
        selectedShowtime = null;
        selectedTimeStates.clear();
      }
    });

    // In ra thông tin debug
    print(
        'Tìm suất chiếu cho phim ${widget.movie.id} vào ngày ${DateFormat('yyyy-MM-dd').format(selectedDate)}');

    // Lấy suất chiếu theo phim và ngày
    _showtimesSubscription = _showtimeService
        .getShowtimesByMovieAndDate(widget.movie.id, selectedDate)
        .listen((showtimes) async {
      if (!mounted) return;

      print('Tìm thấy ${showtimes.length} suất chiếu');

      cinemaShowtimes.clear();
      availableCinemas.clear();
      roomData.clear(); // Xóa dữ liệu phòng cũ

      // Nhóm suất chiếu theo rạp phim
      for (var showtime in showtimes) {
        try {
          // Lấy thông tin phòng chiếu
          Room room = await _showtimeService.getRoomById(showtime.roomId);
          if (!mounted) return;

          // Lưu thông tin phòng
          roomData[room.id] = room;

          // Lấy thông tin rạp phim
          Cinema cinema =
              await _showtimeService.getCinemaById(showtime.cinemaId);
          if (!mounted) return;

          // Chỉ hiển thị rạp thuộc tỉnh đã chọn (nếu có)
          if (selectedProvince == null ||
              cinema.provinceId == selectedProvince!.id) {
            if (!cinemaShowtimes.containsKey(cinema.id)) {
              cinemaShowtimes[cinema.id] = [];
              availableCinemas.add(cinema);
            }
            cinemaShowtimes[cinema.id]!.add(showtime);
          }
        } catch (e) {
          print('Lỗi khi lấy thông tin phòng/rạp: $e');
        }
      }

      if (!mounted) return;

      setState(() {
        if (availableCinemas.isNotEmpty) {
          selectedCinema = availableCinemas.first;
        } else {
          selectedCinema = null;
        }
        isLoading = false;
      });
    }, onError: (error) {
      print('Lỗi khi tải suất chiếu: $error');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  void _onDateSelected(DateTime date) {
    if (!mounted) return;

    setState(() {
      selectedDate = date;
      selectedShowtime = null;
      selectedTimeStates.clear();
    });

    // Tải lại dữ liệu với ngày mới
    _fetchCinemasAndShowtimes(forceRefresh: true);
  }

  void _onCinemaSelected(Cinema cinema) {
    if (!mounted) return;

    setState(() {
      selectedCinema = cinema;
      selectedShowtime = null;
    });
  }

  void _fetchCinemasByProvince(Province province) {
    if (!mounted) return;

    setState(() {
      selectedProvince = province;
    });

    _fetchCinemasAndShowtimes();
  }

  // Widget hiển thị danh sách ngày
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
                    style: TextStyle(
                      color: Colors.white,
                    ),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/movies');
          },
          child: Row(
            children: [
              Flexible(
                child: Text(
                  widget.movie.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Nút làm mới dữ liệu
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.3),
                  ],
                ).createShader(bounds);
              },
              blendMode: BlendMode.darken,
              child: CustomImageWidget(
                imagePath: widget.movie.imagePath,
                isBackground: true,
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.black.withOpacity(0.7),
          ),
          isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.orange))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 100),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildDatePicker(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () async {
                          final selectedProvinceObj =
                              await Navigator.push<Province?>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProvinceListScreen(),
                            ),
                          );

                          if (mounted) {
                            setState(() {
                              selectedProvince =
                                  selectedProvinceObj; // Có thể là null nếu chọn "Tất cả"
                              selectedCinema = null;
                              selectedShowtime = null;
                              selectedTimeStates.clear();
                            });
                            _fetchCinemasAndShowtimes(forceRefresh: true);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_city,
                                    color: Colors.orange,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    selectedProvince != null
                                        ? selectedProvince!.name
                                        : 'Tất cả tỉnh',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white54,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (availableCinemas.isNotEmpty)
                        Column(
                          children: availableCinemas.map((cinema) {
                            bool isSelected = cinema == selectedCinema;
                            return GestureDetector(
                              onTap: () => _onCinemaSelected(cinema),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 20),
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.orangeAccent
                                      : Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded,
                                        color: Colors.white),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(cinema.name,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18.0,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        color: Colors.white),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 20),
                      if (selectedCinema != null &&
                          cinemaShowtimes[selectedCinema!.id] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: TimePicker(
                            availableShowtimes:
                                cinemaShowtimes[selectedCinema!.id]!,
                            onTimeSelected: (Showtime showtime) {
                              if (!mounted) return;
                              setState(() {
                                selectedTimeStates.clear();
                                selectedTimeStates[showtime.id] = true;
                                selectedShowtime = showtime;
                              });
                            },
                            height: 50,
                            selectedTimeStates:
                                selectedTimeStates, // Truyền dữ liệu phòng vào TimePicker
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 50),
                          child: const Text("Không có suất chiếu khả dụng",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.black,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              mainAxisAlignment: selectedShowtime == null
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (selectedShowtime != null)
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          selectedShowtime!.bookedSeats.length <
                                  selectedShowtime!.totalSeats
                              ? "Còn ghế"
                              : "Hết ghế",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                if (selectedShowtime != null) const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: selectedShowtime != null
                        ? () {
                            final userProvider = Provider.of<UserProvider>(
                                context,
                                listen: false);
                            if (userProvider.currentUser == null) {
                              // Nếu chưa đăng nhập, chuyển đến trang đăng nhập
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            } else {
                              // Nếu đã đăng nhập, chuyển đến trang chọn ghế
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SeatSelectionScreen(
                                    showtime: selectedShowtime!,
                                    movieTitle: widget.movie.title,
                                    moviePoster: widget.movie.imagePath,
                                  ),
                                ),
                              );
                            }
                          }
                        : null,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: selectedShowtime != null
                            ? Colors.orangeAccent
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Center(
                        child: Text("Đặt vé",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22.0,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
