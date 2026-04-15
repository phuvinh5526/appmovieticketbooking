import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Model/Food.dart';
import '../../Services/food_service.dart';
import '../../Components/custom_image_widget.dart';
import 'payment_screen.dart';

class FoodSelectionScreen extends StatefulWidget {
  final String movieTitle;
  final String moviePoster;
  final dynamic showtime;
  final List<String> selectedSeats;
  final double totalPrice;

  const FoodSelectionScreen({
    Key? key,
    required this.movieTitle,
    required this.moviePoster,
    required this.showtime,
    required this.selectedSeats,
    required this.totalPrice,
  }) : super(key: key);

  @override
  _FoodSelectionScreenState createState() => _FoodSelectionScreenState();
}

class _FoodSelectionScreenState extends State<FoodSelectionScreen> {
  Map<String, int> selectedFoods = {}; // Lưu số lượng món ăn đã chọn
  List<Food> foodItems = [];
  bool isLoading = true;
  final FoodService _foodService = FoodService();

  @override
  void initState() {
    super.initState();
    _loadFoodItems();
  }

  void _loadFoodItems() {
    _foodService.getAllFoods().listen((foods) {
      setState(() {
        foodItems = foods;
        isLoading = false;
      });
    }, onError: (e) {
      print('Error loading food items: $e');
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double foodTotal = foodItems.fold(0, (sum, item) {
      return sum + (selectedFoods[item.id] ?? 0) * item.price;
    });

    double finalTotal = widget.totalPrice + foodTotal;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title:
            const Text('Chọn bắp nước', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: foodItems.length,
                    itemBuilder: (context, index) {
                      return _buildFoodItem(foodItems[index]);
                    },
                  ),
                ),
                _buildBottomBar(foodTotal, finalTotal),
              ],
            ),
    );
  }

  Widget _buildFoodItem(Food item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Hình ảnh
          CustomImageWidget(
            imagePath: item.image,
            width: 80,
            height: 80,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(width: 12),

          // Thông tin món ăn
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  item.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 5),
                Text(
                  "${item.price.toStringAsFixed(0)}đ",
                  style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white54, width: 0.8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      int quantity = (selectedFoods[item.id] ?? 0);
                      if (quantity > 0) {
                        selectedFoods[item.id] = quantity - 1;
                      }
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.remove, color: Colors.white, size: 16),
                  ),
                ),
                Container(
                  width: 22,
                  alignment: Alignment.center,
                  child: Text(
                    (selectedFoods[item.id] ?? 0).toString(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      int quantity = (selectedFoods[item.id] ?? 0);
                      selectedFoods[item.id] = quantity + 1;
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(double foodTotal, double finalTotal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tổng tiền",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  "${finalTotal.toStringAsFixed(0)}đ",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 7,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      movieTitle: widget.movieTitle,
                      moviePoster: widget.moviePoster,
                      showtime: widget.showtime,
                      selectedSeats: widget.selectedSeats,
                      totalPrice: finalTotal,
                      selectedFoods: selectedFoods,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Tiếp tục',
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
