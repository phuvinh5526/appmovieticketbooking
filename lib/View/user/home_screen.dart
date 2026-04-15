import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import '../../../Components/movie_card_widget.dart';
import '../../../Components/backgroud_widget.dart';
import '../../Model/Movie.dart';
import '../../Services/movie_service.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController controller = PageController();
  final MovieService _movieService = MovieService();
  bool isLoggined = false;
  bool _isLoading = true;
  List<Movie> _showingMovies = [];

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  void _loadMovies() {
    _movieService.getNowShowingMovies().listen(
      (movies) async {
        setState(() {
          _showingMovies = movies;
          _isLoading = false;
        });

        // Cập nhật rating cho từng phim
        for (var movie in movies) {
          final ratingData = await Movie.calculateRating(movie.id);
          await movie.updateReviewCount();
        }
      },
      onError: (error) {
        print('Error loading movies: $error');
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã có lỗi xảy ra khi tải danh sách phim'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  bool checkUserLoginStatus() {
    // Giả sử lấy trạng thái từ SharedPreferences
    return isLoggined ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xff252429),
        body: Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xff252429),
      body: Stack(
        children: [
          if (_showingMovies.isNotEmpty)
            BackgroundWidget(
              controller: controller,
              movies: _showingMovies,
            ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 12.0,
                right: 12.0,
                top: 50.0,
                bottom: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome text and Chat button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chào bạn!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.orange.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Hôm nay bạn muốn xem phim gì?',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.orange,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ChatScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (_showingMovies.isNotEmpty)
                    CarouselSlider(
                      items: _showingMovies
                          .map((movie) => MovieCardWidget(movie: movie))
                          .toList(),
                      options: CarouselOptions(
                        enableInfiniteScroll: _showingMovies.length > 1,
                        viewportFraction: 0.75,
                        height: MediaQuery.of(context).size.height * 0.7,
                        enlargeCenterPage: true,
                        onPageChanged: (index, reason) {
                          controller.animateToPage(
                            index,
                            duration: const Duration(seconds: 1),
                            curve: Curves.ease,
                          );
                        },
                      ),
                    )
                  else
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.movie_outlined,
                            size: 64,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Hiện tại không có phim nào đang chiếu!",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
