import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../Model/Movie.dart';
import '../../Model/Showtime.dart';
import '../../Model/Cinema.dart';
import '../../Model/Room.dart';
import '../../Model/Province.dart';
import '../../Services/movie_service.dart';
import '../../Services/showtime_service.dart';
import '../../Services/province_service.dart';
import '../../View/admin/showtime_tickets_screen.dart';

class ShowtimeManagementScreen extends StatefulWidget {
  const ShowtimeManagementScreen({Key? key}) : super(key: key);

  @override
  _ShowtimeManagementScreenState createState() =>
      _ShowtimeManagementScreenState();
}

class _ShowtimeManagementScreenState extends State<ShowtimeManagementScreen> {
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  String? selectedProvinceId;
  String? selectedCinemaId;
  String? selectedMovieId;

  final MovieService _movieService = MovieService();
  final ShowtimeService _showtimeService = ShowtimeService();
  final ProvinceService _provinceService = ProvinceService();

  List<Province> provinces = [];
  List<Cinema> cinemas = [];
  List<Movie> movies = [];
  List<Showtime> showtimes = [];
  List<Room> rooms = [];

  bool isLoading = true;
  bool isDisposed = false;

  // Cache cho thông tin phòng và rạp phim
  final Map<String, Room> _roomCache = {};
  final Map<String, Cinema> _cinemaCache = {};
  bool _dataLoaded = false; // Đánh dấu đã tải dữ liệu thành công một lần

  // Stream subscriptions to manage
  StreamSubscription? _provincesSubscription;
  StreamSubscription? _moviesSubscription;
  StreamSubscription? _showtimesSubscription;
  StreamSubscription? _cinemasSubscription;

  @override
  void initState() {
    super.initState();
    // Khởi tạo danh sách trống để tránh lỗi null hay no element
    provinces = [];
    cinemas = [];
    movies = [];
    showtimes = [];
    rooms = [];
    _loadData();
  }

  @override
  void dispose() {
    isDisposed = true;
    _provincesSubscription?.cancel();
    _moviesSubscription?.cancel();
    _showtimesSubscription?.cancel();
    _cinemasSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() async {
    if (isDisposed) return;

    // Nếu đã tải dữ liệu một lần rồi thì không hiển thị loading full screen
    if (!_dataLoaded) {
      setState(() {
        isLoading = true;
      });
    }

    bool provinceLoaded = false;
    bool movieLoaded = false;
    bool showtimeLoaded = false;

    // Load provinces
    _provincesSubscription?.cancel();
    _provincesSubscription =
        _provinceService.getAllProvinces().listen((provinceList) {
      if (isDisposed) return;
      setState(() {
        provinces = provinceList;
        provinceLoaded = true;

        // Chỉ tắt isLoading khi tất cả dữ liệu đã load xong
        if (provinceLoaded && movieLoaded && showtimeLoaded) {
          isLoading = false;
          _dataLoaded = true; // Đánh dấu đã tải thành công
          print("Đã tải tất cả dữ liệu");
        }
      });
    }, onError: (e) {
      if (isDisposed) return;
      print('Error loading provinces: $e');
      setState(() {
        provinceLoaded = true;
        if (provinceLoaded && movieLoaded && showtimeLoaded) {
          isLoading = false;
        }
      });
    });

    // Load movies
    _moviesSubscription?.cancel();
    _moviesSubscription =
        _movieService.getNowShowingMovies().listen((movieList) {
      if (isDisposed) return;
      setState(() {
        movies = movieList;
        movieLoaded = true;

        // Chỉ tắt isLoading khi tất cả dữ liệu đã load xong
        if (provinceLoaded && movieLoaded && showtimeLoaded) {
          isLoading = false;
          _dataLoaded = true; // Đánh dấu đã tải thành công
          print("Đã tải tất cả dữ liệu");
        }
      });
    }, onError: (e) {
      if (isDisposed) return;
      print('Error loading movies: $e');
      setState(() {
        movieLoaded = true;
        if (provinceLoaded && movieLoaded && showtimeLoaded) {
          isLoading = false;
        }
      });
    });

    // Load showtimes
    _showtimesSubscription?.cancel();
    _showtimesSubscription =
        _showtimeService.getAllShowtimes().listen((showtimeList) {
      if (isDisposed) return;

      // Nạp danh sách phòng và rạp vào cache ngay khi nhận được showtimes
      _preloadRoomsAndCinemas(showtimeList);

      setState(() {
        showtimes = showtimeList;
        showtimeLoaded = true;

        // Chỉ tắt isLoading khi tất cả dữ liệu đã load xong
        if (provinceLoaded && movieLoaded && showtimeLoaded) {
          isLoading = false;
          _dataLoaded = true; // Đánh dấu đã tải thành công
          print("Đã tải tất cả dữ liệu");
        }
      });
    }, onError: (e) {
      if (isDisposed) return;
      print('Error loading showtimes: $e');
      setState(() {
        showtimeLoaded = true;
        if (provinceLoaded && movieLoaded && showtimeLoaded) {
          isLoading = false;
        }
      });
    });

    // Nếu sau 10 giây vẫn chưa load xong, tắt loading indicator
    Future.delayed(Duration(seconds: 10), () {
      if (isDisposed) return;
      if (isLoading) {
        setState(() {
          isLoading = false;
          _dataLoaded =
              true; // Đánh dấu đã tải xong để tránh loading lại khi người dùng thao tác
        });
        print('Forced loading to complete after timeout');
      }
    });
  }

  // Hàm giúp nạp trước thông tin phòng và rạp vào cache
  void _preloadRoomsAndCinemas(List<Showtime> showtimeList) {
    // Tạo Set để lưu trữ các ID duy nhất
    Set<String> uniqueRoomIds = {};
    Set<String> uniqueCinemaIds = {};

    // Thu thập các ID duy nhất từ danh sách suất chiếu
    for (var showtime in showtimeList) {
      if (showtime.roomId.isNotEmpty) {
        uniqueRoomIds.add(showtime.roomId);
      }
      if (showtime.cinemaId.isNotEmpty) {
        uniqueCinemaIds.add(showtime.cinemaId);
      }
    }

    // Nạp thông tin phòng vào cache
    for (String roomId in uniqueRoomIds) {
      if (!_roomCache.containsKey(roomId)) {
        _showtimeService.getRoomById(roomId).then((room) {
          if (!isDisposed) {
            _roomCache[roomId] = room;
            print('Đã cache phòng: ${room.id} - ${room.name}');
          }
        }).catchError((e) {
          print('Error preloading room $roomId: $e');
        });
      }
    }

    // Nạp thông tin rạp vào cache
    for (String cinemaId in uniqueCinemaIds) {
      if (!_cinemaCache.containsKey(cinemaId)) {
        _showtimeService.getCinemaById(cinemaId).then((cinema) {
          if (!isDisposed) {
            _cinemaCache[cinemaId] = cinema;
            print('Đã cache rạp: ${cinema.id} - ${cinema.name}');
          }
        }).catchError((e) {
          print('Error preloading cinema $cinemaId: $e');
        });
      }
    }
  }

  void _loadCinemasByProvince(String provinceId) {
    if (isDisposed) return;

    setState(() {
      cinemas = [];
      selectedCinemaId = null;
      selectedRoomId = null;
      rooms = [];
    });

    _cinemasSubscription?.cancel();
    _cinemasSubscription =
        _showtimeService.getCinemasByProvince(provinceId).listen((cinemaList) {
      if (isDisposed) return;
      setState(() {
        cinemas = cinemaList;
      });
    }, onError: (e) {
      if (isDisposed) return;
      print('Error loading cinemas: $e');
    });
  }

  void _loadRoomsByCinema(String cinemaId) async {
    if (isDisposed) return;

    setState(() {
      isLoading = true;
      rooms = [];
    });

    try {
      // Fetch rooms from Firestore
      final QuerySnapshot roomsSnapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .where('cinemaId', isEqualTo: cinemaId)
          .get();

      if (isDisposed) return;

      setState(() {
        rooms = roomsSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Room(
            id: doc.id,
            cinemaId: data['cinemaId'] ?? '',
            name: data['name'] ?? '',
            rows: data['rows'] ?? 0,
            cols: data['cols'] ?? 0,
            seatLayout: [], // We don't need the full seat layout here
          );
        }).toList();

        print('Loaded ${rooms.length} rooms for cinema $cinemaId');
        isLoading = false;
      });
    } catch (e) {
      print('Error loading rooms: $e');
      if (isDisposed) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff252429),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
              children: [
                _buildProvinceSelector(),
                if (selectedProvinceId != null) _buildCinemaSelector(),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildMovieSelector(),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(left: 8),
                          child: _buildRoomSelector(),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDateSelector(),
                Expanded(
                  child: _buildShowtimesList(),
                ),
              ],
            ),
      floatingActionButton: selectedCinemaId != null
          ? FloatingActionButton(
              onPressed: () => _showAddShowtimeDialog(),
              backgroundColor: Colors.orange,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white),
      onChanged: (value) => setState(() => searchQuery = value),
      decoration: const InputDecoration(
        hintText: "Tìm kiếm suất chiếu...",
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
        suffixIcon: Icon(Icons.search, color: Colors.white),
      ),
    );
  }

  Widget _buildProvinceSelector() {
    return Container(
      padding: const EdgeInsets.only(left: 15, right: 15, top: 10),
      child: DropdownButtonFormField<String>(
        value: selectedProvinceId,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.black12,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
          ),
        ),
        dropdownColor: const Color(0xff252429),
        style: const TextStyle(color: Colors.white),
        hint: const Text('Chọn tỉnh/thành phố',
            style: TextStyle(color: Colors.white70)),
        items: provinces.map((province) {
          return DropdownMenuItem<String>(
            value: province.id,
            child: Text(province.name),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            selectedProvinceId = newValue;
            if (newValue != null) {
              _loadCinemasByProvince(newValue);
            }
            selectedCinemaId = null;
            selectedMovieId = null;
          });
        },
      ),
    );
  }

  Widget _buildCinemaSelector() {
    return Container(
      padding: const EdgeInsets.only(right: 15, left: 15, top: 10, bottom: 10),
      child: DropdownButtonFormField<String>(
        value: selectedCinemaId,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.black12,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
          ),
        ),
        dropdownColor: const Color(0xff252429),
        style: const TextStyle(color: Colors.white),
        hint: const Text('Chọn rạp chiếu',
            style: TextStyle(color: Colors.white70)),
        items: cinemas.map((Cinema cinema) {
          return DropdownMenuItem<String>(
            value: cinema.id,
            child: Text(cinema.name),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            selectedCinemaId = newValue;
            if (newValue != null) {
              _loadRoomsByCinema(newValue);
            }
          });
        },
      ),
    );
  }

  Widget _buildMovieSelector() {
    return DropdownButtonFormField<String>(
      value: selectedMovieId,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black12,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      ),
      dropdownColor: const Color(0xff252429),
      style: const TextStyle(color: Colors.white),
      hint: const Text('Chọn phim', style: TextStyle(color: Colors.white70)),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Tất cả phim', style: TextStyle(color: Colors.white70)),
        ),
        ...movies.map((Movie movie) {
          return DropdownMenuItem<String>(
            value: movie.id,
            child: Text(
              movie.title,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      ],
      onChanged: (String? newValue) {
        setState(() {
          selectedMovieId = newValue;
        });
      },
      selectedItemBuilder: (context) {
        return [
          const Text('Tất cả phim', style: TextStyle(color: Colors.white70)),
          ...movies.map((Movie movie) {
            return Text(
              movie.title,
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          }).toList(),
        ];
      },
    );
  }

  String? selectedRoomId;

  Widget _buildRoomSelector() {
    return DropdownButtonFormField<String>(
      value: selectedRoomId,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black12,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      ),
      dropdownColor: const Color(0xff252429),
      style: const TextStyle(color: Colors.white),
      hint: const Text('Chọn phòng', style: TextStyle(color: Colors.white70)),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Tất cả phòng', style: TextStyle(color: Colors.white70)),
        ),
        ...rooms.map((Room room) {
          return DropdownMenuItem<String>(
            value: room.id,
            child: Text(
              room.name,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      ],
      onChanged: (String? newValue) {
        setState(() {
          selectedRoomId = newValue;
        });
      },
      selectedItemBuilder: (context) {
        return [
          const Text('Tất cả phòng', style: TextStyle(color: Colors.white70)),
          ...rooms.map((Room room) {
            return Text(
              room.name,
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          }).toList(),
        ];
      },
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.only(right: 15, left: 15, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.orange),
            onPressed: () {
              setState(() {
                selectedDate = selectedDate.subtract(const Duration(days: 1));
              });
            },
          ),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Text(
                DateFormat('dd/MM/yyyy').format(selectedDate),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.orange),
            onPressed: () {
              setState(() {
                selectedDate = selectedDate.add(const Duration(days: 1));
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShowtimesList() {
    if (selectedCinemaId == null) {
      return const Center(
        child: Text(
          "Vui lòng chọn rạp để xem danh sách suất chiếu!",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    // Kiểm tra xem movies và showtimes đã được load chưa
    if (movies.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text(
              "Đang tải danh sách phim...",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (showtimes.isEmpty) {
      return const Center(
        child: Text(
          "Không có suất chiếu nào trong hệ thống!",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    List<Showtime> filteredShowtimes = showtimes.where((showtime) {
      // Kiểm tra nếu movieId hoặc roomId không tồn tại, bỏ qua suất chiếu đó
      if (showtime.movieId.isEmpty ||
          showtime.roomId.isEmpty ||
          showtime.cinemaId.isEmpty) {
        return false;
      }

      bool matchesDate = showtime.startTime.year == selectedDate.year &&
          showtime.startTime.month == selectedDate.month &&
          showtime.startTime.day == selectedDate.day;

      bool matchesCinema = showtime.cinemaId == selectedCinemaId;

      bool matchesMovie =
          selectedMovieId == null || showtime.movieId == selectedMovieId;

      bool matchesRoom =
          selectedRoomId == null || showtime.roomId == selectedRoomId;

      return matchesDate && matchesCinema && matchesMovie && matchesRoom;
    }).toList();

    filteredShowtimes.sort((a, b) => a.startTime.compareTo(b.startTime));

    if (filteredShowtimes.isEmpty) {
      return const Center(
        child: Text(
          "Không có suất chiếu nào trong ngày đã chọn!",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredShowtimes.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        try {
          return _buildShowtimeCard(filteredShowtimes[index]);
        } catch (e) {
          print('Error building showtime card: $e');
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.5)),
            ),
            child: const Text(
              "Lỗi hiển thị suất chiếu",
              style: TextStyle(color: Colors.white70),
            ),
          );
        }
      },
    );
  }

  Widget _buildShowtimeCard(Showtime showtime) {
    // Tìm thông tin phim từ danh sách đã load
    Movie? movie;
    try {
      movie = movies.firstWhere((m) => m.id == showtime.movieId);
    } catch (e) {
      print('Movie not found for id: ${showtime.movieId}');
      movie = Movie(
        id: showtime.movieId,
        title: 'Phim không xác định',
        imagePath: '',
        trailerUrl: '',
        duration: '',
        genres: [],
        isShowingNow: true,
        description: '',
        cast: [],
        reviewCount: 0,
        releaseDate: '',
        director: '',
      );
    }

    // Cache key để tránh nhiều lần gọi _getShowtimeDetails cho cùng một suất chiếu
    final String cacheKey =
        '${showtime.id}_${showtime.roomId}_${showtime.cinemaId}';

    // Load thông tin phòng và rạp
    return FutureBuilder<Map<String, dynamic>>(
      future: Future.sync(() => _getShowtimeDetails(showtime, cacheKey))
          .catchError((error) {
        print('Error caught in FutureBuilder: $error');
        return {
          'room': Room(
            id: showtime.roomId,
            cinemaId: showtime.cinemaId,
            name: 'Phòng không xác định',
            rows: 0,
            cols: 0,
            seatLayout: [],
          ),
          'cinema': Cinema(
            id: showtime.cinemaId,
            name: 'Rạp không xác định',
            provinceId: '',
            address: '',
          ),
        };
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Colors.orange),
              ),
            ),
          );
        }

        Room room;
        Cinema cinema;

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          print('Error in showtime details: ${snapshot.error}');
          room = Room(
            id: showtime.roomId,
            cinemaId: showtime.cinemaId,
            name: 'Phòng không xác định',
            rows: 0,
            cols: 0,
            seatLayout: [],
          );

          cinema = Cinema(
            id: showtime.cinemaId,
            name: 'Rạp không xác định',
            provinceId: '',
            address: '',
          );
        } else {
          final data = snapshot.data!;

          if (data.containsKey('room') && data['room'] is Room) {
            room = data['room'] as Room;
          } else {
            room = Room(
              id: showtime.roomId,
              cinemaId: showtime.cinemaId,
              name: 'Phòng không xác định',
              rows: 0,
              cols: 0,
              seatLayout: [],
            );
          }

          if (data.containsKey('cinema') && data['cinema'] is Cinema) {
            cinema = data['cinema'] as Cinema;
          } else {
            cinema = Cinema(
              id: showtime.cinemaId,
              name: 'Rạp không xác định',
              provinceId: '',
              address: '',
            );
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              // Header với thông tin phim và thời gian
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    // Thông tin phim và phòng
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie?.title ?? 'Phim không xác định',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            room.name,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Thời gian chiếu
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        DateFormat('HH:mm').format(showtime.startTime),
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Footer với số ghế và các nút
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Số ghế đã đặt
                    InkWell(
                      onTap: () =>
                          _showTicketsDialog(showtime, movie!, room, cinema),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.event_seat,
                              color: Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${showtime.bookedSeats.length}/${room.rows * room.cols}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Các nút hành động
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.confirmation_number,
                              color: Colors.orange, size: 20),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ShowtimeTicketsScreen(
                                  showtime: showtime,
                                  movie: movie!,
                                  room: room,
                                  cinema: cinema,
                                ),
                              ),
                            );
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Xem thông tin vé đã đặt',
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.edit,
                              color: Colors.orange, size: 20),
                          onPressed: () =>
                              _showEditShowtimeDialog(showtime, room, cinema),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getShowtimeDetails(
      Showtime showtime, String cacheKey) async {
    // Thử lấy từ cache trước
    Room room;
    Cinema cinema;

    // Kiểm tra cache cho phòng
    if (_roomCache.containsKey(showtime.roomId)) {
      room = _roomCache[showtime.roomId]!;
    } else {
      try {
        // Lấy thông tin phòng từ service
        room = await _showtimeService.getRoomById(showtime.roomId);
        // Lưu vào cache
        _roomCache[showtime.roomId] = room;
      } catch (e) {
        print('Error loading room: $e');
        // Tạo phòng mặc định nếu có lỗi
        room = Room(
          id: showtime.roomId,
          cinemaId: showtime.cinemaId,
          name: 'Phòng không xác định',
          rows: 0,
          cols: 0,
          seatLayout: [],
        );
      }
    }

    // Kiểm tra cache cho rạp
    if (_cinemaCache.containsKey(showtime.cinemaId)) {
      cinema = _cinemaCache[showtime.cinemaId]!;
    } else {
      try {
        // Lấy thông tin rạp từ service
        cinema = await _showtimeService.getCinemaById(showtime.cinemaId);
        // Lưu vào cache
        _cinemaCache[showtime.cinemaId] = cinema;
      } catch (e) {
        print('Error loading cinema: $e');
        // Tạo rạp mặc định nếu có lỗi
        cinema = Cinema(
          id: showtime.cinemaId,
          name: 'Rạp không xác định',
          provinceId: '',
          address: '',
        );
      }
    }

    return {
      'room': room,
      'cinema': cinema,
    };
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.orange,
              onPrimary: Colors.white,
              surface: Color(0xff252429),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _showAddShowtimeDialog() {
    final _timeController = TextEditingController();
    Movie? selectedMovie;
    Room? selectedRoom;
    DateTime? selectedTime;

    // Check if rooms list is empty
    if (rooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Không có phòng chiếu nào cho rạp này. Vui lòng thêm phòng trước.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xff252429),
          title: const Text(
            "Thêm Suất Chiếu",
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chọn phim
                DropdownButtonFormField<Movie>(
                  decoration: InputDecoration(
                    labelText: "Chọn Phim",
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.orange.withOpacity(0.3)),
                    ),
                  ),
                  dropdownColor: const Color(0xff252429),
                  style: const TextStyle(color: Colors.white),
                  items: movies.map((Movie movie) {
                    return DropdownMenuItem<Movie>(
                      value: movie,
                      child: Text(movie.title),
                    );
                  }).toList(),
                  onChanged: (Movie? value) {
                    setState(() {
                      selectedMovie = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Chọn phòng
                DropdownButtonFormField<Room>(
                  decoration: InputDecoration(
                    labelText: "Chọn Phòng",
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.orange.withOpacity(0.3)),
                    ),
                  ),
                  dropdownColor: const Color(0xff252429),
                  style: const TextStyle(color: Colors.white),
                  items: rooms.map((Room room) {
                    return DropdownMenuItem<Room>(
                      value: room,
                      child: Text(room.name),
                    );
                  }).toList(),
                  onChanged: (Room? value) {
                    setState(() {
                      selectedRoom = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Chọn giờ
                TextFormField(
                  controller: _timeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Chọn Giờ Chiếu",
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.orange.withOpacity(0.3)),
                    ),
                    suffixIcon:
                        const Icon(Icons.access_time, color: Colors.orange),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final TimeOfDay? time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Colors.orange,
                              onPrimary: Colors.white,
                              surface: Color(0xff252429),
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (time != null) {
                      setState(() {
                        selectedTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          time.hour,
                          time.minute,
                        );
                        _timeController.text =
                            DateFormat('HH:mm').format(selectedTime!);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy", style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                if (selectedMovie == null ||
                    selectedRoom == null ||
                    selectedTime == null ||
                    selectedCinemaId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng điền đầy đủ thông tin!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  // Tạo ID cho showtime mới
                  final String newShowtimeId = FirebaseFirestore.instance
                      .collection('showtimes')
                      .doc()
                      .id;

                  // Tạo showtime mới với startTime là Timestamp
                  final newShowtime = {
                    'id': newShowtimeId,
                    'movieId': selectedMovie!.id,
                    'cinemaId': selectedCinemaId!,
                    'roomId': selectedRoom!.id,
                    'startTime': Timestamp.fromDate(selectedTime!),
                    'bookedSeats': [],
                  };

                  // Thêm vào Firebase
                  await FirebaseFirestore.instance
                      .collection('showtimes')
                      .doc(newShowtimeId)
                      .set(newShowtime);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thêm suất chiếu thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  print('Error adding showtime: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khi thêm suất chiếu: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Thêm", style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditShowtimeDialog(Showtime showtime, Room room, Cinema cinema) {
    Movie movie;
    try {
      movie = movies.firstWhere((m) => m.id == showtime.movieId);
    } catch (e) {
      print('Movie not found for edit: ${showtime.movieId}');
      movie = Movie(
        id: showtime.movieId,
        title: 'Phim không xác định',
        imagePath: '',
        trailerUrl: '',
        duration: '',
        genres: [],
        isShowingNow: true,
        description: '',
        cast: [],
        reviewCount: 0,
        releaseDate: '',
        director: '',
      );
    }

    final _timeController = TextEditingController(
      text: DateFormat('HH:mm').format(showtime.startTime),
    );
    DateTime? selectedTime = showtime.startTime;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff252429),
        title: const Text(
          "Chỉnh Sửa Suất Chiếu",
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hiển thị thông tin phim (không cho phép thay đổi)
              ListTile(
                title: const Text(
                  "Phim",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                subtitle: Text(
                  movie.title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),

              // Hiển thị thông tin phòng (không cho phép thay đổi)
              ListTile(
                title: const Text(
                  "Phòng",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                subtitle: Text(
                  room.name,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),

              // Chọn giờ mới
              TextFormField(
                controller: _timeController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Giờ Chiếu",
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.orange.withOpacity(0.3)),
                  ),
                  suffixIcon:
                      const Icon(Icons.access_time, color: Colors.orange),
                ),
                readOnly: true,
                onTap: () async {
                  final TimeOfDay? time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(showtime.startTime),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Colors.orange,
                            onPrimary: Colors.white,
                            surface: Color(0xff252429),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (time != null) {
                    selectedTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      time.hour,
                      time.minute,
                    );
                    _timeController.text =
                        DateFormat('HH:mm').format(selectedTime!);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              if (selectedTime == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng chọn giờ chiếu!'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                // Cập nhật giờ chiếu
                Map<String, dynamic> updateData = {
                  'startTime': Timestamp.fromDate(selectedTime!),
                };

                await _showtimeService.updateShowtime(showtime.id, updateData);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cập nhật suất chiếu thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                print('Error updating showtime: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi khi cập nhật suất chiếu: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Lưu", style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      selectedMovieId = null;
      selectedRoomId = null;
    });
  }

  void _showTicketsDialog(
      Showtime showtime, Movie movie, Room room, Cinema cinema) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xff252429),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      movie.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Thống kê
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Tổng số ghế', '${room.rows * room.cols}',
                        Colors.white),
                    _buildStatItem('Đã đặt', '${showtime.bookedSeats.length}',
                        Colors.orange),
                    _buildStatItem(
                      'Còn trống',
                      '${(room.rows * room.cols) - showtime.bookedSeats.length}',
                      Colors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Danh sách ghế
              const Text(
                'Danh sách ghế đã đặt:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Danh sách ghế đã đặt
              if (showtime.bookedSeats.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Chưa có ghế nào được đặt',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                )
              else
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: showtime.bookedSeats.map((seat) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              '$seat',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
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
