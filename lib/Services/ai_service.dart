import 'dart:convert';
import 'package:http/http.dart' as http;
import 'movie_service.dart';
import 'showtime_service.dart';
import 'ticket_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AIService {
  // static const String apiKey =
  //     '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';
  static const String apiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
  static const String apiUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  final MovieService _movieService = MovieService();
  final ShowtimeService _showtimeService = ShowtimeService();
  final TicketService _ticketService = TicketService();

  // Thêm phương thức để lấy tên phim từ movieId
  String _getMovieTitle(String movieId, List<dynamic> movies) {
    try {
      final movie = movies.firstWhere((m) => m.id == movieId);
      return movie.title;
    } catch (e) {
      return movieId; // Trả về movieId nếu không tìm thấy phim
    }
  }

  // Thêm phương thức để lấy thông tin rạp từ showtime
  Future<String> _getTheaterInfo(dynamic showtime) async {
    try {
      // Lấy thông tin phòng từ Firebase
      final room = await showtime.getRoom();
      if (room == null) {
        return 'Rạp chiếu';
      }

      // Lấy thông tin rạp từ Firebase
      final cinemaDoc = await FirebaseFirestore.instance
          .collection('cinemas')
          .doc(showtime.cinemaId)
          .get();

      if (!cinemaDoc.exists) {
        return '${room.name}';
      }

      final cinemaData = cinemaDoc.data() as Map<String, dynamic>;
      final cinemaName = cinemaData['name'] ?? 'Rạp chiếu';

      return '$cinemaName -' + 'phòng' + ' ${room.name}';
    } catch (e) {
      print('Lỗi khi lấy thông tin rạp: $e');
      return 'Rạp chiếu';
    }
  }

  Future<Map<String, dynamic>> getResponse(String prompt) async {
    try {
      print('Đang lấy dữ liệu từ các dịch vụ...');

      // Lấy dữ liệu từ các service
      final movies = await _movieService.getMovies().first;
      final allShowtimes = await _showtimeService.getAllShowtimes().first;

      // Lọc suất chiếu từ ngày hiện tại
      final now = DateTime.now();
      final currentDate =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

      final currentShowtimes = allShowtimes.where((showtime) {
        final parts = showtime.formattedDate.split('/');
        if (parts.length != 3) return false;

        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final showtimeDate = DateTime(year, month, day);

        return showtimeDate.isAfter(now) ||
            (showtimeDate.year == now.year &&
                showtimeDate.month == now.month &&
                showtimeDate.day == now.day);
      }).toList();

      // Kiểm tra nếu câu hỏi liên quan đến phim cụ thể
      String promptLower = prompt.toLowerCase();
      String? specificMovie;
      for (var movie in movies) {
        if (promptLower.contains(movie.title.toLowerCase())) {
          specificMovie = movie.title;
          break;
        }
      }

      String context;
      String enhancedPrompt;

      if (specificMovie != null) {
        // Nếu hỏi về một phim cụ thể
        final movie = movies.firstWhere(
            (m) => m.title.toLowerCase() == specificMovie!.toLowerCase());
        final movieShowtimes =
            currentShowtimes.where((s) => s.movieId == movie.id).toList();

        // Lấy thông tin rạp cho từng suất chiếu
        final showtimeInfo = await Future.wait(movieShowtimes.map((s) async {
          final theaterInfo = await _getTheaterInfo(s);
          return '• ${s.formattedDate} lúc ${s.formattedTime} tại $theaterInfo';
        }));

        context = '''
        Thông tin chi tiết phim "${movie.title}":
        • Thời lượng: ${movie.duration}
        • Đạo diễn: ${movie.director}
        • Thể loại: ${movie.genres.map((g) => g.name).join(", ")}
        • Mô tả: ${movie.description}
        
        Lịch chiếu từ $currentDate:
        ${showtimeInfo.join('\n')}
        ''';

        enhancedPrompt = '''
        Context: $context
        
        Câu hỏi của người dùng: $prompt
        
        Hãy trả lời bằng tiếng Việt thân thiện như một nhân viên rạp chiếu phim. Trả lời chi tiết về phim "${movie.title}" dựa trên thông tin trong context.
        
        Nếu có hỏi về lịch chiếu:
        - Chỉ trả về các suất chiếu ngày $currentDate
        - Nói rõ ngày giờ chiếu
        - Gợi ý người dùng đặt vé nếu có suất chiếu phù hợp
        
        Nếu không có thông tin cần thiết, hãy xin lỗi và đề xuất các thông tin liên quan khác.
        
        Luôn kết thúc bằng một câu mời người dùng đặt vé hoặc hỏi thêm thông tin nếu cần.
        ''';
      } else if (promptLower.contains('phim') ||
          promptLower.contains('chieu') ||
          promptLower.contains('suat')) {
        // Nếu hỏi về danh sách phim
        // Lấy thông tin rạp cho từng suất chiếu
        final showtimeInfo = await Future.wait(currentShowtimes.map((s) async {
          final theaterInfo = await _getTheaterInfo(s);
          return '• ${_getMovieTitle(s.movieId, movies)} vào ${s.formattedDate} lúc ${s.formattedTime} tại $theaterInfo';
        }));

        context = '''
        Danh sách phim đang chiếu:
        ${movies.map((m) => '''
        • ${m.title}
          - Thời lượng: ${m.duration}
          - Đạo diễn: ${m.director}
          - Thể loại: ${m.genres.map((g) => g.name).join(", ")}
          - Mô tả ngắn: ${m.description}
        ''').join('\n')}

        Lịch chiếu  $currentDate:
        ${showtimeInfo.join('\n')}
        ''';

        enhancedPrompt = '''
        Context: $context
        
        Câu hỏi của người dùng: $prompt
        
        Hãy trả lời bằng tiếng Việt thân thiện như một nhân viên rạp chiếu phim. Trả lời về danh sách phim đang chiếu dựa trên thông tin trong context.
        
        Khi liệt kê phim:
        - Nhóm các phim theo thể loại nếu có thể
        - Nhấn mạnh các phim mới và đang hot
        - Giới thiệu ngắn gọn về nội dung chính
        
        Khi đề cập lịch chiếu:
        - Chỉ đề cập suất chiếu ngày $currentDate
        - Sắp xếp theo giờ chiếu để dễ theo dõi
        
        Kết thúc bằng cách mời người dùng:
        - Hỏi thêm về phim họ quan tâm
        - Gợi ý đặt vé cho suất chiếu phù hợp
        ''';
      } else {
        // Các câu hỏi khác
        // Lấy thông tin rạp cho từng suất chiếu
        final showtimeInfo = await Future.wait(currentShowtimes.map((s) async {
          final theaterInfo = await _getTheaterInfo(s);
          return '• ${_getMovieTitle(s.movieId, movies)} vào ${s.formattedDate} lúc ${s.formattedTime} tại $theaterInfo';
        }));

        context = '''
        Dữ liệu phim hiện có:
        ${movies.map((m) => '• ${m.title} (${m.genres.map((g) => g.name).join(", ")}): ${m.description}').join('\n')}

        Lịch chiếu  $currentDate:
        ${showtimeInfo.join('\n')}
        ''';

        enhancedPrompt = '''
        Context: $context
        
        Câu hỏi của người dùng: $prompt
        
        Hãy trả lời bằng tiếng Việt thân thiện như một nhân viên rạp chiếu phim. Trả lời dựa trên thông tin trong context.
        
        Nguyên tắc trả lời:
        - Sử dụng ngôn ngữ thân thiện, gần gũi
        - Ưu tiên thông tin mới nhất và phù hợp nhất
        - Chỉ đề cập suất chiếu  ngày $currentDate
        - Nếu không có thông tin, gợi ý các chủ đề liên quan
        
        Kết thúc trả lời bằng:
        - Hỏi xem người dùng cần hỗ trợ gì thêm
        - Gợi ý về phim hoặc suất chiếu phù hợp
        - Mời đặt vé nếu họ đã tìm được phim ưng ý
        ''';
      }

      print('Đã tạo context: $context');
      print('Đang gửi prompt đến AI: $enhancedPrompt');

      // Gửi request đến API
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama3-70b-8192',
          'messages': [
            {
              'role': 'user',
              'content': enhancedPrompt,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];

        // Xác định loại câu hỏi và trả về kết quả phù hợp
        if (promptLower.contains('vé') ||
            promptLower.contains('đặt') ||
            promptLower.contains('mua')) {
          return {
            'type': 'ticket',
            'content': content,
            'action': 'Xem vé của tôi',
          };
        } else if (promptLower.contains('suất chiếu') ||
            promptLower.contains('lịch chiếu')) {
          return {
            'type': 'showtime',
            'content': content,
            'action': 'Xem lịch chiếu',
          };
        } else {
          return {
            'type': 'movie',
            'content': content,
            'action': specificMovie != null ? null : 'Xem lịch chiếu',
          };
        }
      } else {
        throw Exception('Không thể nhận phản hồi AI: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi trong getResponse: $e');
      return {
        'type': 'error',
        'content':
            'Xin lỗi, có lỗi xảy ra khi xử lý yêu cầu của bạn. Vui lòng thử lại sau.',
        'action': null,
      };
    }
  }

  Future<Map<String, dynamic>> getTicketInfoByUserId(
      String userId, String prompt) async {
    try {
      print('Đang lấy thông tin vé cho người dùng: $userId');

      // Lấy dữ liệu từ các service
      final movies = await _movieService.getMovies().first;
      final allShowtimes = await _showtimeService.getAllShowtimes().first;
      final allUserTickets =
          await _ticketService.getTicketsByUserId(userId).first;

      // Lọc vé từ ngày hiện tại
      final now = DateTime.now();
      final currentDate =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

      final currentUserTickets = allUserTickets.where((ticket) {
        // Parse ngày từ formattedDate (format: dd/MM/yyyy)
        final parts = ticket.showtime.formattedDate.split('/');
        if (parts.length != 3) return false;

        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final ticketDate = DateTime(year, month, day);

        return ticketDate.isAfter(now) ||
            (ticketDate.year == now.year &&
                ticketDate.month == now.month &&
                ticketDate.day == now.day);
      }).toList();

      print('Dữ liệu phim: ${movies.length} phim');
      print(
          'Dữ liệu vé hiện tại của người dùng: ${currentUserTickets.length} vé');

      // Lấy thông tin rạp cho từng vé
      final ticketInfo = await Future.wait(currentUserTickets.map((t) async {
        final theaterInfo = await _getTheaterInfo(t.showtime);
        return '''
      - Phim: ${_getMovieTitle(t.showtime.movieId, movies)}
      - Ngày chiếu: ${t.showtime.formattedDate}
      - Giờ chiếu: ${t.showtime.formattedTime}
      - Rạp chiếu: $theaterInfo
      - Số ghế: ${t.selectedSeats.join(", ")}
      - Tổng tiền: ${t.totalPrice}đ
      ''';
      }));

      // Tạo context từ dữ liệu
      final context = '''
      Thông tin vé của người dùng từ $currentDate:
      ${ticketInfo.join('\n')}

      Danh sách phim hiện có:
      ${movies.map((m) => '- ${m.title} (${m.genres.map((g) => g.name).join(", ")}): ${m.description}').join('\n')}
      ''';

      print('Đã tạo context: $context');

      // Tạo prompt mới với context
      final enhancedPrompt = '''
      Context: $context
      
      Câu hỏi của người dùng: $prompt
      
      Hãy trả lời bằng tiếng Việt thân thiện như một nhân viên rạp chiếu phim. Trả lời dựa trên thông tin vé của người dùng trong context.
      
      Khi trả lời về vé:
      - Sắp xếp vé theo thứ tự thời gian
      - Nhấn mạnh các vé sắp đến ngày chiếu
      - Nhắc nhở thời gian còn lại nếu sắp đến giờ chiếu
      - Thông báo rõ về trạng thái vé (còn hiệu lực/hết hạn)
      
      Chỉ trả về thông tin vé từ ngày $currentDate.
      
      Kết thúc trả lời bằng:
      - Nhắc nhở đến sớm trước giờ chiếu 15-30 phút
      - Gợi ý mang theo mã QR để quét vé
      - Hỏi xem người dùng cần hỗ trợ gì thêm
      ''';

      print('Đang gửi prompt đến AI: $enhancedPrompt');

      // Gửi request đến API
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama3-70b-8192',
          'messages': [
            {
              'role': 'user',
              'content': enhancedPrompt,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'type': 'ticket',
          'content': data['choices'][0]['message']['content'],
          'action': 'Xem vé của tôi',
        };
      } else {
        throw Exception(
            'Không thể nhận phản hồi từ AI: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi trong getTicketInfoByUserId: $e');
      return {
        'type': 'error',
        'content':
            'Xin lỗi, có lỗi xảy ra khi xử lý yêu cầu của bạn. Vui lòng thử lại sau.',
        'action': null,
      };
    }
  }
}
