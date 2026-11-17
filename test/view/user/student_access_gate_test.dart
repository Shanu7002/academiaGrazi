import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/memberships/membership_model.dart';
import 'package:academiagrazi/service/memberships/membership_service.dart';
import 'package:academiagrazi/service/users/register_user.dart';
import 'package:academiagrazi/view/user/student_access_gate.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../aluno_profile_view_test.mocks.dart' show MockFirebaseAuth;

void main() {
  late FakeFirebaseFirestore db;
  late MembershipService service;
  late MockFirebaseAuth auth;
  // 1ª mensalidade em 10/01: em 20/01 está vencida há 10 dias.
  DateTime hoje() => DateTime(2026, 1, 20);

  setUp(() async {
    await locator.reset();
    db = FakeFirebaseFirestore();
    service = MembershipService(db: db, clock: hoje);
    auth = MockFirebaseAuth();
    when(auth.signOut()).thenAnswer((_) async {});
    locator.registerSingleton<MembershipService>(service);
    locator.registerSingleton<RegisterUserService>(RegisterUserService(db: db));
    locator.registerSingleton<FirebaseAuth>(auth);
    await db.collection('users').doc('prof1').set({
      'name': 'Carla Mendes',
      'email': 'carla@test.com',
      'type': 'instructor',
    });
    await db.collection('users').doc('aluno1').set({
      'name': 'Ana',
      'email': 'ana@test.com',
      'type': 'user',
      'responsable': 'prof1',
    });
  });

  tearDown(() async => locator.reset());

  Future<String> atribuir(DateTime start) async {
    await service.createPlan(
      name: 'Trimestral',
      monthlyPriceCents: 12990,
      durationMonths: 3,
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
        home: StudentAccessGate(
          studentId: 'aluno1',
          clock: hoje,
          child: const Text('area_do_aluno'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('aluno sem plano entra normalmente', (tester) async {
    await abrir(tester);

    expect(find.text('area_do_aluno'), findsOneWidget);
  });

  testWidgets('atraso dentro da tolerância não bloqueia', (tester) async {
    await atribuir(DateTime(2026, 1, 17));
    await abrir(tester);

    expect(find.text('area_do_aluno'), findsOneWidget);
  });

  testWidgets('atraso além da tolerância bloqueia e cita o professor', (
    tester,
  ) async {
    await atribuir(DateTime(2026, 1, 10));
    await abrir(tester);

    expect(find.text('area_do_aluno'), findsNothing);
    expect(
      find.text(
        'Entre em contato com seu professor responsável, Carla Mendes, '
        'para regularizar.',
      ),
      findsOneWidget,
    );
    expect(find.text(r'1 mensalidade em aberto · R$ 129,90'), findsOneWidget);
  });

  testWidgets('libera sozinho quando o admin registra o pagamento', (
    tester,
  ) async {
    final id = await atribuir(DateTime(2026, 1, 10));
    await abrir(tester);
    expect(find.text('area_do_aluno'), findsNothing);

    await service.recordPayment(
      id,
      installment: 1,
      paidOn: DateTime(2026, 1, 20),
      method: PaymentMethod.pix,
      amountCents: 12990,
      adminId: 'admin1',
    );
    await tester.pumpAndSettle();

    expect(find.text('area_do_aluno'), findsOneWidget);
  });

  testWidgets('Sair encerra a sessão', (tester) async {
    await atribuir(DateTime(2026, 1, 10));
    await abrir(tester);

    await tester.ensureVisible(find.byKey(const Key('botao_sair_bloqueio')));
    await tester.tap(find.byKey(const Key('botao_sair_bloqueio')));
    await tester.pumpAndSettle();

    verify(auth.signOut()).called(1);
  });
}
