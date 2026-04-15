import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movieticketbooking/Model/Comment.dart';
import 'package:movieticketbooking/Model/User.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tạo bình luận và đánh giá mới
  Future<void> createComment(Comment comment) async {
    try {
      final commentData = {
        'id': comment.id,
        'userId': comment.userId,
        'movieId': comment.movieId,
        'content': comment.content,
        'createdAt': Timestamp.fromDate(comment.createdAt),
        'rating': comment.rating,
        'userName': comment.userName,
        'ticketId': comment.ticketId,
      };

      // 1. Lưu bình luận vào Firestore
      await _firestore.collection('comments').doc(comment.id).set(commentData);

      // 2. Cập nhật số lượng đánh giá cho phim
      await _firestore.collection('movies').doc(comment.movieId).update({
        'reviewCount': FieldValue.increment(1),
      });

      print('Đã lưu bình luận và đánh giá thành công');
    } catch (e) {
      print('Error creating comment: $e');
      throw e;
    }
  }

  // Lấy thông tin bình luận theo ID
  Future<Comment?> getCommentById(String commentId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('comments').doc(commentId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Comment.fromMap(data);
      }
      return null;
    } catch (e) {
      print('Error getting comment: $e');
      throw e;
    }
  }

  // Cập nhật thông tin bình luận
  Future<void> updateComment(
      String commentId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('comments').doc(commentId).update(data);
    } catch (e) {
      print('Error updating comment: $e');
      throw e;
    }
  }

  // Xóa bình luận
  Future<void> deleteComment(String commentId) async {
    try {
      await _firestore.collection('comments').doc(commentId).delete();
    } catch (e) {
      print('Error deleting comment: $e');
      throw e;
    }
  }

  // Lấy danh sách tất cả bình luận
  Stream<List<Comment>> getAllComments() {
    return _firestore.collection('comments').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Comment.fromMap(data);
      }).toList();
    });
  }

  // Lấy danh sách bình luận theo phim (Sắp xếp thủ công để tránh lỗi Index)
  Stream<List<Comment>> getCommentsByMovie(String movieId) {
    return _firestore
        .collection('comments')
        .where('movieId', isEqualTo: movieId)
        .snapshots()
        .map((snapshot) {
      final comments = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Comment.fromMap(data);
      }).toList();

      // Sắp xếp mới nhất lên đầu
      comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return comments;
    });
  }

  // Lấy danh sách bình luận theo người dùng
  Stream<List<Comment>> getCommentsByUser(String userId) {
    return _firestore
        .collection('comments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final comments = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Comment.fromMap(data);
      }).toList();
      
      comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return comments;
    });
  }

  // Lấy danh sách bình luận mới nhất
  Stream<List<Comment>> getLatestComments({int limit = 10}) {
    return _firestore
        .collection('comments')
        .snapshots()
        .map((snapshot) {
      final comments = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Comment.fromMap(data);
      }).toList();

      comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return comments.take(limit).toList();
    });
  }

  // Lấy thông tin người dùng cho một comment
  Future<User?> getUserForComment(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return User.fromJson(userDoc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user for comment: $e');
      return null;
    }
  }
}
