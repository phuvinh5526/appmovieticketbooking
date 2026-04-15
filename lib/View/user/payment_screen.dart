import 'package:flutter/material.dart';
import '../../Model/Food.dart';
import '../../Model/Showtime.dart';
import '../../Model/Room.dart';
import '../../Model/Cinema.dart';
import '../../Services/room_service.dart';
import '../../Services/cinema_service.dart';
import '../../Services/food_service.dart';
import 'payment_success_screen.dart';
import 'package:provider/provider.dart';
import '../../Providers/user_provider.dart';
import '../../Components/custom_image_widget.dart';

class PaymentScreen extends StatefulWidget {
  final String movieTitle;
  final String moviePoster;
  final Showtime showtime;
  final List<String> selectedSeats;
  final double totalPrice;
  final Map<String, int> selectedFoods;

  const PaymentScreen({
    Key? key,
    required this.movieTitle,
    required this.moviePoster,
    required this.showtime,
    required this.selectedSeats,
    required this.totalPrice,
    required this.selectedFoods,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  String selectedPaymentMethod = "MoMo";
  bool isAgreed = false;
  bool isLoading = false;
  String paymentStatus = "";
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  String? cardNumberError;
  String? expiryError;
  String? cvvError;

  Room? selectedRoom;
  Cinema? selectedCinema;
  List<Food> foodItems = [];

  final RoomService _roomService = RoomService();
  final CinemaService _cinemaService = CinemaService();
  final FoodService _foodService = FoodService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    cardNumberController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    super.dispose();
  }

  bool _validateCardInfo() {
    bool isValid = true;

    // Validate card number (16 digits)
    if (cardNumberController.text.isEmpty ||
        !RegExp(r'^\d{16}$').hasMatch(cardNumberController.text)) {
      setState(() => cardNumberError = "Số thẻ không hợp lệ");
      isValid = false;
    }

    // Validate expiry date (MM/YY format)
    if (expiryController.text.isEmpty ||
        !RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$')
            .hasMatch(expiryController.text)) {
      setState(() => expiryError = "Ngày hết hạn không hợp lệ");
      isValid = false;
    }

    // Validate CVV (3-4 digits)
    if (cvvController.text.isEmpty ||
        !RegExp(r'^\d{3,4}$').hasMatch(cvvController.text)) {
      setState(() => cvvError = "CVV không hợp lệ");
      isValid = false;
    }

    return isValid;
  }

  Future<void> _simulatePayment() async {
    setState(() {
      isLoading = true;
      paymentStatus = "Đang xử lý thanh toán...";
    });

    // Giả lập kiểm tra số dư
    await Future.delayed(Duration(seconds: 1));
    setState(() => paymentStatus = "Đang kiểm tra số dư...");

    // Giả lập xác thực thông tin
    await Future.delayed(Duration(seconds: 1));
    setState(() => paymentStatus = "Đang xác thực thông tin...");

    // Giả lập xử lý giao dịch
    await Future.delayed(Duration(seconds: 1));
    setState(() => paymentStatus = "Đang xử lý giao dịch...");

    // Giả lập hoàn tất
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      isLoading = false;
      paymentStatus = "Thanh toán thành công!";
    });
  }

  void confirmPayment() async {
    if (!isAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Bạn cần đồng ý với điều khoản trước khi thanh toán!"),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (selectedPaymentMethod == "Thẻ ngân hàng" && !_validateCardInfo()) {
      return;
    }

    // Hiển thị dialog xác nhận với animation
    bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.payment, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text(
              "Xác nhận thanh toán",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orangeAccent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Thông tin giao dịch",
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Số tiền: ${widget.totalPrice.toStringAsFixed(0)}đ",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (selectedPaymentMethod == "Thẻ ngân hàng") ...[
                    SizedBox(height: 8),
                    Text(
                      "Phương thức: Thẻ ngân hàng",
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      "Số thẻ: ${cardNumberController.text.substring(0, 4)} **** **** ${cardNumberController.text.substring(12)}",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ] else ...[
                    SizedBox(height: 8),
                    Text(
                      "Phương thức: MoMo",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Bạn có chắc chắn muốn thanh toán?",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Hủy",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "Xác nhận",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Bắt đầu quá trình thanh toán với loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                  strokeWidth: 3,
                ),
                SizedBox(height: 16),
                Text(
                  paymentStatus,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Thực hiện quá trình thanh toán
    await _simulatePayment();

    // Đóng loading overlay
    Navigator.pop(context);

    // Chuyển đến màn hình thành công
    if (selectedRoom != null && selectedCinema != null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            userEmail: userProvider.currentUser!.email,
            userName: userProvider.currentUser!.fullName,
            movieTitle: widget.movieTitle,
            moviePoster: widget.moviePoster,
            showtime: widget.showtime,
            selectedSeats: widget.selectedSeats,
            totalPrice: widget.totalPrice,
            selectedFoods: widget.selectedFoods,
            userId: userProvider.currentUser!.id,
            roomName: selectedRoom!.name,
            cinemaName: selectedCinema!.name,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra khi chuyển đến màn hình thành công'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (selectedRoom == null || selectedCinema == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Thanh Toán',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            )),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTicketInfo(selectedCinema!, selectedRoom!),
              SizedBox(height: 20),
              if (widget.selectedFoods.isNotEmpty) _buildFoodInfo(),
              SizedBox(height: 20),
              _buildPaymentMethods(),
              SizedBox(height: 20),
              _buildTerms(),
              SizedBox(height: 20),
              _buildTotalAndPayButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketInfo(Cinema cinema, Room room) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.orangeAccent, width: 2),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomImageWidget(
                imagePath: widget.moviePoster,
                width: 130,
                height: 190,
                borderRadius: BorderRadius.circular(10),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.movieTitle,
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow(Icons.location_on, "Rạp", cinema.name),
                    _buildInfoRow(Icons.meeting_room, "Phòng", room.name),
                    _buildInfoRow(Icons.schedule, "Thời gian",
                        widget.showtime.formattedTime),
                    _buildInfoRow(Icons.calendar_month, "Ngày",
                        widget.showtime.formattedDate),
                    _buildInfoRow(Icons.event_seat, "Ghế",
                        widget.selectedSeats.join(", ")),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFoodInfo() {
    if (foodItems.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.orangeAccent, width: 2),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Bắp nước đã chọn",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          ...widget.selectedFoods.entries.map((entry) {
            Food? food = foodItems.firstWhere(
              (item) => item.id == entry.key,
              orElse: () => Food(
                id: entry.key,
                name: "Không xác định",
                price: 0,
                image:
                    "https://png.pngtree.com/png-clipart/20231023/original/pngtree-watercolor-popcorn-cinema-png-image_13398697.png",
                description: "",
              ),
            );
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  CustomImageWidget(
                    imagePath: food.image,
                    width: 60,
                    height: 60,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "${entry.value} x ${food.price.toStringAsFixed(0)}đ",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "${(entry.value * food.price).toStringAsFixed(0)}đ",
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.orangeAccent, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Tổng tiền bắp nước",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${widget.selectedFoods.entries.fold(0, (sum, entry) {
                    Food food = foodItems.firstWhere(
                      (item) => item.id == entry.key,
                      orElse: () => Food(
                        id: entry.key,
                        name: "Không xác định",
                        price: 0,
                        image: "assets/images/food/placeholder.png",
                        description: "",
                      ),
                    );
                    return sum + (entry.value * food.price).toInt();
                  }).toStringAsFixed(0)}đ",
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.orangeAccent, width: 2),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Chọn phương thức thanh toán",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildPaymentMethodOption(
            "MoMo",
            Icons.account_balance_wallet,
            "Thanh toán qua ví MoMo",
          ),
          SizedBox(height: 12),
          _buildPaymentMethodOption(
            "Thẻ ngân hàng",
            Icons.credit_card,
            "Thanh toán qua thẻ ngân hàng",
          ),
          if (selectedPaymentMethod == "Thẻ ngân hàng") ...[
            SizedBox(height: 16),
            _buildCardInputFields(),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption(
      String method, IconData icon, String description) {
    return GestureDetector(
      onTap: () => setState(() => selectedPaymentMethod = method),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selectedPaymentMethod == method
              ? Colors.orangeAccent.withOpacity(0.2)
              : Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedPaymentMethod == method
                ? Colors.orangeAccent
                : Colors.white30,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.orangeAccent, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Radio(
              value: method,
              groupValue: selectedPaymentMethod,
              onChanged: (value) =>
                  setState(() => selectedPaymentMethod = value.toString()),
              activeColor: Colors.orangeAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardInputFields() {
    return Column(
      children: [
        TextFormField(
          controller: cardNumberController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "Số thẻ",
            labelStyle: TextStyle(color: Colors.white70),
            prefixIcon: Icon(Icons.credit_card, color: Colors.orangeAccent),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.orangeAccent),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.orangeAccent.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.orangeAccent),
            ),
            errorText: cardNumberError,
            errorStyle: TextStyle(color: Colors.red),
          ),
          onChanged: (value) => setState(() => cardNumberError = null),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: expiryController,
                keyboardType: TextInputType.datetime,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Ngày hết hạn (MM/YY)",
                  labelStyle: TextStyle(color: Colors.white70),
                  prefixIcon:
                      Icon(Icons.date_range, color: Colors.orangeAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.orangeAccent),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.orangeAccent.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.orangeAccent),
                  ),
                  errorText: expiryError,
                  errorStyle: TextStyle(color: Colors.red),
                ),
                onChanged: (value) => setState(() => expiryError = null),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: cvvController,
                keyboardType: TextInputType.number,
                obscureText: true,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "CVV",
                  labelStyle: TextStyle(color: Colors.white70),
                  prefixIcon: Icon(Icons.lock, color: Colors.orangeAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.orangeAccent),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.orangeAccent.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.orangeAccent),
                  ),
                  errorText: cvvError,
                  errorStyle: TextStyle(color: Colors.red),
                ),
                onChanged: (value) => setState(() => cvvError = null),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTerms() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.orangeAccent, width: 2),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: isAgreed,
            onChanged: (value) => setState(() => isAgreed = value!),
            activeColor: Colors.orangeAccent,
          ),
          Expanded(
            child: Text(
              "Tôi đồng ý với điều khoản và điều kiện của dịch vụ",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAndPayButton() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.orangeAccent, width: 2),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tổng tiền",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              Text(
                "${widget.totalPrice.toStringAsFixed(0)}đ",
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (paymentStatus.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                paymentStatus,
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : confirmPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: isAgreed ? Colors.orangeAccent : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 5,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      "Thanh Toán",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.orangeAccent, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "$label: $value",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    try {
      // Load room data
      selectedRoom = await _roomService.getRoomById(widget.showtime.roomId);

      if (selectedRoom != null) {
        // Load cinema data
        selectedCinema =
            await _cinemaService.getCinemaById(selectedRoom!.cinemaId);

        // Load food data
        final foodStream = _foodService.getAllFoods();
        foodStream.listen((foods) {
          setState(() {
            foodItems = foods;
          });
        }, onError: (error) {
          print('Error loading food data: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Có lỗi xảy ra khi tải dữ liệu đồ ăn'),
              backgroundColor: Colors.red,
            ),
          );
        });

        setState(() {});
      }
    } catch (e) {
      print('Error loading data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra khi tải dữ liệu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
