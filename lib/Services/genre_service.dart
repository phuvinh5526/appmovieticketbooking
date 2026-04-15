import 'package:cloud_firestore/cloud_firestore.dart';
import '../Model/Genre.dart';

class GenreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection = 'genres';

  // Lấy danh sách thể loại
  Stream<List<Genre>> getAllGenres() {
    return _firestore.collection(collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Genre(
          id: doc.id,
          name: doc['name'] as String,
        );
      }).toList();
    });
  }

  // Thêm thể loại mới
  Future<DocumentReference> createGenre(Genre genre) async {
    return await _firestore.collection(collection).add({
      'name': genre.name,
    });
  }

  // Cập nhật thể loại
  Future<void> updateGenre(Genre genre) async {
    await _firestore.collection(collection).doc(genre.id).update({
      'name': genre.name,
    });
  }

  // Xóa thể loại
  Future<void> deleteGenre(String id) async {
    await _firestore.collection(collection).doc(id).delete();
  }

  // Lấy thể loại theo ID
  Future<Genre?> getGenreById(String id) async {
    final doc = await _firestore.collection(collection).doc(id).get();
    if (doc.exists) {
      return Genre(
        id: doc.id,
        name: doc['name'] as String,
      );
    }
    return null;
  }

  // Lấy danh sách thể loại theo tên
  Stream<List<Genre>> searchGenres(String query) {
    return _firestore
        .collection('genres')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Genre.fromJson(doc.data());
      }).toList();
    });
  }
}
