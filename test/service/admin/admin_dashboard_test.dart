import 'package:academiagrazi/service/admin/admin_dashboard.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late AdminDashboardService service;
  final now = DateTime(2026, 10, 20);

  setUp(() {
    db = FakeFirebaseFirestore();
    service = AdminDashboardService(db: db);
  });

  Future<void> addUser(String id, String type, String? createdAt) {
    return db.collection('users').doc(id).set({
      'name': id,
      'type': type,
      if (createdAt != null) 'createdAt': createdAt,
    });
  }

  test('conta somente alunos e os novos dos últimos 30 dias', () async {
    await addUser('a1', 'user', DateTime(2026, 1, 1).toIso8601String());
    await addUser('a2', 'user', DateTime(2026, 2, 1).toIso8601String());
    await addUser('a3', 'user', DateTime(2026, 10, 10).toIso8601String());
    await addUser('a4', 'user', null);
    await addUser('p1', 'instructor', DateTime(2026, 10, 15).toIso8601String());
    await addUser('adm', 'admin', DateTime(2026, 10, 15).toIso8601String());

    final stats = await service.getStudentStats(now: now);

    expect(stats.total, 4);
    expect(stats.newLast30Days, 1);
    expect(stats.growthPercent!.round(), 33);
  });

  test('growthPercent é null quando não há base anterior', () async {
    await addUser('a1', 'user', DateTime(2026, 10, 10).toIso8601String());

    final stats = await service.getStudentStats(now: now);

    expect(stats.total, 1);
    expect(stats.growthPercent, isNull);
  });

  test('retorna zero quando não há alunos', () async {
    final stats = await service.getStudentStats(now: now);

    expect(stats.total, 0);
    expect(stats.growthPercent, isNull);
  });
}
