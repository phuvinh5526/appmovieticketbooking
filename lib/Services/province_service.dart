import 'package:cloud_firestore/cloud_firestore.dart';
import '../Model/Province.dart';
import '../Model/Cinema.dart';

class ProvinceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tạo tỉnh/thành phố mới
  Future<void> createProvince(Province province) async {
    try {
      await _firestore
          .collection('provinces')
          .doc(province.id)
          .set(province.toJson());
    } catch (e) {
      print('Error creating province: $e');
      throw e;
    }
  }

  // Lấy thông tin tỉnh/thành phố theo ID
  Future<Province?> getProvinceById(String provinceId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('provinces').doc(provinceId).get();
      if (doc.exists) {
        return Province.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting province: $e');
      throw e;
    }
  }

  // Cập nhật thông tin tỉnh/thành phố
  Future<void> updateProvince(
      String provinceId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('provinces').doc(provinceId).update(data);
    } catch (e) {
      print('Error updating province: $e');
      throw e;
    }
  }

  // Xóa tỉnh/thành phố
  Future<void> deleteProvince(String provinceId) async {
    try {
      await _firestore.collection('provinces').doc(provinceId).delete();
    } catch (e) {
      print('Error deleting province: $e');
      throw e;
    }
  }

  // Lấy tất cả tỉnh/thành phố từ Firebase
  Stream<List<Province>> getAllProvinces() {
    try {
      return _firestore.collection('provinces').snapshots().map((snapshot) {
        List<Province> provinceList = [];
        for (var doc in snapshot.docs) {
          try {
            final data = doc.data();
            provinceList.add(Province(
              id: doc.id,
              name: data['name'] ?? 'Không có tên',
            ));
          } catch (e) {
            print('Lỗi khi parse province: $e');
          }
        }

        print('Đã tải ${provinceList.length} tỉnh/thành phố từ Firebase');

        // Sắp xếp theo tên
        provinceList.sort((a, b) => a.name.compareTo(b.name));

        return provinceList;
      }).handleError((error) {
        print('Lỗi khi lấy dữ liệu tỉnh/thành phố: $error');
        // Nếu có lỗi, trả về một số tỉnh/thành phố mặc định để app không bị lỗi
        return [
          Province(id: 'p001', name: 'TP. Hồ Chí Minh'),
          Province(id: 'p002', name: 'Hà Nội'),
          Province(id: 'p003', name: 'Đà Nẵng'),
        ];
      });
    } catch (e) {
      print('Lỗi nghiêm trọng khi tạo stream cho provinces: $e');
      // Tạo stream trả về dữ liệu mẫu
      return Stream.value([
        Province(id: 'p001', name: 'TP. Hồ Chí Minh'),
        Province(id: 'p002', name: 'Hà Nội'),
        Province(id: 'p003', name: 'Đà Nẵng'),
      ]);
    }
  }

  // Lấy danh sách tỉnh/thành phố theo tên
  Stream<List<Province>> searchProvinces(String query) {
    return _firestore
        .collection('provinces')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Province.fromJson(doc.data());
      }).toList();
    });
  }

  Stream<List<Cinema>> getAllCinemas() {
    try {
      return _firestore.collection('cinemas').snapshots().map((snapshot) {
        List<Cinema> cinemaList = [];
        for (var doc in snapshot.docs) {
          try {
            final data = doc.data();
            // Kiểm tra các trường bắt buộc
            if (!data.containsKey('name') ||
                !data.containsKey('provinceId') ||
                !data.containsKey('address')) {
              print('Bỏ qua rạp ${doc.id} do thiếu thông tin bắt buộc');
              continue;
            }

            cinemaList.add(Cinema(
              id: doc.id,
              name: data['name'],
              address: data['address'],
              provinceId: data['provinceId'],
            ));
          } catch (e) {
            print('Lỗi khi xử lý dữ liệu rạp ${doc.id}: $e');
          }
        }

        print('Đã tải ${cinemaList.length} rạp từ Firebase');
        return cinemaList;
      }).handleError((error) {
        print('Lỗi khi lấy dữ liệu rạp: $error');
        return <Cinema>[];
      });
    } catch (e) {
      print('Lỗi nghiêm trọng khi tạo stream cho cinemas: $e');
      return Stream.value(<Cinema>[]);
    }
  }

  Stream<List<Cinema>> getCinemasByProvince(String provinceId) {
    return _firestore
        .collection('cinemas')
        .where('provinceId', isEqualTo: provinceId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Cinema(
                  id: doc.id,
                  name: doc['name'],
                  provinceId: doc['provinceId'],
                  address: doc['address'],
                ))
            .toList());
  }
}
