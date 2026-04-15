import 'package:cloud_firestore/cloud_firestore.dart';
import '../Model/Movie.dart';
import '../Model/Genre.dart';

class MovieService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection = 'movies';

  // Lấy danh sách phim
  Stream<List<Movie>> getMovies() {
    return _firestore
        .collection(collection)
        .where('status', whereIn: ['showing', 'upcoming'])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            try {
              final data = doc.data();
              return Movie.fromJson({...data, 'id': doc.id});
            } catch (e) {
              return Movie(
                id: doc.id,
                title: 'Error loading movie',
                imagePath: '',
                trailerUrl: '',
                duration: 'N/A',
                genres: [], // Empty list of genres
                isShowingNow: false,
                description: '',
                cast: [],
                reviewCount: 0,
                releaseDate: '',
                director: '',
                status: MovieStatus.upcoming,
              );
            }
          }).toList();
        });
  }

  // Thêm phim mới
  Future<String> addMovie(Movie movie) async {
    try {
      // Xác định trạng thái phim dựa trên ngày phát hành
      String status = 'upcoming';
      if (movie.isShowingNow) {
        status = 'showing';
      }

      final docRef = await _firestore.collection(collection).add({
        ...movie.toJson(),
        'genres': movie.genres.map((genre) => genre.toJson()).toList(),
        'status': status,
      });
      return docRef.id;
    } catch (e) {
      print('Error adding movie: $e');
      throw e;
    }
  }

  // Cập nhật phim
  Future<void> updateMovie(Movie movie) async {
    try {
      // Xác định trạng thái phim dựa trên ngày phát hành
      String status = 'upcoming';
      if (movie.isShowingNow) {
        status = 'showing';
      }

      await _firestore.collection(collection).doc(movie.id).update({
        ...movie.toJson(),
        'genres': movie.genres.map((genre) => genre.toJson()).toList(),
        'status': status,
      });
    } catch (e) {
      print('Error updating movie: $e');
      throw e;
    }
  }

  // Xóa phim
  Future<void> deleteMovie(String id) async {
    try {
      await _firestore.collection(collection).doc(id).update({
        'status': 'deleted', // Đánh dấu phim là đã xóa
      });
    } catch (e) {
      print('Error deleting movie: $e');
      throw e;
    }
  }

  // Lấy phim theo ID
  Future<Movie?> getMovieById(String id) async {
    try {
      final doc = await _firestore.collection(collection).doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        return Movie.fromJson({...data, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error getting movie: $e');
      throw e;
    }
  }

  // Lấy danh sách phim theo thể loại
  Stream<List<Movie>> getMoviesByGenre(String genreId) {
    return _firestore
        .collection(collection)
        .where('status', whereIn: ['showing', 'upcoming'])
        .where('genres', arrayContains: {'id': genreId})
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Movie.fromJson({...data, 'id': doc.id});
          }).toList();
        });
  }

  // Lấy danh sách phim đang chiếu
  Stream<List<Movie>> getNowShowingMovies() {
    return _firestore
        .collection(collection)
        .where('status', isEqualTo: 'showing')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Movie.fromJson({...data, 'id': doc.id});
      }).toList();
    });
  }

  // Lấy danh sách phim sắp chiếu
  Stream<List<Movie>> getUpcomingMovies() {
    return _firestore
        .collection(collection)
        .where('status', isEqualTo: 'upcoming')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Movie.fromJson({...data, 'id': doc.id});
      }).toList();
    });
  }

  // Lấy danh sách phim theo tên
  Stream<List<Movie>> searchMovies(String query) {
    return _firestore
        .collection(collection)
        .where('status', whereIn: ['showing', 'upcoming'])
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Movie.fromJson({...data, 'id': doc.id});
          }).toList();
        });
  }

  // Khôi phục phim đã xóa
  Future<void> restoreMovie(String id) async {
    try {
      await _firestore.collection(collection).doc(id).update({
        'status': 'upcoming', // Khôi phục về trạng thái sắp chiếu
      });
    } catch (e) {
      print('Error restoring movie: $e');
      throw e;
    }
  }

  // Lấy danh sách phim đã xóa
  Stream<List<Movie>> getDeletedMovies() {
    return _firestore
        .collection(collection)
        .where('status', isEqualTo: 'deleted')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Movie.fromJson({...data, 'id': doc.id});
      }).toList();
    });
  }
}
