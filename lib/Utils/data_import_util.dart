import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DataImportUtil {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // 1. Import Người dùng mẫu
  static Future<void> importUsers() async {
    final List<Map<String, dynamic>> users = [
      {
        "id": "user_demo_01",
        "fullName": "Nguyễn Văn Demo",
        "email": "demo@gmail.com",
        "phoneNumber": "0987654321",
        "hashedPassword": _hashPassword("12345678aA@"),
        "birthDate": Timestamp.fromDate(DateTime(2000, 1, 1)),
        "gender": "Nam",
        "province": "TP. Hồ Chí Minh",
        "district": "Quận 1",
        "status": "Active",
        "createdAt": Timestamp.now(),
      }
    ];
    try {
      for (var user in users) {
        await _firestore.collection('users').doc(user['id']).set(user);
      }
      print('Hoàn thành import người dùng');
    } catch (e) {
      print('Lỗi khi import người dùng: $e');
    }
  }

  // 2. Import Tỉnh/Thành phố
  static Future<void> importProvinces() async {
    final List<Map<String, dynamic>> provinces = [
      {"id": "p001", "name": "TP. Hồ Chí Minh"},
      {"id": "p002", "name": "Hà Nội"},
      {"id": "p003", "name": "Đà Nẵng"},
      {"id": "p004", "name": "Cần Thơ"},
      {"id": "p005", "name": "Hải Phòng"},
      {"id": "p006", "name": "Bình Dương"},
      {"id": "p007", "name": "Đồng Nai"},
      {"id": "p008", "name": "Khánh Hòa"},
      {"id": "p009", "name": "Thừa Thiên Huế"},
      {"id": "p010", "name": "Bà Rịa - Vũng Tàu"},
    ];
    try {
      for (var province in provinces) {
        await _firestore.collection('provinces').doc(province['id']).set(province);
      }
      print('Hoàn thành import tỉnh thành');
    } catch (e) {
      print('Lỗi khi import tỉnh thành: $e');
    }
  }

  // 3. Import Quận/Huyện
  static Future<void> importDistricts() async {
    final List<Map<String, dynamic>> districts = [
      // Hồ Chí Minh
      {"id": "d001", "name": "Quận 1", "provinceId": "p001"},
      {"id": "d002", "name": "Quận 3", "provinceId": "p001"},
      {"id": "d003", "name": "Quận 4", "provinceId": "p001"},
      {"id": "d004", "name": "Quận 5", "provinceId": "p001"},
      {"id": "d005", "name": "Quận 10", "provinceId": "p001"},
      {"id": "d006", "name": "Quận Bình Thạnh", "provinceId": "p001"},
      {"id": "d007", "name": "Quận Gò Vấp", "provinceId": "p001"},
      {"id": "d008", "name": "Quận Phú Nhuận", "provinceId": "p001"},
      {"id": "d009", "name": "Quận Tân Bình", "provinceId": "p001"},
      {"id": "d010", "name": "Quận Tân Phú", "provinceId": "p001"},
      // Hà Nội
      {"id": "d011", "name": "Quận Ba Đình", "provinceId": "p002"},
      {"id": "d012", "name": "Quận Cầu Giấy", "provinceId": "p002"},
      {"id": "d013", "name": "Quận Đống Đa", "provinceId": "p002"},
      {"id": "d014", "name": "Quận Hai Bà Trưng", "provinceId": "p002"},
      {"id": "d015", "name": "Quận Hoàn Kiếm", "provinceId": "p002"},
      {"id": "d016", "name": "Quận Long Biên", "provinceId": "p002"},
      {"id": "d017", "name": "Quận Thanh Xuân", "provinceId": "p002"},
      {"id": "d018", "name": "Quận Từ Liêm", "provinceId": "p002"},
      {"id": "d019", "name": "Quận Tây Hồ", "provinceId": "p002"},
      {"id": "d020", "name": "Quận Nam Từ Liêm", "provinceId": "p002"},
      // Các quận khác giữ nguyên như dữ liệu của bạn...
    ];
    try {
      for (var district in districts) {
        await _firestore.collection('districts').doc(district['id']).set(district);
      }
      print('Hoàn thành import quận/huyện');
    } catch (e) {
      print('Lỗi khi import quận/huyện: $e');
    }
  }

  // 4. Import Phim
  static Future<void> importMovies() async {
    final List<Map<String, dynamic>> movies = [
      {
        "id": "movie_01",
        "title": "Mai",
        "imagePath": "https://media.themoviedb.org/t/p/w600_and_h900_face/2nF8xD200rcDawuCg5ObxxqA2fC.jpg",
        "isShowingNow": true,
        "status": "showing",
        "genres": [{"id": "g1", "name": "Tình cảm"}],
        "description": "Phim Mai của Trấn Thành...",
        "releaseDate": "2024-02-10",
        "duration": "130 phút",
        "cast": ["Phương Anh Đào"],
        "director": "Trấn Thành",
        "reviewCount": 0
      }
    ];
    try {
      for (var movie in movies) {
        await _firestore.collection('movies').doc(movie['id']).set(movie);
      }
      print('Hoàn thành import phim');
    } catch (e) {
      print('Lỗi khi import phim: $e');
    }
  }

  // 5. Import Đồ ăn
  static Future<void> importFoodData() async {
    final List<Map<String, dynamic>> foodItems = [
      {
        "id": "food_1",
        "name": "Bắp rang bơ",
        "price": 45000,
        "image": "https://tse3.mm.bing.net/th/id/OIP.ctOKZWCmnRImZFwiaJZq5AHaFq?pid=Api&h=220&P=0",
        "description": "Bắp rang giòn tan",
      },
      {
        "id": "food_2",
        "name": "Nước ngọt lớn",
        "price": 35000,
        "image": "https://tse3.mm.bing.net/th/id/OIP.C4NhBZ4RP4ddl8NbVHq9JAHaE6?pid=Api&h=220&P=0",
        "description": "Nước ngọt mát lạnh",
      },
      {
        "id": "food_3",
        "name": "Combo bắp nước",
        "price": 75000,
        "image": "https://tse3.mm.bing.net/th/id/OIP.EoSEdv9v_2W9csW0NUuWswHaGl?pid=Api&h=220&P=0",
        "description": "Combo tiết kiệm: 1 bắp lớn + 1 nước ngọt lớn",
      },
      {
        "id": "food_4",
        "name": "Bắp rang phô mai",
        "price": 55000,
        "image": "https://tse3.mm.bing.net/th/id/OIP.ctOKZWCmnRImZFwiaJZq5AHaFq?pid=Api&h=220&P=0",
        "description": "Bắp rang phô mai",
      },
      {
        "id": "food_5",
        "name": "Bắp rang caramel",
        "price": 50000,
        "image": "https://tse3.mm.bing.net/th/id/OIP.ctOKZWCmnRImZFwiaJZq5AHaFq?pid=Api&h=220&P=0",
        "description": "Bắp rang vị caramel ngọt ngào",
      },
      {
        "id": "food_6",
        "name": "Nước ngọt nhỏ",
        "price": 25000,
        "image": "https://tse3.mm.bing.net/th/id/OIP.C4NhBZ4RP4ddl8NbVHq9JAHaE6?pid=Api&h=220&P=0",
        "description": "Nước ngọt mát lạnh",
      },
      {
        "id": "food_7",
        "name": "Combo gia đình",
        "price": 150000,
        "image": "https://tse4.mm.bing.net/th/id/OIP.F3NNMg8s0NPNUrzANlqg8gHaE8?pid=Api&h=220&P=0",
        "description": "Combo gia đình: 2 bắp lớn + 2 nước lớn",
      },
      {
        "id": "food_8",
        "name": "Bắp rang mix",
        "price": 65000,
        "image": "https://tse3.mm.bing.net/th/id/OIP.ctOKZWCmnRImZFwiaJZq5AHaFq?pid=Api&h=220&P=0",
        "description": "Bắp rang mix 3 vị: bơ, phô mai, caramel",
      },
      {
        "id": "food_9",
        "name": "Combo đôi",
        "price": 95000,
        "image": "https://tse4.mm.bing.net/th/id/OIP.F3NNMg8s0NPNUrzANlqg8gHaE8?pid=Api&h=220&P=0",
        "description": "Combo đôi: 1 bắp lớn + 2 nước lớn",
      }
    ];
    try {
      for (var food in foodItems) {
        await _firestore.collection('foods').doc(food['id']).set({
          ...food,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      print('Hoàn thành import đồ ăn');
    } catch (e) {
      print('Lỗi khi import đồ ăn: $e');
    }
  }

  // 6. Import Bình luận
  static Future<void> importComments() async {
    final List<Map<String, dynamic>> comments = [
      {
        "id": "comment1",
        "movieId": "movie_01",
        "userId": "user_demo_01",
        "userName": "Nguyễn Văn Demo",
        "content": "Phim rất cảm động!",
        "rating": 9.0,
        "createdAt": Timestamp.now(),
        "ticketId": "ticket_01"
      }
    ];
    try {
      for (var comment in comments) {
        await _firestore.collection('comments').doc(comment['id']).set(comment);
      }
      print('Hoàn thành import bình luận');
    } catch (e) {
      print('Lỗi khi import bình luận: $e');
    }
  }

  // 7. Xóa toàn bộ dữ liệu đồ ăn
  static Future<void> deleteAllFoodData() async {
    try {
      final snapshot = await _firestore.collection('foods').get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      print('Đã xóa toàn bộ dữ liệu đồ ăn');
    } catch (e) {
      print('Lỗi khi xóa dữ liệu đồ ăn: $e');
    }
  }

  // HÀM TỔNG HỢP: Import tất cả dữ liệu
  static Future<void> importAllDataDirectly() async {
    print('BẮT ĐẦU NẠP DỮ LIỆU...');
    await importUsers();
    await importProvinces();
    await importDistricts();
    await importMovies();
    await importFoodData();
    await importComments();
    print('NẠP DỮ LIỆU THÀNH CÔNG!');
  }
}
