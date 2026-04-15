import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Thêm thư viện CachedNetworkImage
import '../../Model/Movie.dart';
import '../../Model/Genre.dart';
import '../../Services/movie_service.dart';
import '../../Services/genre_service.dart';
import 'movie_edit_screen.dart';

class MovieManagementScreen extends StatefulWidget {
  const MovieManagementScreen({Key? key}) : super(key: key);

  @override
  _MovieManagementScreenState createState() => _MovieManagementScreenState();
}

class _MovieManagementScreenState extends State<MovieManagementScreen> {
  final MovieService _movieService = MovieService();
  final GenreService _genreService = GenreService();
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _genreNameController = TextEditingController();
  int selectedTab = 0;
  List<Movie> allMovies = [];
  List<Movie> deletedMovies = []; // Thêm danh sách phim đã xóa
  List<Genre> allGenres = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMovies();
    _loadGenres();
    _loadDeletedMovies(); // Thêm hàm load phim đã xóa
  }

  void _loadMovies() {
    _movieService.getMovies().listen(
      (movies) {
        setState(() {
          allMovies = movies;
          _isLoading = false;
        });
      },
      onError: (error) {
        print('Error loading movies: $error');
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã có lỗi xảy ra khi tải danh sách phim'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  void _loadGenres() {
    _genreService.getAllGenres().listen(
      (genres) {
        setState(() {
          allGenres = genres;
        });
      },
      onError: (error) {
        print('Error loading genres: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã có lỗi xảy ra khi tải danh sách thể loại'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  void _loadDeletedMovies() {
    _movieService.getDeletedMovies().listen(
      (movies) {
        setState(() {
          deletedMovies = movies;
        });
      },
      onError: (error) {
        print('Error loading deleted movies: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã có lỗi xảy ra khi tải danh sách phim đã xóa'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  void _showAddGenreDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff252429),
        title: const Text(
          'Thêm thể loại mới',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _genreNameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Nhập tên thể loại',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.orange),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.orange),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _genreNameController.clear();
            },
            child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              if (_genreNameController.text.trim().isNotEmpty) {
                try {
                  final newGenre = Genre(
                    id: '', // ID sẽ được Firestore tự động tạo
                    name: _genreNameController.text.trim(),
                  );
                  await _genreService.createGenre(newGenre);
                  Navigator.pop(context);
                  _genreNameController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã thêm thể loại "${newGenre.name}"'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Không thể thêm thể loại. Vui lòng thử lại.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Thêm', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _showGenresDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff252429),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quản lý thể loại',
              style: TextStyle(color: Colors.white),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.orange),
              onPressed: () {
                Navigator.pop(context);
                _showAddGenreDialog();
              },
              tooltip: 'Thêm thể loại mới',
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<Genre>>(
            stream: _genreService.getAllGenres(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text(
                  'Đã có lỗi xảy ra',
                  style: TextStyle(color: Colors.red),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                );
              }

              final genres = snapshot.data!;
              if (genres.isEmpty) {
                return const Center(
                  child: Text(
                    'Chưa có thể loại nào',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: genres.length,
                itemBuilder: (context, index) {
                  final genre = genres[index];
                  return ListTile(
                    title: Text(
                      genre.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Nút chỉnh sửa
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: Colors.orange),
                          onPressed: () {
                            _showEditGenreDialog(genre);
                          },
                        ),
                        // Nút xóa
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => _showDeleteGenreDialog(genre),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _showEditGenreDialog(Genre genre) {
    final editController = TextEditingController(text: genre.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff252429),
        title: const Text(
          'Chỉnh sửa thể loại',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: editController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Nhập tên thể loại mới',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.orange),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.orange),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              if (editController.text.trim().isNotEmpty) {
                try {
                  final updatedGenre = Genre(
                    id: genre.id,
                    name: editController.text.trim(),
                  );
                  await _genreService.updateGenre(updatedGenre);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Đã cập nhật thể loại thành "${updatedGenre.name}"'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Không thể cập nhật thể loại. Vui lòng thử lại.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Lưu', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _showDeleteGenreDialog(Genre genre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff252429),
        title: const Text(
          'Xác nhận xóa',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Bạn có chắc muốn xóa thể loại "${genre.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _genreService.deleteGenre(genre.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa thể loại "${genre.name}"'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Không thể xóa thể loại. Vui lòng thử lại.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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

    List<Movie> showingNowMovies = _filterMovies(isShowingNow: true);
    List<Movie> comingSoonMovies = _filterMovies(isShowingNow: false);

    return Scaffold(
      backgroundColor: const Color(0xff252429),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          const SizedBox(height: 16),
          Expanded(
            child: selectedTab == 0
                ? _buildMovieList(showingNowMovies)
                : selectedTab == 1
                    ? _buildMovieList(comingSoonMovies)
                    : _buildDeletedMovieList(deletedMovies),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addMovie',
        onPressed: () => _navigateToEditScreen(),
        backgroundColor: Colors.orange,
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Thêm phim",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xff252429),
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Ô tìm kiếm
          Expanded(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Tìm kiếm phim...",
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.orange),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            setState(() {
                              searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) => setState(() => searchQuery = value),
              ),
            ),
          ),
          // Nút quản lý thể loại
          const SizedBox(width: 16),
          Container(
            height: 45,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showGenresDialog,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.category_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Thể loại",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabButton("Phim đang chiếu", 0)),
          Expanded(child: _buildTabButton("Phim sắp chiếu", 1)),
          Expanded(child: _buildTabButton("Đã xóa", 2)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMovieList(List<Movie> movies) {
    if (movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_outlined,
                size: 64, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              "Không có phim nào!",
              style:
                  TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: movies.length,
      itemBuilder: (context, index) => _buildMovieCard(movies[index]),
    );
  }

  Widget _buildMovieCard(Movie movie) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => _navigateToEditScreen(movie: movie),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Poster
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 100,
                  height: 140,
                  child: movie.imagePath.isNotEmpty
                      ? (movie.imagePath.startsWith('http'))
                          ? CachedNetworkImage(
                              imageUrl: movie.imagePath,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.black26,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error, color: Colors.orange),
                            )
                          : Image.file(
                              File(movie.imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.error, color: Colors.orange),
                            )
                      : Container(
                          color: Colors.black26,
                          child: const Icon(
                            Icons.movie,
                            size: 40,
                            color: Colors.orange,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Movie Info
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
                    // Rating và Duration
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        FutureBuilder<Map<String, dynamic>>(
                          future: Movie.calculateRating(movie.id),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                "${(snapshot.data!['rating'] as num).toStringAsFixed(1)}/10",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              );
                            }
                            return const Text(
                              "0.0/10",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.access_time,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          movie.duration,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: movie.isShowingNow
                            ? Colors.green.withOpacity(0.2)
                            : Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: movie.isShowingNow
                              ? Colors.green.withOpacity(0.5)
                              : Colors.blue.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        movie.isShowingNow ? "Đang chiếu" : "Sắp chiếu",
                        style: TextStyle(
                          color:
                              movie.isShowingNow ? Colors.green : Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Action Buttons
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _navigateToEditScreen(movie: movie),
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.orange,
                    ),
                    tooltip: 'Chỉnh sửa',
                  ),
                  IconButton(
                    onPressed: () => _showDeleteDialog(movie),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    tooltip: 'Xóa',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(Movie movie) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff252429),
        title: const Text(
          'Xóa phim',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Bạn có chắc muốn xóa phim "${movie.title}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _movieService.deleteMovie(movie.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa phim "${movie.title}"'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Không thể xóa phim. Vui lòng thử lại sau.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  List<Movie> _filterMovies({required bool isShowingNow}) {
    return allMovies.where((movie) {
      bool matchesSearch = searchQuery.isEmpty ||
          movie.title.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesSearch && movie.isShowingNow == isShowingNow;
    }).toList();
  }

  void _navigateToEditScreen({Movie? movie}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieEditScreen(
          isEdit: movie != null,
          movie: movie,
        ),
      ),
    );

    if (result != null && result is Movie) {
      try {
        if (movie == null) {
          // Thêm phim mới
          await _movieService.addMovie(result);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã thêm phim "${result.title}"'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Cập nhật phim
          await _movieService.updateMovie(result);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã cập nhật phim "${result.title}"'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Cập nhật UI nếu cần
        setState(() {
          if (result.isShowingNow && selectedTab != 0) {
            selectedTab = 0;
          } else if (!result.isShowingNow && selectedTab != 1) {
            selectedTab = 1;
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã có lỗi xảy ra. Vui lòng thử lại sau.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDeletedMovieList(List<Movie> movies) {
    if (movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_outlined,
                size: 64, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              "Không có phim nào!",
              style:
                  TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: movies.length,
      itemBuilder: (context, index) => _buildDeletedMovieCard(movies[index]),
    );
  }

  Widget _buildDeletedMovieCard(Movie movie) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 100,
                height: 140,
                child: movie.imagePath.isNotEmpty
                    ? (movie.imagePath.startsWith('http'))
                        ? CachedNetworkImage(
                            imageUrl: movie.imagePath,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.black26,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error, color: Colors.orange),
                          )
                        : Image.file(
                            File(movie.imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.error, color: Colors.orange),
                          )
                    : Container(
                        color: Colors.black26,
                        child: const Icon(
                          Icons.movie,
                          size: 40,
                          color: Colors.orange,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Movie Info
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
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đạo diễn: ${movie.director}',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Thời lượng: ${movie.duration}',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Ngày phát hành: ${movie.releaseDate}',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            // Action buttons
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _showRestoreDialog(movie),
                  icon: const Icon(
                    Icons.restore,
                    color: Colors.green,
                  ),
                  tooltip: 'Khôi phục',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRestoreDialog(Movie movie) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff252429),
        title: const Text(
          'Khôi phục phim',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Bạn có chắc muốn khôi phục phim "${movie.title}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _movieService.restoreMovie(movie.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã khôi phục phim "${movie.title}"'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Không thể khôi phục phim. Vui lòng thử lại sau.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child:
                const Text('Khôi phục', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }
}
