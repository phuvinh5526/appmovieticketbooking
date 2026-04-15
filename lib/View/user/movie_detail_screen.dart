import 'package:flutter/material.dart';
import 'package:movieticketbooking/View/user/showtime_picker_screen.dart';
import '../../Model/Movie.dart';
import '../../Model/Comment.dart';
import '../../Model/User.dart' as app_user;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../Services/comment_service.dart';
import '../../Services/ticket_service.dart';
import 'trailer_screen.dart';
import '../../Components/custom_image_widget.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({
    required this.movie,
    Key? key,
  }) : super(key: key);

  @override
  _MovieDetailScreenState createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _commentController = TextEditingController();
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final CommentService _commentService = CommentService();
  final TicketService _ticketService = TicketService();
  List<Comment> _comments = [];
  bool _isLoading = false;
  double _averageRating = 10.0;
  double _selectedRating = 5.0;
  late Movie _currentMovie;
  bool _canComment = false;
  String _commentMessage = '';
  String _currentTicketId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentMovie = widget.movie;
    _loadComments();
    _checkCommentEligibility();

    // Add listener for tab changes
    _tabController.addListener(() {
      setState(() {}); // Rebuild UI when tab changes
    });
  }

  Future<void> _checkCommentEligibility() async {
    if (_auth.currentUser == null) {
      setState(() {
        _canComment = false;
        _commentMessage = 'Vui lòng đăng nhập để bình luận';
      });
      return;
    }

    try {
      // Kiểm tra xem người dùng đã comment cho phim này chưa
      final commentSnapshot = await FirebaseFirestore.instance
          .collection('comments')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .where('movieId', isEqualTo: _currentMovie.id)
          .get();

      if (commentSnapshot.docs.isNotEmpty) {
        setState(() {
          _canComment = false;
          _commentMessage = 'Bạn đã bình luận cho phim này';
        });
        return;
      }

      // Nếu chưa comment, kiểm tra xem có vé nào đã qua thời gian chiếu không
      final tickets =
          await _ticketService.getTicketsByUserId(_auth.currentUser!.uid).first;

      final now = DateTime.now();
      bool hasEligibleTicket = false;
      String ticketId = '';

      for (var ticket in tickets) {
        if (ticket.showtime.movieId == _currentMovie.id) {
          final showDateTime = DateTime(
            ticket.showtime.startTime.year,
            ticket.showtime.startTime.month,
            ticket.showtime.startTime.day,
            ticket.showtime.startTime.hour,
            ticket.showtime.startTime.minute,
          );

          // Nếu thời gian hiện tại đã qua thời gian chiếu
          if (now.isAfter(showDateTime)) {
            hasEligibleTicket = true;
            ticketId = ticket.id;
            break;
          }
        }
      }

      setState(() {
        _canComment = hasEligibleTicket;
        _commentMessage = hasEligibleTicket
            ? 'Bạn có thể bình luận phim này'
            : 'Bạn chưa thể bình luận phim này';
        if (hasEligibleTicket) {
          _currentTicketId = ticketId;
        }
      });
    } catch (e) {
      print('Error checking comment eligibility: $e');
      setState(() {
        _canComment = false;
        _commentMessage = 'Có lỗi xảy ra khi kiểm tra điều kiện bình luận';
      });
    }
  }

  Future<void> _loadComments() async {
    print('Loading comments for movie: ${_currentMovie.id}'); // Debug log
    setState(() {
      _isLoading = true;
    });

    try {
      _commentService.getCommentsByMovie(_currentMovie.id).listen(
        (comments) {
          print('Received ${comments.length} comments'); // Debug log
          if (mounted) {
            setState(() {
              _comments = comments;
              if (_comments.isNotEmpty) {
                _averageRating =
                    _comments.map((c) => c.rating).reduce((a, b) => a + b) /
                        _comments.length;
                print('Average rating: $_averageRating'); // Debug log
                print(
                    'First comment content: ${_comments.first.content}'); // Debug log
              } else {
                _averageRating = 10.0;
                print('No comments found'); // Debug log
              }
              _isLoading = false;
            });
          }
        },
        onError: (error) {
          print('Error in comment stream: $error'); // Debug log
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Không thể tải bình luận: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e) {
      print('Error setting up comment stream: $e'); // Debug log
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải bình luận: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateMovieRating() async {
    try {
      final comments =
          await _commentService.getCommentsByMovie(_currentMovie.id).first;
      if (comments.isNotEmpty) {
        final averageRating =
            comments.map((c) => c.rating).reduce((a, b) => a + b) /
                comments.length;
        await FirebaseFirestore.instance
            .collection('movies')
            .doc(_currentMovie.id)
            .update({
          'rating': averageRating,
          'reviewCount': comments.length,
        });
      } else {
        await FirebaseFirestore.instance
            .collection('movies')
            .doc(_currentMovie.id)
            .update({
          'rating': 0.0,
          'reviewCount': 0,
        });
      }

      // Reload movie data from Firestore
      final movieDoc = await FirebaseFirestore.instance
          .collection('movies')
          .doc(_currentMovie.id)
          .get();

      if (movieDoc.exists) {
        setState(() {
          _currentMovie = Movie.fromJson(movieDoc.data()!);
        });
      }
    } catch (e) {
      print('Error updating movie rating: $e');
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập nội dung bình luận'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_canComment) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_commentMessage),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final comment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _auth.currentUser!.uid,
        movieId: _currentMovie.id,
        content: _commentController.text.trim(),
        createdAt: DateTime.now(),
        rating: _selectedRating,
        userName: _auth.currentUser!.displayName ?? 'Người dùng',
        ticketId: _currentTicketId,
      );

      await _commentService.createComment(comment);
      _commentController.clear();
      setState(() {
        _selectedRating = 5.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bình luận thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error submitting comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi xảy ra khi gửi bình luận'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(() {}); // Remove listener when disposing
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xff252429),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background Image with Gradient
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.7),
                  ],
                ).createShader(bounds);
              },
              blendMode: BlendMode.darken,
              child: CustomImageWidget(
                imagePath: _currentMovie.imagePath,
                isBackground: true,
              ),
            ),
          ),

          // Main Content
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 100),
                // Movie Poster and Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Movie Poster
                      Container(
                        width: 190,
                        height: 280,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CustomImageWidget(
                            imagePath: _currentMovie.imagePath,
                            width: 190,
                            height: 280,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Movie Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentMovie.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 16),
                            buildInfoBox("⏳ ${_currentMovie.duration}"),
                            buildInfoBox("📅 ${_currentMovie.releaseDate}"),
                            buildInfoBox(
                                "⭐ ${_averageRating.toStringAsFixed(1)}/10"),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TrailerScreen(
                                      trailerUrl: _currentMovie.trailerUrl,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "▶ Xem Trailer",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.orange,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(fontSize: 16),
                    tabs: const [
                      Tab(text: "Giới thiệu"),
                      Tab(text: "Đánh giá"),
                    ],
                  ),
                ),
                // Tab Content
                Container(
                  height: MediaQuery.of(context).size.height - 300,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      buildIntroductionTab(),
                      buildReviewsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottom Button
          if (_tabController.index == 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ShowtimePickerScreen(movie: _currentMovie),
                    ),
                  );
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange,
                        Colors.orange.shade700,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "Đặt Vé",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildInfoBox(String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: Colors.orange.withOpacity(0.9),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget buildIntroductionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildDetailRow("Thể loại:",
              _currentMovie.genres.map((genre) => genre.name).join(", ")),
          buildDetailRow("Đạo diễn:", _currentMovie.director),
          buildDetailRow("Diễn viên:", _currentMovie.cast.join(", ")),
          const SizedBox(height: 16),
          const Text(
            "Tóm tắt",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentMovie.description,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            TextSpan(
              text: " $value",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildReviewsTab() {
    return Column(
      children: [
        // Rating Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Rating Number with Star Icon
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_averageRating.toStringAsFixed(1)}/10',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Review Count
              Text(
                '${_comments.length} đánh giá',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        // Comments List
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.orange))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    return FutureBuilder<app_user.User?>(
                      future: _commentService.getUserForComment(comment.userId),
                      builder: (context, userSnapshot) {
                        final userName =
                            userSnapshot.data?.fullName ?? 'Người dùng';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(10, (index) {
                                      return Icon(
                                        index < comment.rating
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.orange,
                                        size: 14,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                comment.content,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatTimestamp(comment.createdAt),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
        // Comment Input - Only show if user can comment
        if (_canComment)
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Rating Stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(10, (index) {
                    return Expanded(
                      child: IconButton(
                        icon: Icon(
                          index < _selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.orange,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedRating = index + 1;
                          });
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                // Comment Input
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(
                            hintText: "Viết bình luận...",
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _submitComment,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Hôm qua';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ngày trước';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks tuần trước';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months tháng trước';
      } else {
        return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year}';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}
