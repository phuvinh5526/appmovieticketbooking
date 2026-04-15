import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:string_similarity/string_similarity.dart';
import 'dart:convert';
import 'movie_service.dart';
import 'ai_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MovieService _movieService = MovieService();
  final AIService _aiService = AIService();

  final Map<String, String> _autoResponses = {
    'phim nào đang chiếu':
        'Để xem danh sách phim đang chiếu hôm nay, tôi sẽ kiểm tra lịch chiếu mới nhất cho bạn.\n\n'
            'Bạn có thể:\n'
            '• Xem chi tiết từng phim\n'
            '• Đọc mô tả và đánh giá\n'
            '• Xem trailer\n'
            '• Chọn suất chiếu phù hợp\n\n'
            'Hãy bấm nút "Xem lịch chiếu" bên dưới để xem danh sách đầy đủ.',
    'lịch chiếu':
        'Tôi sẽ hiển thị lịch chiếu phim mới nhất cho bạn, bao gồm:\n\n'
            '• Các suất chiếu trong ngày\n'
            '• Thời gian chiếu cụ thể\n'
            '• Phòng chiếu và loại ghế\n'
            '• Giá vé cho từng suất\n\n'
            'Bấm "Xem lịch chiếu" để xem chi tiết.',
    'kiểm tra vé': 'Để xem thông tin vé đã đặt, tôi sẽ kiểm tra cho bạn:\n\n'
        '• Vé đang có hiệu lực\n'
        '• Thông tin suất chiếu\n'
        '• Số ghế đã chọn\n'
        '• Mã QR để quét tại rạp\n\n'
        'Bấm "Xem vé của tôi" để kiểm tra chi tiết.',
    'hướng dẫn đặt vé': 'Quy trình đặt vé online rất đơn giản:\n\n'
        '1. Chọn phim muốn xem\n'
        '2. Chọn ngày và suất chiếu\n'
        '3. Chọn ghế (có thể chọn nhiều ghế)\n'
        '4. Thêm bắp nước (tùy chọn)\n'
        '5. Kiểm tra thông tin và thanh toán\n'
        '6. Nhận mã vé qua email\n\n'
        'Bạn có thể bấm "Xem lịch chiếu" để bắt đầu đặt vé.',
    'giá vé': 'Giá vé phim được phân loại như sau:\n\n'
        '• Ghế thường: 50.000đ - 80.000đ\n'
        '• Ghế VIP: 100.000đ - 120.000đ\n'
        '• Ghế đôi: 150.000đ\n\n'
        'Giá có thể thay đổi tùy suất chiếu và ngày trong tuần.\n'
        'Bạn có thể xem giá cụ thể khi chọn suất chiếu.',
    'suất chiếu': 'Các suất chiếu được tổ chức từ 10:00 - 22:00 hàng ngày.\n\n'
        'Để xem lịch chiếu chi tiết và đặt vé, vui lòng bấm "Xem lịch chiếu" bên dưới.',
    'thanh toán': 'Chúng tôi hỗ trợ các hình thức thanh toán:\n\n'
        '• Thẻ ATM nội địa\n'
        '• Thẻ tín dụng/ghi nợ quốc tế\n'
        '• Ví điện tử (MoMo, ZaloPay)\n'
        '• Chuyển khoản ngân hàng\n\n'
        'Thanh toán được bảo mật và xử lý ngay lập tức.',
    'hủy vé': 'Quy định hủy vé như sau:\n\n'
        '• Có thể hủy trước 24h so với giờ chiếu\n'
        '• Hoàn tiền 100% nếu hủy sớm\n'
        '• Phí hủy 10% nếu hủy trong 24h\n'
        '• Không hoàn tiền nếu hủy sau giờ chiếu\n\n'
        'Liên hệ hotline để được hỗ trợ hủy vé.',
    'xem phim':
        'Bạn có thể xem danh sách phim đang chiếu tại trang chủ của ứng dụng.',
    'rạp':
        'Chúng tôi có nhiều rạp chiếu phim tại các địa điểm khác nhau. Vui lòng chọn rạp gần nhất với bạn.',
    'khuyến mãi':
        'Thường xuyên có các chương trình khuyến mãi và ưu đãi đặc biệt. Vui lòng theo dõi thông báo.',
    'thành viên':
        'Đăng ký thành viên để nhận nhiều ưu đãi đặc biệt và tích điểm khi mua vé.',
    'hotline': 'Hotline hỗ trợ: 1900xxxx. Thời gian làm việc: 8:00 - 22:00.',
    'phim':
        'Bạn muốn xem thông tin về phim nào? Tôi có thể giúp bạn tìm hiểu về:\n\n'
            '• Phim đang chiếu\n'
            '• Thông tin chi tiết phim\n'
            '• Lịch chiếu\n'
            '• Giá vé',
    'vé': 'Bạn cần hỗ trợ gì về vé?\n\n'
        '• Đặt vé\n'
        '• Xem vé đã đặt\n'
        '• Giá vé',
  };

  // Xử lý tiếng Việt
  String _processVietnameseText(String text) {
    const vietnamese =
        'áàảãạâấầẩẫậăắằẳẵặéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđÁÀẢÃẠÂẤẦẨẪẬĂẮẰẲẴẶÉÈẺẼẸÊẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÚÙỦŨỤƯỨỪỬỮỰÝỲỶỸỴĐ';
    const english =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiioooooooooooooooooouuuuuuuuuuuyyyyydAAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';

    String processed = text;
    for (int i = 0; i < vietnamese.length; i++) {
      processed = processed.replaceAll(vietnamese[i], english[i]);
    }
    return processed;
  }

  String? _findAutoResponse(String message) {
    message = message.toLowerCase().trim();
    String searchText = _processVietnameseText(message);

    String? bestMatch;
    double bestScore = 0.0;

    _autoResponses.forEach((keyword, response) {
      final keywordSearch = _processVietnameseText(keyword.toLowerCase());
      final score =
          StringSimilarity.compareTwoStrings(searchText, keywordSearch);
      if (score > 0.5 && score > bestScore) {
        bestScore = score;
        bestMatch = response; // Giữ nguyên response gốc không xử lý
      }
    });

    return bestMatch;
  }

  Future<String> _getNowShowingMovies() async {
    try {
      final movies = await _movieService.getNowShowingMovies().first;
      if (movies.isEmpty) {
        return 'Hiện tại không có phim nào đang chiếu. Vui lòng quay lại sau.';
      }

      String response = 'Hôm nay có các phim sau đang chiếu:\n\n';
      for (var movie in movies) {
        response += '• ${movie.title}\n';
        response += '  Thời lượng: ${movie.duration}\n';
        response += '  Đạo diễn: ${movie.director}\n';
        response +=
            '  Thể loại: ${movie.genres.map((g) => g.name).join(", ")}\n\n';
      }
      response +=
          'Bạn có thể xem chi tiết và đặt vé cho bất kỳ phim nào trong danh sách trên.';
      return response;
    } catch (e) {
      print('Error getting movies: $e');
      return 'Xin lỗi, tôi không thể lấy thông tin phim lúc này. Vui lòng thử lại sau.';
    }
  }

  Future<void> sendMessage(String content) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final sessionId = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
      content = content.trim();

      // Lưu tin nhắn của người dùng
      await _firestore.collection('messages').add({
        'userId': user.uid,
        'userName': user.displayName ?? 'Người dùng',
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'sessionId': sessionId,
      });

      // Kiểm tra câu trả lời tự động
      String? autoResponse = _findAutoResponse(content);

      if (autoResponse != null) {
        // Xác định loại và hành động dựa trên từ khóa
        String type = 'info';
        String? action;

        String searchContent = _processVietnameseText(content.toLowerCase());
        if (searchContent.contains(_processVietnameseText('vé'))) {
          type = 'ticket';
          action = 'Xem vé của tôi';
        } else if (searchContent.contains(_processVietnameseText('phim')) ||
            searchContent.contains(_processVietnameseText('lịch chiếu')) ||
            searchContent.contains(_processVietnameseText('suất chiếu'))) {
          type = 'movie';
          action = 'Xem lịch chiếu';
        }

        // Lưu phản hồi tự động
        await _firestore.collection('messages').add({
          'userId': 'bot',
          'userName': 'Trợ lý ảo',
          'content': autoResponse,
          'type': type,
          'action': action,
          'timestamp': FieldValue.serverTimestamp(),
          'sessionId': sessionId,
        });
        return;
      }

      // Nếu không có câu trả lời tự động, gọi AI
      final response = await _aiService.getResponse(content);

      // Lưu phản hồi của AI
      await _firestore.collection('messages').add({
        'userId': 'bot',
        'userName': 'Trợ lý ảo',
        'content': response['content'],
        'type': response['type'],
        'action': response['action'],
        'timestamp': FieldValue.serverTimestamp(),
        'sessionId': sessionId,
      });
    } catch (e) {
      print('Lỗi khi gửi tin nhắn: $e');
    }
  }

  Future<void> clearMessages() async {
    try {
      final batch = _firestore.batch();
      final messages = await _firestore.collection('messages').get();

      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Đã xóa tất cả tin nhắn thành công');
    } catch (e) {
      print('Lỗi khi xóa tin nhắn: $e');
    }
  }

  Stream<QuerySnapshot> getMessages() {
    print('Đang lấy tin nhắn từ Firestore...');
    return _firestore
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      print('Đã nhận ${snapshot.docs.length} tin nhắn');
      return snapshot;
    });
  }
}
