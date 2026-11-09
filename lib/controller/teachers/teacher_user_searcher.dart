import 'package:academiagrazi/models/users/registration_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserSummary {
  final String id;
  final String name;

  /// Medidas informadas pelo aluno no cadastro, quando existirem.
  final BodyMeasurements? measurements;

  const UserSummary({required this.id, required this.name, this.measurements});

  factory UserSummary.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final profile = data['registrationProfile'];
    final measurements = profile is Map ? profile['measurements'] : null;
    return UserSummary(
      id: doc.id,
      name: (data['name'] as String?) ?? 'Unknown User',
      measurements:
          measurements is Map
              ? BodyMeasurements.fromJson(
                Map<String, dynamic>.from(measurements),
              )
              : null,
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
