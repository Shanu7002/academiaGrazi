import 'package:academiagrazi/config/business_rules.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/students/student_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// O que o painel do professor precisa saber de cada aluno.
class TeacherStudentSnapshot {
  final UserModel student;

  /// Último treino finalizado; null se nunca treinou.
  final DateTime? lastFinishedAt;

  /// Tem ficha publicada ou treino em casa vigente.
  final bool hasActivePlan;

  /// Tem treino em casa vigente.
  final bool hasHomeWorkout;

  /// Programação semanal da ficha publicada (1 = segunda … 7 = domingo →
  /// id do treino, ou null no descanso); null sem ficha presencial.
  final Map<int, String?>? weeklySchedule;

  /// Data da última avaliação física; null se nunca foi avaliado.
  final DateTime? lastAssessmentAt;

  const TeacherStudentSnapshot({
    required this.student,
    this.lastFinishedAt,
    this.hasActivePlan = false,
    this.hasHomeWorkout = false,
    this.weeklySchedule,
    this.lastAssessmentAt,
  });
}

/// Tipos de prioridade, do mais grave para o menos grave.
enum TeacherPriorityKind {
  /// Sem treinar há [BusinessRules.inactiveDaysWithoutTraining] dias ou mais.
  inactive,

  /// Sem treinar há [BusinessRules.riskDaysWithoutTraining] dias ou mais.
  atRisk,

  /// Sem ficha publicada nem treino em casa.
  noPlan,

  /// Avaliação física atrasada (P9).
  assessmentOverdue,
}

class TeacherPriority {
  final TeacherPriorityKind kind;
  final UserModel student;

  /// Dias sem treinar ou desde a última avaliação; null quando o aluno nunca
  /// treinou ou nunca foi avaliado.
  final int? days;

  const TeacherPriority({required this.kind, required this.student, this.days});
}

/// Números e prioridades do painel do professor.
class TeacherDashboardData {
  final int totalStudents;

  /// Alunos com [StudentStatus.active].
  final int activeStudents;

  /// Alunos com treino finalizado hoje.
  final int presentToday;

  /// Alunos em [StudentStatus.atRisk] (prioridades desse tipo), do mais
  /// tempo sem treinar ao menos.
  final List<TeacherPriority> atRisk;

  /// Pendências ordenadas por gravidade.
  final List<TeacherPriority> priorities;

  const TeacherDashboardData({
    required this.totalStudents,
    required this.activeStudents,
    required this.presentToday,
    required this.atRisk,
    required this.priorities,
  });
}

/// Monta o painel a partir dos alunos do professor.
///
/// Prioridades, da mais grave para a menos grave: inativo, risco de evasão,
/// sem ficha e avaliação atrasada. Dentro de cada tipo, quem está há mais
/// dias vem primeiro. Um aluno pode ter mais de uma prioridade.
TeacherDashboardData buildTeacherDashboard(
  Iterable<TeacherStudentSnapshot> students,
  DateTime now,
) {
  var active = 0;
  var presentToday = 0;
  final priorities = <TeacherPriority>[];
  var total = 0;

  for (final item in students) {
    total++;
    final status = statusFor(
      lastFinishedAt: item.lastFinishedAt,
      createdAt: item.student.createdAt,
      now: now,
    );
    final daysIdle = daysWithoutTraining(item.lastFinishedAt, now);

    if (status == StudentStatus.active) active++;
    if (daysIdle == 0) presentToday++;

    if (status == StudentStatus.inactive) {
      priorities.add(
        TeacherPriority(
          kind: TeacherPriorityKind.inactive,
          student: item.student,
          days: daysIdle,
        ),
      );
    } else if (status == StudentStatus.atRisk) {
      priorities.add(
        TeacherPriority(
          kind: TeacherPriorityKind.atRisk,
          student: item.student,
          days: daysIdle,
        ),
      );
    }

    if (!item.hasActivePlan) {
      priorities.add(
        TeacherPriority(
          kind: TeacherPriorityKind.noPlan,
          student: item.student,
        ),
      );
    }

    final assessmentDays = assessmentOverdueDays(item, now);
    if (assessmentDays != null) {
      priorities.add(
        TeacherPriority(
          kind: TeacherPriorityKind.assessmentOverdue,
          student: item.student,
          days: item.lastAssessmentAt == null ? null : assessmentDays,
        ),
      );
    }
  }

  priorities.sort((a, b) {
    final byKind = a.kind.index.compareTo(b.kind.index);
    if (byKind != 0) return byKind;
    // Sem data (nunca treinou ou nunca avaliado) é o caso mais antigo.
    final byDays = (b.days ?? 1 << 30).compareTo(a.days ?? 1 << 30);
    if (byDays != 0) return byDays;
    return a.student.name.toLowerCase().compareTo(b.student.name.toLowerCase());
  });

  return TeacherDashboardData(
    totalStudents: total,
    activeStudents: active,
    presentToday: presentToday,
    atRisk: [
      for (final priority in priorities)
        if (priority.kind == TeacherPriorityKind.atRisk) priority,
    ],
    priorities: priorities,
  );
}

/// Dias de atraso da avaliação (P9), ou null se ela está em dia.
///
/// Sem avaliação, o aluno é cobrado depois de
/// [BusinessRules.firstAssessmentGraceDays] dias de cadastro (sem data de
/// cadastro, já é cobrado); nesse caso devolve os dias de cadastro.
int? assessmentOverdueDays(TeacherStudentSnapshot item, DateTime now) {
  final last = item.lastAssessmentAt;
  if (last != null) {
    final days = daysSince(last, now);
    return days >= BusinessRules.assessmentOverdueDays ? days : null;
  }
  final createdAt = item.student.createdAt;
  final joined = createdAt == null ? null : daysSince(createdAt, now);
  return joined == null || joined >= BusinessRules.firstAssessmentGraceDays
      ? (joined ?? 0)
      : null;
}

/// Lê no Firestore os alunos do professor e o que o painel precisa de cada
/// um. As regras liberam essas leituras só para o professor responsável.
class TeacherDashboardService {
  final FirebaseFirestore _db;
  final DateTime Function() _clock;

  // coverage:ignore-start
  TeacherDashboardService({FirebaseFirestore? db, DateTime Function()? clock})
    : _db = db ?? FirebaseFirestore.instance,
      _clock = clock ?? DateTime.now;
  // coverage:ignore-end

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Data e hora de referência dos cálculos (injetável nos testes).
  DateTime get now => _clock();

  /// Painel do professor: números e prioridades.
  Future<TeacherDashboardData> load(String teacherId) async =>
      buildTeacherDashboard(await loadStudents(teacherId), _clock());

  /// Alunos do professor com o que o painel e a lista precisam de cada um.
  Future<List<TeacherStudentSnapshot>> loadStudents(String teacherId) async {
    if (teacherId.trim().isEmpty) {
      throw ArgumentError.value(teacherId, 'teacherId');
    }
    final snapshot =
        await _users
            .where('type', isEqualTo: UserType.user.name)
            .where('responsable', isEqualTo: teacherId)
            .get();
    final students = snapshot.docs.map(
      (doc) => UserModel.fromJson(doc.data(), doc.id),
    );
    // Quatro leituras pequenas por aluno, em paralelo (mais a ficha ativa).
    return Future.wait(students.map(_snapshotOf));
  }

  Future<TeacherStudentSnapshot> _snapshotOf(UserModel student) async {
    final ref = _users.doc(student.id);
    final results = await Future.wait<Object?>([
      // Índice `trainingSessions (status, finishedAt desc)`.
      ref
          .collection('trainingSessions')
          .where('status', isEqualTo: 'finished')
          .orderBy('finishedAt', descending: true)
          .limit(1)
          .get(),
      ref.collection('trainingState').doc('current').get(),
      ref.collection('homeWorkouts').doc('current').get(),
      ref
          .collection('evaluations')
          .orderBy('date', descending: true)
          .limit(1)
          .get(),
    ]);

    final sessions = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final rawFinished =
        sessions.docs.isEmpty ? null : sessions.docs.first.data()['finishedAt'];
    final plan = results[1] as DocumentSnapshot<Map<String, dynamic>>;
    final home = results[2] as DocumentSnapshot<Map<String, dynamic>>;
    final evaluations = results[3] as QuerySnapshot<Map<String, dynamic>>;
    final rawDate =
        evaluations.docs.isEmpty ? null : evaluations.docs.first.data()['date'];
    final activePlanId = plan.data()?['activePlanId'];

    return TeacherStudentSnapshot(
      student: student,
      lastFinishedAt:
          rawFinished is String ? DateTime.tryParse(rawFinished) : null,
      hasActivePlan: plan.exists || home.exists,
      hasHomeWorkout: home.exists,
      weeklySchedule:
          activePlanId is String && activePlanId.isNotEmpty
              ? await _scheduleOf(ref, activePlanId)
              : null,
      lastAssessmentAt: rawDate is Timestamp ? rawDate.toDate() : null,
    );
  }

  /// Programação semanal da ficha ativa (`weeklySchedule` com dias "1".."7").
  Future<Map<int, String?>?> _scheduleOf(
    DocumentReference<Map<String, dynamic>> student,
    String planId,
  ) async {
    final plan = await student.collection('trainingPlans').doc(planId).get();
    final raw = plan.data()?['weeklySchedule'];
    if (raw is! Map) return null;
    return {
      for (final entry in raw.entries)
        if (int.tryParse('${entry.key}') case final day?)
          day: entry.value is String ? entry.value as String : null,
    };
  }
}
