import 'Comment.dart';
import 'Genre.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum MovieStatus {
  showing, // Đang chiếu
  upcoming, // Sắp chiếu
  deleted // Đã xóa
}

class Movie {
  final String id;
  final String title;
  final String imagePath;
  final String trailerUrl;
  final String duration;
  final List<Genre> genres;
  final bool isShowingNow;
  final String description;
  final List<String> cast;
  final int reviewCount;
  final String releaseDate;
  final String director;
  final MovieStatus status;

  const Movie({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.trailerUrl,
    required this.duration,
    required this.genres,
    required this.isShowingNow,
    required this.description,
    required this.cast,
    required this.reviewCount,
    required this.releaseDate,
    required this.director,
    this.status = MovieStatus.upcoming,
  });

  /// Tính toán rating của movie dựa trên trung bình rating của các comment
  static Future<Map<String, dynamic>> calculateRating(String movieId) async {
    try {
      final comments = await FirebaseFirestore.instance
          .collection('comments')
          .where('movieId', isEqualTo: movieId)
          .get();

      if (comments.docs.isEmpty) {
        return {
          'rating': 0.0,
          'reviewCount': 0,
        };
      }

      final totalRating = comments.docs.fold<double>(
        0,
        (sum, doc) => sum + (doc.data()['rating'] as num).toDouble(),
      );

      final averageRating = totalRating / comments.docs.length;

      return {
        'rating': averageRating,
        'reviewCount': comments.docs.length,
      };
    } catch (e) {
      print('Error calculating movie rating: $e');
      return {
        'rating': 0.0,
        'reviewCount': 0,
      };
    }
  }

  /// Cập nhật reviewCount của movie trong Firestore
  Future<void> updateReviewCount() async {
    try {
      final ratingData = await Movie.calculateRating(id);
      await FirebaseFirestore.instance.collection('movies').doc(id).update({
        'reviewCount': ratingData['reviewCount'],
      });
    } catch (e) {
      print('Error updating movie review count: $e');
    }
  }

  /// Chuyển từ JSON sang `Movie`
  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? "",
      title: json['title'] ?? "Chưa có tên",
      imagePath: json['imagePath'] ?? "",
      trailerUrl: json['trailerUrl'] ?? "",
      duration: json['duration'] ?? "N/A",
      genres: (json['genres'] as List? ?? [])
          .map((genre) => Genre.fromJson(genre))
          .toList(),
      isShowingNow: json['isShowingNow'] ?? false,
      description: json['description'] ?? "Chưa có mô tả",
      cast: List<String>.from(json['cast'] ?? []),
      reviewCount: json['reviewCount'] ?? 0,
      releaseDate: json['releaseDate'] ?? "Chưa xác định",
      director: json['director'] ?? "Không rõ",
      status: MovieStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] ?? 'upcoming'),
        orElse: () => MovieStatus.upcoming,
      ),
    );
  }

  /// Chuyển từ `Movie` sang JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'imagePath': imagePath,
        'trailerUrl': trailerUrl,
        'duration': duration,
        'genres': genres.map((genre) => genre.toJson()).toList(),
        'isShowingNow': isShowingNow,
        'description': description,
        'cast': cast,
        'reviewCount': reviewCount,
        'releaseDate': releaseDate,
        'director': director,
        'status': status.toString().split('.').last,
      };

  /// Cập nhật một phần dữ liệu của `Movie`
  Movie copyWith({
    String? id,
    String? title,
    String? imagePath,
    String? trailerUrl,
    String? duration,
    List<Genre>? genres,
    bool? isShowingNow,
    String? description,
    List<String>? cast,
    int? reviewCount,
    String? releaseDate,
    String? director,
    MovieStatus? status,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      imagePath: imagePath ?? this.imagePath,
      trailerUrl: trailerUrl ?? this.trailerUrl,
      duration: duration ?? this.duration,
      genres: genres ?? this.genres,
      isShowingNow: isShowingNow ?? this.isShowingNow,
      description: description ?? this.description,
      cast: cast ?? this.cast,
      reviewCount: reviewCount ?? this.reviewCount,
      releaseDate: releaseDate ?? this.releaseDate,
      director: director ?? this.director,
      status: status ?? this.status,
    );
  }
}
