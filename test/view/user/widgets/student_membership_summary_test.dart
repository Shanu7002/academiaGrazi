import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/memberships/membership_model.dart';
import 'package:academiagrazi/service/memberships/membership_service.dart';
import 'package:academiagrazi/view/user/widgets/student_membership_summary.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MembershipService service;
  DateTime hoje() => DateTime(2026, 2, 20);

  setUp(() async {
    await locator.reset();
    service = MembershipService(db: FakeFirebaseFirestore(), clock: hoje);
    locator.registerSingleton<MembershipService>(service);
  });

  tearDown(() async => locator.reset());

  Future<String> atribuir(DateTime start) async {
    await service.createPlan(
      name: 'Trimestral',
      monthlyPriceCents: 12990,
      durationMonths: 3,
      modalities: 'Musculação',
    );
    final plan = (await service.streamPlans().first).single;
    return service.assignPlan(
      studentId: 'aluno1',
      plan: plan,
      startDate: start,
      adminId: 'admin1',
    );
  }

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentMembershipSummary(studentId: 'aluno1', clock: hoje),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sem plano orienta a procurar a recepção', (tester) async {
    await abrir(tester);

    expect(
      find.textContaining('Você ainda não tem um plano cadastrado.'),
      findsOneWidget,
    );
  });

  testWidgets('mostra validade, próximo vencimento e atraso', (tester) async {
    await atribuir(DateTime(2026, 1, 10));
    await abrir(tester);

    expect(find.text('Trimestral'), findsOneWidget);
    expect(find.text('Válido até 09/04/2026'), findsOneWidget);
    expect(find.text('10/01/2026'), findsOneWidget);
    expect(find.text('Musculação'), findsOneWidget);
    expect(find.text('Em atraso'), findsOneWidget);
    expect(
      find.textContaining(r'2 mensalidades em aberto (R$ 259,80)'),
      findsOneWidget,
    );
  });

  testWidgets('em dia quando a próxima ainda está longe', (tester) async {
    final id = await atribuir(DateTime(2026, 1, 10));
    for (final installment in [1, 2]) {
      await service.recordPayment(
        id,
        installment: installment,
        paidOn: DateTime(2026, 2, 1),
        method: PaymentMethod.pix,
        amountCents: 12990,
        adminId: 'admin1',
      );
    }
    await abrir(tester);

    expect(find.text('Em dia'), findsOneWidget);
    expect(find.text('10/03/2026'), findsOneWidget);
    expect(find.textContaining('em aberto'), findsNothing);
  });
}
