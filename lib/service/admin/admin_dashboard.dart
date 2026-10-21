import "package:cloud_firestore/cloud_firestore.dart";
import "../../models/users/user_model.dart";

class StudentStats {
  final int total;
  final int newLast30Days;

  const StudentStats({required this.total, required this.newLast30Days});

  /// Crescimento percentual da base de alunos nos últimos 30 dias.
  /// Retorna null quando não existe base anterior para comparar.
  double? get growthPercent {
    final previous = total - newLast30Days;
    if (previous <= 0) return null;
    return newLast30Days / previous * 100;
  }
}

class InstructorWorkload {
  final String id;
  final String name;
  final String email;
  final int activeStudents;

  const InstructorWorkload({
    required this.id,
    required this.name,
    required this.email,
    required this.activeStudents,
  });
}

class InstructorStudent {
  final UserModel user;
  final DateTime? joinedAt;

  const InstructorStudent({required this.user, this.joinedAt});
}

class InstructorDetails {
  final UserModel instructor;
  final List<InstructorStudent> students;

  const InstructorDetails({required this.instructor, required this.students});

  /// Alunos que entraram nos últimos 30 dias.
  int newStudents({DateTime? now}) {
    final limit = (now ?? DateTime.now()).subtract(const Duration(days: 30));
    return students
        .where((s) => s.joinedAt != null && s.joinedAt!.isAfter(limit))
        .length;
  }
}

class AdminDashboardService {
  final FirebaseFirestore _db;

  // coverage:ignore-start
  AdminDashboardService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  // coverage:ignore-end

  Future<StudentStats> getStudentStats({DateTime? now}) async {
    final snapshot =
        await _db
            .collection("users")
            .where("type", isEqualTo: UserType.user.name)
            .get();

    final limit = (now ?? DateTime.now()).subtract(const Duration(days: 30));

    final newStudents =
        snapshot.docs.where((doc) {
          final createdAt = doc.data()["createdAt"];
          if (createdAt is! String) return false;
          final date = DateTime.tryParse(createdAt);
          return date != null && date.isAfter(limit);
        }).length;

    return StudentStats(
      total: snapshot.docs.length,
      newLast30Days: newStudents,
    );
  }

  /// Professores cadastrados e quantos alunos estão vinculados a cada um
  /// (alunos cujo `responsable` é o id do professor), do mais carregado
  /// para o menos carregado.
  Future<List<InstructorWorkload>> getTeamWorkload() async {
    final users = _db.collection("users");
    final results = await Future.wait([
      users.where("type", isEqualTo: UserType.instructor.name).get(),
      users.where("type", isEqualTo: UserType.user.name).get(),
    ]);

    final studentsByInstructor = <String, int>{};
    for (final doc in results[1].docs) {
      final responsable = doc.data()["responsable"];
      if (responsable is String && responsable.isNotEmpty) {
        studentsByInstructor.update(
          responsable,
          (total) => total + 1,
          ifAbsent: () => 1,
        );
      }
    }

    final team =
        results[0].docs.map((doc) {
          final data = doc.data();
          return InstructorWorkload(
            id: doc.id,
            name: (data["name"] as String?)?.trim() ?? "",
            email: data["email"] as String? ?? "",
            activeStudents: studentsByInstructor[doc.id] ?? 0,
          );
        }).toList();

    team.sort((a, b) => b.activeStudents.compareTo(a.activeStudents));
    return team;
  }

  /// Perfil do professor e seus alunos (ordenados pelo nome).
  /// Retorna null se o professor não existir.
  Future<InstructorDetails?> getInstructorDetails(String instructorId) async {
    final users = _db.collection("users");
    final results = await Future.wait([
      users.doc(instructorId).get(),
      users.where("responsable", isEqualTo: instructorId).get(),
    ]);

    final instructorDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final data = instructorDoc.data();
    if (!instructorDoc.exists || data == null) return null;

    final studentDocs = (results[1] as QuerySnapshot<Map<String, dynamic>>).docs
        .where((doc) => doc.data()["type"] == UserType.user.name);

    final students =
        studentDocs.map((doc) {
          final createdAt = doc.data()["createdAt"];
          return InstructorStudent(
            user: UserModel.fromJson(doc.data(), doc.id),
            joinedAt: createdAt is String ? DateTime.tryParse(createdAt) : null,
          );
        }).toList();

    students.sort(
      (a, b) => a.user.name.toLowerCase().compareTo(b.user.name.toLowerCase()),
    );

    return InstructorDetails(
      instructor: UserModel.fromJson(data, instructorDoc.id),
      students: students,
    );
  }
}
