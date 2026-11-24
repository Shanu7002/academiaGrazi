import 'package:academiagrazi/service/admin/admin_alerts.dart';
import 'package:academiagrazi/service/admin/admin_dashboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  InstructorWorkload professor(String id, int alunos, {int capacidade = 30}) =>
      InstructorWorkload(
        id: id,
        name: 'Prof. $id',
        email: '$id@test.com',
        activeStudents: alunos,
        capacity: capacidade,
      );

  const semInativos = StudentStats(total: 100, newLast30Days: 0);

  test('sem sobrecarga e poucos inativos não gera alerta', () {
    final alertas = adminAlerts(
      stats: const StudentStats(total: 100, newLast30Days: 0, inactive: 9),
      team: [professor('a', 30), professor('b', 10, capacidade: 10)],
    );

    expect(alertas, isEmpty);
  });

  test('alerta cada professor acima da capacidade, do pior para o menor', () {
    final alertas = adminAlerts(
      stats: semInativos,
      team: [
        professor('leve', 31),
        professor('ok', 30),
        professor('pesado', 20, capacidade: 10),
      ],
    );

    expect(alertas.map((a) => a.instructorId), ['pesado', 'leve']);
    expect(alertas.first.type, AdminAlertType.instructorOverCapacity);
    expect(
      alertas.first.description,
      'Prof. pesado está com 20 alunos para 10 vagas.',
    );
  });

  test('alerta inativos acima de 10% dos ativos', () {
    // 12 inativos para 88 ativos = 13,6%.
    final alertas = adminAlerts(
      stats: const StudentStats(total: 100, newLast30Days: 0, inactive: 12),
      team: const [],
    );

    expect(alertas.single.type, AdminAlertType.inactiveStudents);
    expect(alertas.single.instructorId, isNull);
    expect(alertas.single.description, contains('12 alunos'));
    expect(alertas.single.description, contains('14% dos ativos'));
  });

  test('exatamente 10% dos ativos ainda não alerta', () {
    // 10 inativos para 100 ativos.
    final alertas = adminAlerts(
      stats: const StudentStats(total: 110, newLast30Days: 0, inactive: 10),
      team: const [],
    );

    expect(alertas, isEmpty);
  });

  test('todos inativos alerta sem percentual', () {
    final alertas = adminAlerts(
      stats: const StudentStats(total: 5, newLast30Days: 0, inactive: 5),
      team: const [],
    );

    expect(alertas.single.description, isNot(contains('%')));
  });
}
