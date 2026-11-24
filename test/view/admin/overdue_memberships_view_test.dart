import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/admin/admin_dashboard.dart';
import 'package:academiagrazi/service/admin/admin_student_service.dart';
import 'package:academiagrazi/service/memberships/membership_service.dart';
import 'package:academiagrazi/service/units/unit_service.dart';
import 'package:academiagrazi/view/admin/admin_student_details_view.dart';
import 'package:academiagrazi/view/admin/overdue_memberships_view.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MembershipService service;
  DateTime hoje() => DateTime(2026, 2, 20);

  setUp(() async {
    await locator.reset();
    db = FakeFirebaseFirestore();
    service = MembershipService(db: db, clock: hoje);
    locator.registerSingleton<MembershipService>(service);
    locator.registerSingleton<AdminStudentService>(AdminStudentService(db: db));
    locator.registerSingleton<AdminDashboardService>(
      AdminDashboardService(db: db),
    );
    locator.registerSingleton<UnitService>(UnitService(db: db));
    for (final (id, name) in [('a1', 'Ana Lima'), ('a2', 'Bruno Dias')]) {
      await db.collection('users').doc(id).set({
        'name': name,
        'email': '$id@test.com',
        'type': 'user',
      });
    }
  });

  tearDown(() async => locator.reset());

  Future<void> atribuir(String studentId, DateTime start) async {
    final plans = await service.streamPlans().first;
    final plan =
        plans.isNotEmpty
            ? plans.first
            : (await () async {
              await service.createPlan(
                name: 'Trimestral',
                monthlyPriceCents: 12990,
                durationMonths: 3,
              );
              return (await service.streamPlans().first).first;
            }());
    await service.assignPlan(
      studentId: studentId,
      plan: plan,
      startDate: start,
      adminId: 'admin1',
    );
  }

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: OverdueMembershipsView(clock: hoje)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sem atraso mostra que está tudo em dia', (tester) async {
    await atribuir('a1', DateTime(2026, 2, 25));
    await abrir(tester);

    expect(
      find.text('Nenhuma mensalidade vencida em aberto. Tudo em dia!'),
      findsOneWidget,
    );
  });

  testWidgets('lista quem está em atraso e abre os detalhes', (tester) async {
    await atribuir('a1', DateTime(2026, 1, 10));
    await atribuir('a2', DateTime(2026, 2, 25));
    await abrir(tester);

    expect(find.text(r'1 aluno · R$ 259,80 em aberto'), findsOneWidget);
    expect(find.text('Ana Lima'), findsOneWidget);
    expect(find.text('Bruno Dias'), findsNothing);

    await tester.tap(find.byKey(const Key('card_atraso_a1')));
    await tester.pumpAndSettle();

    expect(find.byType(AdminStudentDetailsView), findsOneWidget);
  });
}
