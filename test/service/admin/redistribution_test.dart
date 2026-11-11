import 'package:academiagrazi/service/admin/redistribution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RedistributionInstructor prof(String id, int capacidade) =>
      RedistributionInstructor(id: id, name: 'Prof. $id', capacity: capacidade);

  /// [quantidade] alunos do professor [de], cadastrados em dias seguidos
  /// (o último é o mais recente).
  List<RedistributionStudent> alunos(String? de, int quantidade) => [
    for (var i = 0; i < quantidade; i++)
      RedistributionStudent(
        id: '${de ?? 'sem'}-$i',
        name: 'Aluno ${de ?? 'sem'} $i',
        instructorId: de,
        joinedAt: DateTime(2026, 1, 1 + i),
      ),
  ];

  group('proportionalTargets', () {
    test('divide proporcional à capacidade e soma o total', () {
      final alvo = proportionalTargets(30, [prof('a', 40), prof('b', 20)]);

      expect(alvo, {'a': 20, 'b': 10});
    });

    test('sobras vão para as maiores frações', () {
      // 10 × 1/3 = 3,33 para cada; sobra 1, que vai para o menor id.
      final alvo = proportionalTargets(10, [
        prof('c', 30),
        prof('a', 30),
        prof('b', 30),
      ]);

      expect(alvo.values.fold<int>(0, (s, v) => s + v), 10);
      expect(alvo, {'a': 4, 'b': 3, 'c': 3});
    });

    test('sem alunos ou sem capacidade, todos ficam com zero', () {
      expect(proportionalTargets(0, [prof('a', 30)]), {'a': 0});
      expect(proportionalTargets(5, [prof('a', 0)]), {'a': 0});
    });
  });

  group('planRedistribution', () {
    test('equilibra pela capacidade movendo o mínimo possível', () {
      final plano = planRedistribution(
        students: [...alunos('a', 25), ...alunos('b', 5)],
        instructors: [prof('a', 30), prof('b', 30)],
      );

      expect(plano.before, {'a': 25, 'b': 5});
      expect(plano.after, {'a': 15, 'b': 15});
      expect(plano.moves.length, 10);
      expect(plano.moves.every((m) => m.fromInstructorId == 'a'), isTrue);
      expect(plano.moves.every((m) => m.toInstructorId == 'b'), isTrue);
    });

    test('quem sai são os alunos cadastrados mais recentemente', () {
      final plano = planRedistribution(
        students: alunos('a', 4),
        instructors: [prof('a', 30), prof('b', 30)],
      );

      expect(plano.moves.map((m) => m.studentId), ['a-3', 'a-2']);
    });

    test('sem data de cadastro conta como o mais antigo', () {
      final plano = planRedistribution(
        students: [
          const RedistributionStudent(id: 'x', name: 'X', instructorId: 'a'),
          ...alunos('a', 1),
        ],
        instructors: [prof('a', 30), prof('b', 30)],
      );

      expect(plano.moves.single.studentId, 'a-0');
    });

    test('capacidade maior recebe mais alunos', () {
      final plano = planRedistribution(
        students: alunos('a', 30),
        instructors: [prof('a', 20), prof('b', 40)],
      );

      expect(plano.after, {'a': 10, 'b': 20});
    });

    test('distribui quem está sem professor ou com professor removido', () {
      final plano = planRedistribution(
        students: [
          ...alunos(null, 3),
          const RedistributionStudent(
            id: 'orfao',
            name: 'Órfão',
            instructorId: 'removido',
          ),
        ],
        instructors: [prof('a', 30), prof('b', 30)],
      );

      expect(plano.unassignedBefore, 4);
      expect(plano.after, {'a': 2, 'b': 2});
      expect(plano.moves.every((m) => m.fromInstructorId == null), isTrue);
    });

    test('equipe já equilibrada não gera mudanças', () {
      final plano = planRedistribution(
        students: [...alunos('a', 10), ...alunos('b', 10)],
        instructors: [prof('a', 30), prof('b', 30)],
      );

      expect(plano.isEmpty, isTrue);
      expect(plano.after, plano.before);
    });

    test('sem professores não gera mudanças', () {
      final plano = planRedistribution(
        students: alunos(null, 2),
        instructors: const [],
      );

      expect(plano.isEmpty, isTrue);
      expect(plano.unassignedBefore, 2);
    });

    test('o maior déficit recebe primeiro', () {
      final plano = planRedistribution(
        students: alunos('a', 9),
        instructors: [prof('a', 30), prof('b', 30), prof('c', 30)],
      );

      expect(plano.after, {'a': 3, 'b': 3, 'c': 3});
      expect(plano.moves.length, 6);
    });
  });
}
