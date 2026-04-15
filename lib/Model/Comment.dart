import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id; // ID của bình luận
  final String userId; // ID của người dùng
  final String movieId; // ID của phim
  final String content; // Nội dung bình luận
  final DateTime createdAt; // Thời gian bình luận
  final double rating; // Điểm đánh giá của người dùng
  final String userName; // Tên người dùng
  final String ticketId; // ID của vé

  const Comment({
    required this.id,
    required this.userId,
    required this.movieId,
    required this.content,
    required this.createdAt,
    required this.rating,
    required this.userName,
    required this.ticketId,
  });

  /// Chuyển đổi từ JSON sang Comment object
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      movieId: json['movieId'] as String,
      content: json['content'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      rating: (json['rating'] as num).toDouble(),
      userName: json['userName'] as String,
      ticketId: json['ticketId'] as String,
    );
  }

  /// Chuyển đổi từ Comment object sang JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'movieId': movieId,
        'content': content,
        'createdAt': createdAt,
        'rating': rating,
        'userName': userName,
        'ticketId': ticketId,
      };

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'movieId': movieId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'rating': rating,
      'userName': userName,
      'ticketId': ticketId,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    DateTime parseCreatedAt(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      }
      throw Exception('Invalid createdAt format');
    }

    return Comment(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      movieId: map['movieId'] ?? '',
      content: map['content'] ?? '',
      createdAt: parseCreatedAt(map['createdAt']),
      rating: (map['rating'] ?? 0.0).toDouble(),
      userName: map['userName'] ?? 'Người dùng',
      ticketId: map['ticketId'] ?? '',
    );
  }
}
