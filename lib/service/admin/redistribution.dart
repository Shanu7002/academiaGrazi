/// Aluno considerado na redistribuição.
class RedistributionStudent {
  final String id;
  final String name;

  /// Professor atual; `null` (ou um professor que não existe mais) = sem
  /// professor.
  final String? instructorId;

  /// Data de cadastro: os mais recentes são os primeiros a mudar.
  final DateTime? joinedAt;

  const RedistributionStudent({
    required this.id,
    required this.name,
    this.instructorId,
    this.joinedAt,
  });
}

/// Professor que pode receber alunos.
class RedistributionInstructor {
  final String id;
  final String name;

  /// Vagas do professor; define a fatia de alunos que ele recebe.
  final int capacity;

  const RedistributionInstructor({
    required this.id,
    required this.name,
    required this.capacity,
  });
}

/// Um aluno trocando de professor.
class StudentMove {
  final String studentId;
  final String studentName;
  final String? fromInstructorId;
  final String toInstructorId;

  const StudentMove({
    required this.studentId,
    required this.studentName,
    required this.fromInstructorId,
    required this.toInstructorId,
  });
}

/// Resultado da redistribuição automática, para a prévia e a gravação.
class RedistributionPlan {
  final List<RedistributionInstructor> instructors;

  /// Alunos de cada professor antes e depois (chave: id do professor).
  final Map<String, int> before;
  final Map<String, int> after;

  /// Alunos sem professor antes da redistribuição.
  final int unassignedBefore;
  final List<StudentMove> moves;

  const RedistributionPlan({
    required this.instructors,
    required this.before,
    required this.after,
    required this.unassignedBefore,
    required this.moves,
  });

  bool get isEmpty => moves.isEmpty;
}

/// Quantos alunos cada professor deve ter, proporcional à capacidade.
///
/// Método do maior resto: cada um recebe a parte inteira da sua fatia e as
/// sobras vão para as maiores frações (no empate, maior capacidade e depois
/// o id, para o resultado ser sempre o mesmo). A soma é sempre [total].
Map<String, int> proportionalTargets(
  int total,
  List<RedistributionInstructor> instructors,
) {
  final valid = instructors.where((i) => i.capacity > 0).toList();
  if (valid.isEmpty || total <= 0) {
    return {for (final instructor in instructors) instructor.id: 0};
  }
  final capacity = valid.fold<int>(0, (sum, i) => sum + i.capacity);
  final targets = <String, int>{
    for (final instructor in instructors) instructor.id: 0,
  };
  final remainders = <RedistributionInstructor, double>{};
  var assigned = 0;
  for (final instructor in valid) {
    final share = total * instructor.capacity / capacity;
    final base = share.floor();
    targets[instructor.id] = base;
    remainders[instructor] = share - base;
    assigned += base;
  }
  final order =
      valid.toList()..sort((a, b) {
        final byRemainder = remainders[b]!.compareTo(remainders[a]!);
        if (byRemainder != 0) return byRemainder;
        final byCapacity = b.capacity.compareTo(a.capacity);
        return byCapacity != 0 ? byCapacity : a.id.compareTo(b.id);
      });
  for (var i = 0; i < total - assigned; i++) {
    final instructor = order[i % order.length];
    targets[instructor.id] = targets[instructor.id]! + 1;
  }
  return targets;
}

/// Redistribui os alunos proporcionalmente à capacidade dos professores,
/// movendo o mínimo possível: só saem alunos de quem está acima da sua
/// fatia (os cadastrados mais recentemente primeiro) e os sem professor.
RedistributionPlan planRedistribution({
  required List<RedistributionStudent> students,
  required List<RedistributionInstructor> instructors,
}) {
  final ids = {for (final instructor in instructors) instructor.id};
  final byInstructor = <String, List<RedistributionStudent>>{
    for (final id in ids) id: [],
  };
  final pool = <RedistributionStudent>[];
  for (final student in students) {
    final current = student.instructorId;
    if (current != null && ids.contains(current)) {
      byInstructor[current]!.add(student);
    } else {
      pool.add(student);
    }
  }
  final before = {
    for (final entry in byInstructor.entries) entry.key: entry.value.length,
  };
  final unassignedBefore = pool.length;

  if (instructors.isEmpty) {
    return RedistributionPlan(
      instructors: instructors,
      before: before,
      after: before,
      unassignedBefore: unassignedBefore,
      moves: const [],
    );
  }

  final targets = proportionalTargets(students.length, instructors);

  // Quem está acima da fatia libera os alunos mais recentes.
  for (final instructor in instructors) {
    final current = byInstructor[instructor.id]!;
    final surplus = current.length - targets[instructor.id]!;
    if (surplus <= 0) continue;
    current.sort(_newestFirst);
    pool.addAll(current.take(surplus));
  }

  // Quem está abaixo recebe, sempre o que tem a maior falta primeiro.
  final missing = {
    for (final instructor in instructors)
      instructor.id: targets[instructor.id]! - before[instructor.id]!,
  };
  final moves = <StudentMove>[];
  for (final student in pool) {
    final receiver =
        instructors.where((i) => missing[i.id]! > 0).toList()..sort((a, b) {
          final byMissing = missing[b.id]!.compareTo(missing[a.id]!);
          return byMissing != 0 ? byMissing : a.id.compareTo(b.id);
        });
    if (receiver.isEmpty) break;
    final to = receiver.first.id;
    missing[to] = missing[to]! - 1;
    final from =
        student.instructorId != null && ids.contains(student.instructorId)
            ? student.instructorId
            : null;
    moves.add(
      StudentMove(
        studentId: student.id,
        studentName: student.name,
        fromInstructorId: from,
        toInstructorId: to,
      ),
    );
  }

  final after = Map<String, int>.from(before);
  for (final move in moves) {
    final from = move.fromInstructorId;
    if (from != null) after[from] = after[from]! - 1;
    after[move.toInstructorId] = after[move.toInstructorId]! + 1;
  }

  return RedistributionPlan(
    instructors: instructors,
    before: before,
    after: after,
    unassignedBefore: unassignedBefore,
    moves: moves,
  );
}

/// Mais recentes primeiro; sem data de cadastro conta como mais antigo.
int _newestFirst(RedistributionStudent a, RedistributionStudent b) {
  final aDate = a.joinedAt;
  final bDate = b.joinedAt;
  if (aDate == null && bDate == null) return a.id.compareTo(b.id);
  if (aDate == null) return 1;
  if (bDate == null) return -1;
  final byDate = bDate.compareTo(aDate);
  return byDate != 0 ? byDate : a.id.compareTo(b.id);
}
