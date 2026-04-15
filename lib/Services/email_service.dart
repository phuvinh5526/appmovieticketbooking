import 'dart:io';
import 'dart:typed_data';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import '../Model/Ticket.dart';
import '../Model/Cinema.dart';
import '../Model/Room.dart';

class EmailService {
  // Tạo ảnh QR và lưu vào file tạm thời
  Future<File> _generateQRCodeImage(String ticketId) async {
    final qrPainter = QrPainter(
      data: ticketId,
      version: QrVersions.auto,
      gapless: false,
      color: Colors.orange,
    );

    final tempDir = await getTemporaryDirectory();
    final qrFile = File('${tempDir.path}/qrcode.png');
    final picData = await qrPainter.toImageData(160);
    await qrFile.writeAsBytes(Uint8List.view(picData!.buffer));

    return qrFile;
  }

  Future<void> sendTicketEmail({
    required String recipientEmail,
    required String recipientName,
    required String movieTitle,
    required Ticket ticket,
    required Cinema cinema,
    required Room room,
  }) async {
    try {
      // Tạo file ảnh QR
      final qrFile = await _generateQRCodeImage(ticket.id);

      // Cấu hình SMTP Gmail
      final smtpServer = SmtpServer(
        'smtp.gmail.com',
        port: 587,
        username: 'hanhphucli63@gmail.com',
        password: 'rnpx zxlu accx aegk',
        ssl: false,
        allowInsecure: true,
        ignoreBadCertificate: true,
      );

      // Nội dung email
      final message = Message()
        ..from = Address('quiv37777@gmail.com', 'Movie Ticket Booking')
        ..recipients.add(recipientEmail)
        ..subject = 'Thông tin vé xem phim - $movieTitle'
        ..html = '''
          <html>
            <body style="font-family: Arial, sans-serif; color: #333;">
              <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                <h2 style="color: #ff6b00;">Thông tin vé xem phim</h2>
                <p>Xin chào $recipientName,</p>
                <p>Cảm ơn bạn đã đặt vé xem phim tại hệ thống của chúng tôi.</p>
                
                <div style="background-color: #f5f5f5; padding: 20px; border-radius: 10px; margin: 20px 0;">
                  <h3 style="color: #ff6b00; margin-top: 0;">$movieTitle</h3>
                  <p><strong>Rạp:</strong> ${cinema.name}</p>
                  <p><strong>Địa chỉ:</strong> ${cinema.address}</p>
                  <p><strong>Phòng chiếu:</strong> ${room.name}</p>
                  <p><strong>Suất chiếu:</strong> ${ticket.showtime.formattedDate} - ${ticket.showtime.formattedTime}</p>
                  <p><strong>Ghế:</strong> ${ticket.selectedSeats.join(", ")}</p>
                  <p><strong>Mã vé:</strong> ${ticket.id}</p>
                  <p><strong>Tổng tiền:</strong> ${ticket.totalPrice.toStringAsFixed(0)}đ</p>
                </div>

                <div style="text-align: center; margin: 20px 0;">
                  <h3 style="color: #ff6b00;">Mã QR của vé</h3>
                  <img src="cid:qrcode" width="160" height="160" style="margin: 10px auto; display: block; ">
                  <p style="color: #666; font-size: 14px;">Quét mã QR này tại rạp để nhận vé</p>
                </div>

                <p>Vui lòng mang mã vé này đến rạp để nhận vé. Chúc bạn xem phim vui vẻ!</p>
                
                <div style="margin-top: 30px; text-align: center;">
                  <p style="color: #666; font-size: 14px;">Đây là email tự động, vui lòng không trả lời.</p>
                </div>
              </div>
            </body>
          </html>
        '''
        ..attachments.add(FileAttachment(qrFile)
          ..cid = 'qrcode'); // **Đính kèm QR và sửa lại cid**

      // Gửi email
      await send(message, smtpServer);
      print('Email sent successfully!');
    } catch (e) {
      print('Error sending email: $e');
    }
  }

  static Future<void> sendEmail({
    required String to,
    required String subject,
    required String body,
  }) async {
    final smtpServer = SmtpServer(
      'smtp.gmail.com',
      username: 'hanhphucli63@gmail.com',
      password: 'rnpx zxlu accx aegk',
      port: 587,
      ssl: false,
      allowInsecure: true,
    );

    final message = Message()
      ..from = const Address('quiv37777@gmail.com', 'Movie Ticket Booking')
      ..recipients.add(to)
      ..subject = subject
      ..text = body;

    try {
      await send(message, smtpServer);
    } catch (e) {
      throw Exception('Failed to send email: $e');
    }
  }
}
