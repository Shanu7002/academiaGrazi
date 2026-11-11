import 'package:academiagrazi/models/users/registration_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserSummary {
  final String id;
  final String name;

  /// Foto de perfil do aluno (Cloudinary), quando ele cadastrou uma.
  final String? photoUrl;

  /// Medidas informadas pelo aluno no cadastro, quando existirem.
  final BodyMeasurements? measurements;

  /// Gênero informado pelo aluno no cadastro, quando existir.
  final Gender? gender;

  const UserSummary({
    required this.id,
    required this.name,
    this.photoUrl,
    this.measurements,
    this.gender,
  });

  factory UserSummary.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final profile = data['registrationProfile'];
    final measurements = profile is Map ? profile['measurements'] : null;
    final gender = profile is Map ? profile['gender'] : null;
    return UserSummary(
      id: doc.id,
      name: (data['name'] as String?) ?? 'Unknown User',
      photoUrl: data['photoUrl'] as String?,
      measurements:
          measurements is Map
              ? BodyMeasurements.fromJson(
                Map<String, dynamic>.from(measurements),
              )
              : null,
      gender: Gender.values.asNameMap()[gender],
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
