const functions = require("firebase-functions");
const nodemailer = require("nodemailer");

// Cấu hình email
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "movieticketbooking@gmail.com", // Thay thế bằng email của bạn
    pass: "your-app-password", // Thay thế bằng app password của bạn
  },
});

exports.sendTicketEmail = functions.https.onCall(async (data, context) => {
  try {
    const {
      recipientEmail,
      recipientName,
      movieTitle,
      cinemaName,
      cinemaAddress,
      roomName,
      showtime,
      seats,
      ticketId,
      totalPrice,
    } = data;

    const mailOptions = {
      from: "movieticketbooking@gmail.com",
      to: recipientEmail,
      subject: `Thông tin vé xem phim - ${movieTitle}`,
      html: `
        <html>
          <body style="font-family: Arial, sans-serif; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
              <h2 style="color: #ff6b00;">Thông tin vé xem phim</h2>
              <p>Xin chào ${recipientName},</p>
              <p>Cảm ơn bạn đã đặt vé xem phim tại hệ thống của chúng tôi.</p>
              
              <div style="background-color: #f5f5f5; padding: 20px; border-radius: 10px; margin: 20px 0;">
                <h3 style="color: #ff6b00; margin-top: 0;">${movieTitle}</h3>
                <p><strong>Rạp:</strong> ${cinemaName}</p>
                <p><strong>Địa chỉ:</strong> ${cinemaAddress}</p>
                <p><strong>Phòng chiếu:</strong> ${roomName}</p>
                <p><strong>Suất chiếu:</strong> ${showtime}</p>
                <p><strong>Ghế:</strong> ${seats}</p>
                <p><strong>Mã vé:</strong> ${ticketId}</p>
                <p><strong>Tổng tiền:</strong> ${totalPrice}đ</p>
              </div>

              <p>Vui lòng mang mã vé này đến rạp để nhận vé. Chúc bạn xem phim vui vẻ!</p>
              
              <div style="margin-top: 30px; text-align: center;">
                <p style="color: #666; font-size: 14px;">Đây là email tự động, vui lòng không trả lời.</p>
              </div>
            </div>
          </body>
        </html>
      `,
    };

    await transporter.sendMail(mailOptions);
    return { success: true };
  } catch (error) {
    console.error("Error sending email:", error);
    throw new functions.https.HttpsError("internal", "Error sending email");
  }
});
