import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movieticketbooking/Model/Cinema.dart';

class CinemaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _cinemaCollection =
      FirebaseFirestore.instance.collection('cinemas');

  // Tạo rạp mới
  Future<void> createCinema(Cinema cinema) async {
    await _cinemaCollection.doc(cinema.id).set({
      'name': cinema.name,
      'provinceId': cinema.provinceId,
      'address': cinema.address,
    });
  }

  // Lấy thông tin rạp theo ID
  Future<Cinema?> getCinemaById(String cinemaId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('cinemas').doc(cinemaId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        // Đảm bảo có ID trong data
        data['id'] = doc.id;
        return Cinema.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting cinema: $e');
      throw e;
    }
  }

  // Cập nhật thông tin rạp
  Future<void> updateCinema(String id, Map<String, dynamic> data) async {
    await _cinemaCollection.doc(id).update(data);
  }

  // Lấy danh sách tất cả rạp
  Stream<List<Cinema>> getAllCinemas() {
    return _cinemaCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            
            // Check for required fields
            if (data['name'] == null ||
                data['provinceId'] == null ||
                data['address'] == null) {
              print('Invalid cinema data found: ${doc.id}');
              return null;
            }
            return Cinema.fromJson(data);
          })
          .where((cinema) => cinema != null)
          .cast<Cinema>()
          .toList();
    });
  }

  // Lấy danh sách rạp theo tỉnh/thành phố
  Stream<List<Cinema>> getCinemasByProvince(String provinceId) {
    return _firestore
        .collection('cinemas')
        .where('provinceId', isEqualTo: provinceId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Cinema.fromJson(data);
      }).toList();
    });
  }

  // Lấy danh sách rạp theo quận/huyện
  Stream<List<Cinema>> getCinemasByDistrict(String district) {
    return _firestore
        .collection('cinemas')
        .where('district', isEqualTo: district)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Cinema.fromJson(data);
      }).toList();
    });
  }

  // Lấy danh sách rạp đã xóa
  Stream<List<Cinema>> getDeletedCinemas() {
    return _firestore
        .collection('cinemas')
        .where('status', isEqualTo: 'deleted')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Cinema.fromJson(data);
      }).toList();
    });
  }

  // Xóa rạp
  Future<void> deleteCinema(String id) async {
    await _cinemaCollection.doc(id).delete();
  }

  // Xóa hoàn toàn nhiều rạp
  Future<void> permanentlyDeleteCinemas(List<String> cinemaIds) async {
    try {
      WriteBatch batch = _firestore.batch();

      for (String id in cinemaIds) {
        DocumentReference cinemaRef = _firestore.collection('cinemas').doc(id);
        batch.delete(cinemaRef);
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting cinemas: $e');
      throw e;
    }
  }
}
