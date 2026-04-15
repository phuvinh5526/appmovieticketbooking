import 'package:flutter/material.dart';
import 'package:movieticketbooking/Components/bottom_nav_bar.dart';
import 'package:movieticketbooking/View/user/movie_detail_screen.dart';
import '../../Model/Movie.dart';
import '../../Model/Genre.dart';
import '../../Services/movie_service.dart';
import '../../Services/genre_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

class MovieListScreen extends StatefulWidget {
  @override
  _MovieListScreenState createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  int selectedTab = 0;
  Genre? selectedGenre;
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  List<Genre> genres = [];
  List<Movie> movies = [];
  bool isLoading = true;
  final MovieService _movieService = MovieService();
  final GenreService _genreService = GenreService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() {
      isLoading = true;
    });

    // Lắng nghe stream thể loại phim
    _genreService.getAllGenres().listen((genreList) {
      setState(() {
        genres = genreList;
      });
    });

    // Lắng nghe stream danh sách phim
    _movieService.getMovies().listen((movieList) {
      setState(() {
        movies = movieList;
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Movie> filteredMovies = _filterMovies();

    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: const Color(0xff252429),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
              children: [
                _buildTabBar(),
                const SizedBox(height: 16),
                _buildGenreFilter(),
                const SizedBox(height: 16),
                Expanded(
                  child: filteredMovies.isEmpty
                      ? _buildNoMoviesMessage()
                      : _buildMovieList(filteredMovies),
                ),
              ],
            ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: _buildSearchField(),
      centerTitle: true,
      backgroundColor: const Color(0xff252429),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => BottomNavBar()));
        },
      ),
    );
  }

  TextField _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => searchQuery = value),
      decoration: InputDecoration(
        hintText: "Tìm kiếm phim...",
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        prefixIcon: const Icon(Icons.search, color: Colors.white70),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 16),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTabButton("Phim đang chiếu", 0),
          const SizedBox(width: 80),
          _buildTabButton("Phim sắp chiếu", 1),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: selectedTab == index ? Colors.orange : Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 3,
            width: 120,
            decoration: BoxDecoration(
              color: selectedTab == index ? Colors.orange : Colors.transparent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreFilter() {
    return Container(
      height: 45,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: genres.length + 1, // +1 cho tùy chọn "Tất cả"
        itemBuilder: (context, index) {
          if (index == 0) {
            // Tùy chọn "Tất cả" ở vị trí đầu tiên
            return _buildAllGenreChip();
          } else {
            // Các thể loại khác
            return _buildGenreChip(genres[index - 1]);
          }
        },
      ),
    );
  }

  Widget _buildAllGenreChip() {
    return GestureDetector(
      onTap: () => setState(() => selectedGenre = null),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: selectedGenre == null
              ? Colors.orange
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: selectedGenre == null
                ? Colors.orange
                : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          "Tất cả",
          style: TextStyle(
            color: selectedGenre == null ? Colors.black : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildGenreChip(Genre genre) {
    return GestureDetector(
      onTap: () => setState(() => selectedGenre = genre),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: selectedGenre?.id == genre.id
              ? Colors.orange
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: selectedGenre?.id == genre.id
                ? Colors.orange
                : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          genre.name,
          style: TextStyle(
            color: selectedGenre?.id == genre.id ? Colors.black : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNoMoviesMessage() {
    return const Center(
      child: Text("Không có phim nào!",
          style: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }

  Widget _buildMovieList(List<Movie> movies) {
    return ListView.builder(
      itemCount: movies.length,
      itemBuilder: (context, index) => _buildMovieCard(movies[index]),
    );
  }

  Widget _buildMovieCard(Movie movie) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => MovieDetailScreen(movie: movie)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildMovieImage(movie.imagePath),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      buildTag(movie.releaseDate),
                      const SizedBox(width: 8),
                      buildTag(movie.duration),
                    ],
                  ),
                  const SizedBox(height: 8),
                  buildTag(movie.genres.map((genre) => genre.name).join(" | ")),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      FutureBuilder<Map<String, dynamic>>(
                        future: Movie.calculateRating(movie.id),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              "${(snapshot.data!['rating'] as num).toStringAsFixed(1)}/10",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          }
                          return const Text(
                            "0.0/10",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieImage(String imagePath) {
    // Kiểm tra xem imagePath có phải là URL hay không
    bool isNetworkImage =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');

    if (isNetworkImage) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        width: 90,
        height: 120,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[800],
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.orange,
                strokeWidth: 2.0,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[800],
          child: const Icon(Icons.image_not_supported, color: Colors.white),
        ),
      );
    } else {
      // Xử lý ảnh local
      try {
        return Image.file(
          File(imagePath),
          width: 90,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 90,
            height: 120,
            color: Colors.grey[800],
            child: const Icon(Icons.image_not_supported, color: Colors.white),
          ),
        );
      } catch (e) {
        // Fallback nếu không thể load file
        return Container(
          width: 90,
          height: 120,
          color: Colors.grey[800],
          child: const Icon(Icons.image_not_supported, color: Colors.white),
        );
      }
    }
  }

  Widget buildTag(String text) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  List<Movie> _filterMovies() {
    if (movies.isEmpty) return [];

    return movies.where((movie) {
      bool matchesTab =
          selectedTab == 0 ? movie.isShowingNow : !movie.isShowingNow;

      bool matchesGenre = selectedGenre == null ||
          movie.genres.any((genre) => genre.id == selectedGenre?.id);

      bool matchesSearch = searchQuery.isEmpty ||
          movie.title.toLowerCase().contains(searchQuery.toLowerCase());

      return matchesTab && matchesGenre && matchesSearch;
    }).toList();
  }
}
