import 'package:academiagrazi/config/business_rules.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/admin/redistribution.dart';
import 'package:academiagrazi/service/students/student_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Filtro da lista de alunos do admin.
enum StudentModalityFilter { all, remote, onSite, undefined }

/// Alunos que casam com a busca por nome (sem diferenciar maiúsculas e
/// acentos) e com o filtro de modalidade.
List<UserModel> filterStudents(
  Iterable<UserModel> students, {
  String query = '',
  StudentModalityFilter modality = StudentModalityFilter.all,
}) {
  final term = _normalize(query);
  return students.where((student) {
    final matchesModality = switch (modality) {
      StudentModalityFilter.all => true,
      StudentModalityFilter.remote =>
        student.modality == StudentModality.remote,
      StudentModalityFilter.onSite =>
        student.modality == StudentModality.onSite,
      StudentModalityFilter.undefined => student.modality == null,
    };
    return matchesModality &&
        (term.isEmpty || _normalize(student.name).contains(term));
  }).toList();
}

String _normalize(String value) {
  const accents = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'é': 'e',
    'ê': 'e',
    'í': 'i',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ü': 'u',
    'ç': 'c',
  };
  var result = value.trim().toLowerCase();
  accents.forEach((from, to) => result = result.replaceAll(from, to));
  return result;
}

/// Situação do aluno para o admin: status e data do último treino.
class StudentActivity {
  final StudentStatus status;
  final DateTime? lastFinishedAt;

  const StudentActivity({required this.status, this.lastFinishedAt});
}

/// Gestão dos alunos pelo admin: listagem, vínculo com o professor e
/// modalidade. As regras do Firestore só aceitam estas escritas do admin.
class AdminStudentService {
  final FirebaseFirestore _db;
  final DateTime Function() _clock;

  // coverage:ignore-start
  AdminStudentService({FirebaseFirestore? db, DateTime Function()? clock})
    : _db = db ?? FirebaseFirestore.instance,
      _clock = clock ?? DateTime.now;
  // coverage:ignore-end

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Todos os alunos, em ordem alfabética.
  Stream<List<UserModel>> streamStudents() => _streamByType(UserType.user);

  /// Professores, em ordem alfabética (para trocar o responsável).
  Stream<List<UserModel>> streamInstructors() =>
      _streamByType(UserType.instructor);

  Stream<List<UserModel>> _streamByType(UserType type) {
    return _users.where('type', isEqualTo: type.name).snapshots().map((
      snapshot,
    ) {
      final users =
          snapshot.docs
              .map((doc) => UserModel.fromJson(doc.data(), doc.id))
              .toList();
      users.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return users;
    });
  }

  /// O aluno, atualizado a cada alteração; `null` se não existir ou não
  /// for aluno.
  Stream<UserModel?> streamStudent(String studentId) {
    return _users.doc(studentId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      final user = UserModel.fromJson(data, doc.id);
      return user.type == UserType.user ? user : null;
    });
  }

  /// Status do aluno pelo último treino finalizado (ver `statusFor`).
  Future<StudentActivity> getActivity(UserModel student) async {
    // Índice `trainingSessions (status, finishedAt)` de escopo coleção.
    final snapshot =
        await _users
            .doc(student.id)
            .collection('trainingSessions')
            .where('status', isEqualTo: 'finished')
            .orderBy('finishedAt', descending: true)
            .limit(1)
            .get();
    final raw =
        snapshot.docs.isEmpty ? null : snapshot.docs.first.data()['finishedAt'];
    final lastFinishedAt = raw is String ? DateTime.tryParse(raw) : null;
    return StudentActivity(
      status: statusFor(
        lastFinishedAt: lastFinishedAt,
        createdAt: student.createdAt,
        now: _clock(),
      ),
      lastFinishedAt: lastFinishedAt,
    );
  }

  /// Vincula o aluno a outro professor. A ficha ativa continua valendo até
  /// o novo professor publicar outra.
  Future<void> changeInstructor(String studentId, String instructorId) {
    if (instructorId.trim().isEmpty) {
      throw ArgumentError.value(instructorId, 'instructorId');
    }
    return _users.doc(studentId).update({'responsable': instructorId});
  }

  /// Prévia da redistribuição automática, proporcional à capacidade de cada
  /// professor (ver [planRedistribution]). Nada é gravado aqui.
  Future<RedistributionPlan> planAutomaticRedistribution() async {
    final results = await Future.wait([
      _users.where('type', isEqualTo: UserType.instructor.name).get(),
      _users.where('type', isEqualTo: UserType.user.name).get(),
    ]);
    final instructors =
        results[0].docs.map((doc) {
            final user = UserModel.fromJson(doc.data(), doc.id);
            return RedistributionInstructor(
              id: user.id,
              name: user.name,
              capacity:
                  user.studentCapacity ?? BusinessRules.defaultStudentCapacity,
            );
          }).toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    final students =
        results[1].docs.map((doc) {
          final user = UserModel.fromJson(doc.data(), doc.id);
          return RedistributionStudent(
            id: user.id,
            name: user.name,
            instructorId: user.responsable,
            joinedAt: user.createdAt,
          );
        }).toList();
    return planRedistribution(students: students, instructors: instructors);
  }

  /// Grava as trocas de professor em lotes (limite de 500 escritas por
  /// lote no Firestore). Cada lote é atômico.
  Future<void> moveStudents(List<StudentMove> moves) async {
    const batchSize = 400;
    for (var start = 0; start < moves.length; start += batchSize) {
      final batch = _db.batch();
      for (final move in moves.skip(start).take(batchSize)) {
        batch.update(_users.doc(move.studentId), {
          'responsable': move.toInstructorId,
        });
      }
      await batch.commit();
    }
  }

  /// Define o bloco em que o aluno treina; `null` tira o bloco.
  Future<void> setUnit(String studentId, String? unitId) {
    return _users.doc(studentId).update({
      'unitId': unitId ?? FieldValue.delete(),
    });
  }

  /// Define se o aluno treina presencialmente ou remotamente.
  Future<void> setModality(String studentId, StudentModality modality) {
    return _users.doc(studentId).update({'modality': modality.name});
  }
}
