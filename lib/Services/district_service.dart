import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movieticketbooking/Model/District.dart';

class DistrictService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tạo quận/huyện mới
  Future<void> createDistrict(District district) async {
    try {
      await _firestore
          .collection('districts')
          .doc(district.id)
          .set(district.toJson());
    } catch (e) {
      print('Error creating district: $e');
      throw e;
    }
  }

  // Lấy thông tin quận/huyện theo ID
  Future<District?> getDistrictById(String districtId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('districts').doc(districtId).get();
      if (doc.exists) {
        return District.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting district: $e');
      throw e;
    }
  }

  // Cập nhật thông tin quận/huyện
  Future<void> updateDistrict(
      String districtId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('districts').doc(districtId).update(data);
    } catch (e) {
      print('Error updating district: $e');
      throw e;
    }
  }

  // Xóa quận/huyện
  Future<void> deleteDistrict(String districtId) async {
    try {
      await _firestore.collection('districts').doc(districtId).delete();
    } catch (e) {
      print('Error deleting district: $e');
      throw e;
    }
  }

  // Lấy danh sách tất cả quận/huyện
  Stream<List<District>> getAllDistricts() {
    return _firestore.collection('districts').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return District.fromJson(doc.data());
      }).toList();
    });
  }

  // Lấy danh sách quận/huyện theo tỉnh/thành phố
  Stream<List<District>> getDistrictsByProvince(String provinceId) {
    return _firestore
        .collection('districts')
        .where('provinceId', isEqualTo: provinceId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return District.fromJson(doc.data());
      }).toList();
    });
  }

  // Lấy danh sách quận/huyện theo tên
  Stream<List<District>> searchDistricts(String query) {
    return _firestore
        .collection('districts')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return District.fromJson(doc.data());
      }).toList();
    });
  }
}
