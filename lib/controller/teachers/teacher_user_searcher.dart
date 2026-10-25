import 'package:cloud_firestore/cloud_firestore.dart';

class UserSummary {
  final String id;
  final String name;

  const UserSummary({required this.id, required this.name});

  factory UserSummary.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return UserSummary(
      id: doc.id,
      name: (data['name'] as String?) ?? 'Unknown User',
    );
  }
}

class TeacherUserSearcher {
  final FirebaseFirestore _db;

  // coverage:ignore-start
  TeacherUserSearcher({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  // coverage:ignore-end

  Stream<List<UserSummary>> streamLinkedUsers(String teacherUid) {
    return _db
        .collection('users')
        .where('type', isEqualTo: 'user')
        .where('responsable', isEqualTo: teacherUid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserSummary.fromFirestore(doc))
              .toList();
        });
  }

  Future<int> userQuantity(String teacherUid) async {
    try {
      final AggregateQuerySnapshot snapshot =
          await _db
              .collection('users')
              .where('type', isEqualTo: 'user')
              .where('responsable', isEqualTo: teacherUid)
              .count()
              .get();

      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
