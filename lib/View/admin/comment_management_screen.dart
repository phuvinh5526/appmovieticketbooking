import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Model/Movie.dart';
import '../../Model/Comment.dart';

class CommentManagementScreen extends StatefulWidget {
  const CommentManagementScreen({Key? key}) : super(key: key);

  @override
  _CommentManagementScreenState createState() =>
      _CommentManagementScreenState();
}

class _CommentManagementScreenState extends State<CommentManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedMovieId;
  List<Movie> _movies = [];
  List<Comment> _allComments = []; // Lưu trữ tất cả bình luận
  List<Comment> _filteredComments = []; // Danh sách hiển thị sau khi lọc
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await _loadMovies();
    await _loadAllComments();
    setState(() => _isLoading = false);
  }

  Future<void> _loadMovies() async {
    try {
      final moviesSnapshot = await _firestore.collection('movies').get();
      _movies = moviesSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Movie.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error loading movies: $e');
    }
  }

  Future<void> _loadAllComments() async {
    try {
      final commentsSnapshot = await _firestore
          .collection('comments')
          .get();

      final List<Comment> comments = [];

      for (var doc in commentsSnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;

          // Lấy tên thật của người dùng từ collection 'users'
          if (data['userId'] != null) {
            final userDoc = await _firestore.collection('users').doc(data['userId']).get();
            if (userDoc.exists) {
              data['userName'] = userDoc.data()?['fullName'] ?? 'Người dùng ẩn danh';
            } else {
              data['userName'] = 'Tài khoản đã xóa';
            }
          }

          if (!data.containsKey('ticketId')) {
            data['ticketId'] = '';
          }

          comments.add(Comment.fromMap(data));
        } catch (e) {
          print('Error processing comment ${doc.id}: $e');
          continue;
        }
      }

      // Sắp xếp theo thời gian mới nhất
      comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _allComments = comments;
        _applyFilter();
      });
    } catch (e) {
      print('Error loading all comments: $e');
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedMovieId == null) {
        _filteredComments = List.from(_allComments);
      } else {
        _filteredComments = _allComments
            .where((comment) => comment.movieId == _selectedMovieId)
            .toList();
      }
    });
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await _firestore.collection('comments').doc(commentId).delete();
      
      setState(() {
        _allComments.removeWhere((c) => c.id == commentId);
        _applyFilter();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa bình luận'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error deleting comment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Dropdown chọn phim
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String?>(
              value: _selectedMovieId,
              dropdownColor: const Color(0xff252429),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Lọc theo phim',
                labelStyle: const TextStyle(color: Colors.orangeAccent),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.orangeAccent),
                ),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text("Tất cả phim")),
                ..._movies.map((movie) => DropdownMenuItem(
                      value: movie.id,
                      child: Text(movie.title, overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (value) {
                _selectedMovieId = value;
                _applyFilter();
              },
            ),
          ),
          // Danh sách bình luận
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                : _filteredComments.isEmpty
                    ? const Center(child: Text("Không có bình luận nào", style: TextStyle(color: Colors.white70)))
                    : ListView.builder(
                        itemCount: _filteredComments.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final comment = _filteredComments[index];
                          
                          return Card(
                            color: Colors.white.withOpacity(0.05),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.orange.withOpacity(0.2)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(comment.userName, 
                                  style: const TextStyle(
                                    color: Colors.orangeAccent, 
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  )),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(comment.content, 
                                      style: const TextStyle(color: Colors.white, fontSize: 15)),
                                  const SizedBox(height: 8),
                                  Text(_formatDateTime(comment.createdAt), 
                                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () {
                                  _showDeleteConfirmation(comment.id);
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff252429),
        title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
        content: const Text('Bạn có chắc chắn muốn xóa bình luận này?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteComment(commentId);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }
}
