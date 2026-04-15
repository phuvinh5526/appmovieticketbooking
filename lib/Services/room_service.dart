import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movieticketbooking/Model/Room.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tạo phòng chiếu mới
  Future<void> createRoom(Room room) async {
    try {
      await _firestore.collection('rooms').doc(room.id).set(room.toJson());
    } catch (e) {
      print('Error creating room: $e');
      throw e;
    }
  }

  // Lấy thông tin phòng chiếu theo ID
  Future<Room?> getRoomById(String roomId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('rooms').doc(roomId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Room.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting room: $e');
      throw e;
    }
  }

  // Cập nhật thông tin phòng chiếu
  Future<void> updateRoom(String roomId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update(data);
    } catch (e) {
      print('Error updating room: $e');
      throw e;
    }
  }

  // Xóa phòng chiếu
  Future<void> deleteRoom(String roomId) async {
    try {
      await _firestore.collection('rooms').doc(roomId).delete();
    } catch (e) {
      print('Error deleting room: $e');
      throw e;
    }
  }

  // Lấy danh sách tất cả phòng chiếu
  Stream<List<Room>> getAllRooms() {
    return _firestore.collection('rooms').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Room.fromJson(data);
      }).toList();
    });
  }

  // Lấy danh sách phòng chiếu theo rạp
  Stream<List<Room>> getRoomsByCinema(String cinemaId) {
    return _firestore
        .collection('rooms')
        .where('cinemaId', isEqualTo: cinemaId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Room.fromJson(data);
      }).toList();
    });
  }

  // Lấy danh sách phòng chiếu theo loại
  Stream<List<Room>> getRoomsByType(String type) {
    return _firestore
        .collection('rooms')
        .where('type', isEqualTo: type)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Room.fromJson(data);
      }).toList();
    });
  }

  // Lấy danh sách phòng chiếu đang hoạt động
  Stream<List<Room>> getActiveRooms() {
    return _firestore
        .collection('rooms')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Room.fromJson(data);
      }).toList();
    });
  }
}
