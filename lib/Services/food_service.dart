import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movieticketbooking/Model/Food.dart';

class FoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tạo đồ ăn mới
  Future<void> createFood(Food food) async {
    try {
      await _firestore.collection('foods').doc(food.id).set(food.toJson());
    } catch (e) {
      print('Error creating food: $e');
      throw e;
    }
  }

  // Lấy thông tin đồ ăn theo ID
  Future<Food?> getFoodById(String foodId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('foods').doc(foodId).get();
      if (doc.exists) {
        return Food.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting food: $e');
      throw e;
    }
  }

  // Cập nhật thông tin đồ ăn
  Future<void> updateFood(String foodId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('foods').doc(foodId).update(data);
    } catch (e) {
      print('Error updating food: $e');
      throw e;
    }
  }

  // Xóa đồ ăn
  Future<void> deleteFood(String foodId) async {
    try {
      await _firestore.collection('foods').doc(foodId).delete();
    } catch (e) {
      print('Error deleting food: $e');
      throw e;
    }
  }

  // Lấy danh sách tất cả đồ ăn
  Stream<List<Food>> getAllFoods() {
    return _firestore.collection('foods').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Food.fromJson(doc.data());
      }).toList();
    });
  }

  // Lấy danh sách đồ ăn theo loại
  Stream<List<Food>> getFoodsByType(String type) {
    return _firestore
        .collection('foods')
        .where('type', isEqualTo: type)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Food.fromJson(doc.data());
      }).toList();
    });
  }

  // Lấy danh sách đồ ăn theo giá (từ thấp đến cao)
  Stream<List<Food>> getFoodsByPriceRange(double minPrice, double maxPrice) {
    return _firestore
        .collection('foods')
        .where('price', isGreaterThanOrEqualTo: minPrice)
        .where('price', isLessThanOrEqualTo: maxPrice)
        .orderBy('price')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Food.fromJson(doc.data());
      }).toList();
    });
  }

  // Lấy danh sách đồ ăn đang có sẵn
  Stream<List<Food>> getAvailableFoods() {
    return _firestore
        .collection('foods')
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Food.fromJson(doc.data());
      }).toList();
    });
  }
}
