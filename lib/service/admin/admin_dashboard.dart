import "package:academiagrazi/config/business_rules.dart";
import "package:academiagrazi/service/admin/hourly_movement.dart";
import "package:academiagrazi/service/students/student_status.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "../../models/users/user_model.dart";

class StudentStats {
  final int total;
  final int newLast30Days;

  /// Alunos com `modality == 'remote'`.
  final int remote;

  /// Alunos com status [StudentStatus.inactive] (ver `student_status.dart`).
  final int inactive;

  const StudentStats({
    required this.total,
    required this.newLast30Days,
    this.remote = 0,
    this.inactive = 0,
  });

  /// Todos os alunos menos os inativos (inclui os novos e os em risco).
  int get active => total - inactive;

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

  /// `studentCapacity` do professor, ou o padrão de [BusinessRules].
  final int capacity;

  const InstructorWorkload({
    required this.id,
    required this.name,
    required this.email,
    required this.activeStudents,
    this.capacity = BusinessRules.defaultStudentCapacity,
  });

  bool get isOverCapacity => activeStudents > capacity;
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

  /// Totais da home do admin: alunos, novos dos últimos 30 dias, remotos e
  /// inativos. A inatividade vem das sessões finalizadas de cada aluno
  /// (`users/{aluno}/trainingSessions`), lidas numa única consulta de grupo.
  Future<StudentStats> getStudentStats({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final results = await Future.wait([
      _db
          .collection("users")
          .where("type", isEqualTo: UserType.user.name)
          .get(),
      _finishedSessionsSince(
        // Um dia a mais de folga: o limite exato é decidido por statusFor,
        // que conta dias de calendário.
        today.subtract(
          const Duration(days: BusinessRules.inactiveDaysWithoutTraining + 1),
        ),
      ),
    ]);
    final students = results[0].docs;
    final lastFinishedByStudent = _lastFinishedByStudent(results[1].docs);

    final limit = today.subtract(const Duration(days: 30));
    var newStudents = 0;
    var remote = 0;
    var inactive = 0;

    for (final doc in students) {
      final data = doc.data();
      final createdAt = _parseDate(data["createdAt"]);
      if (createdAt != null && createdAt.isAfter(limit)) newStudents++;
      if (data["modality"] == StudentModality.remote.name) remote++;
      final status = statusFor(
        lastFinishedAt: lastFinishedByStudent[doc.id],
        createdAt: createdAt,
        now: today,
      );
      if (status == StudentStatus.inactive) inactive++;
    }

    return StudentStats(
      total: students.length,
      newLast30Days: newStudents,
      remote: remote,
      inactive: inactive,
    );
  }

  /// Treinos finalizados nos últimos 30 dias, agrupados pela hora em que
  /// começaram (06h às 22h). Sessões abandonadas não contam como movimento.
  Future<HourlyMovement> getHourlyMovement({DateTime? now}) async {
    final since = (now ?? DateTime.now()).subtract(const Duration(days: 30));
    final sessions = await _finishedSessionsSince(since);
    return hourlyMovement(
      sessions.docs
          .map((doc) => _parseDate(doc.data()["startedAt"]))
          .whereType<DateTime>(),
    );
  }

  /// Sessões finalizadas a partir de [since], de todos os alunos.
  /// Usa o índice de grupo `trainingSessions (status, finishedAt)`.
  Future<QuerySnapshot<Map<String, dynamic>>> _finishedSessionsSince(
    DateTime since,
  ) {
    return _db
        .collectionGroup("trainingSessions")
        .where("status", isEqualTo: "finished")
        .where(
          "finishedAt",
          isGreaterThanOrEqualTo: since.toUtc().toIso8601String(),
        )
        .get();
  }

  /// Último `finishedAt` de cada aluno. O aluno é o dono da subcoleção
  /// (`users/{aluno}/trainingSessions/{sessao}`).
  static Map<String, DateTime> _lastFinishedByStudent(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> sessions,
  ) {
    final result = <String, DateTime>{};
    for (final session in sessions) {
      final studentId = session.reference.parent.parent?.id;
      final finishedAt = _parseDate(session.data()["finishedAt"]);
      if (studentId == null || finishedAt == null) continue;
      final previous = result[studentId];
      if (previous == null || finishedAt.isAfter(previous)) {
        result[studentId] = finishedAt;
      }
    }
    return result;
  }

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

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
            capacity:
                (data["studentCapacity"] as num?)?.toInt() ??
                BusinessRules.defaultStudentCapacity,
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
