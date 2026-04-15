import 'package:flutter/foundation.dart';
import 'package:movieticketbooking/Model/Movie.dart';
import 'package:movieticketbooking/Services/movie_service.dart';

class MovieProvider with ChangeNotifier {
  final MovieService _movieService = MovieService();
  List<Movie> _movies = [];
  bool _isLoading = false;
  String? _error;

  List<Movie> get movies => _movies;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMovies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final movies = await _movieService.getNowShowingMovies().first;

      // Cập nhật rating cho từng phim
      for (var movie in movies) {
        final ratingData = await Movie.calculateRating(movie.id);
        await movie.updateReviewCount();
      }

      _movies = movies;
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      print('Error loading movies: $error');
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
