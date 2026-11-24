import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/memberships/membership_service.dart';
import 'package:academiagrazi/view/admin/widgets/student_membership_section.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../aluno_profile_view_test.mocks.dart'
    show MockFirebaseAuth, MockUser;

void main() {
  late FakeFirebaseFirestore db;
  late MembershipService service;
  // 20/02/2026: a 1ª mensalidade (10/01) e a 2ª (10/02) já venceram.
  DateTime hoje() => DateTime(2026, 2, 20, 10);

  setUp(() async {
    await locator.reset();
    db = FakeFirebaseFirestore();
    service = MembershipService(db: db, clock: hoje);
    locator.registerSingleton<MembershipService>(service);
    final auth = MockFirebaseAuth();
    final user = MockUser();
    when(user.uid).thenReturn('admin1');
    when(auth.currentUser).thenReturn(user);
    locator.registerSingleton<FirebaseAuth>(auth);
  });

  tearDown(() async => locator.reset());

  Future<String> criarPlano() => service.createPlan(
    name: 'Trimestral',
    monthlyPriceCents: 12990,
    durationMonths: 3,
  );

  Future<String> atribuir() async {
    await criarPlano();
    final plan = (await service.streamPlans().first).single;
    return service.assignPlan(
      studentId: 'aluno1',
      plan: plan,
      startDate: DateTime(2026, 1, 10),
      adminId: 'admin1',
    );
  }

  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StudentMembershipSection(studentId: 'aluno1', clock: hoje),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('aluno sem plano recebe um plano do catálogo', (tester) async {
    await criarPlano();
    await abrir(tester);

    expect(find.text('Este aluno ainda não tem plano.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('botao_atribuir_plano')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('campo_plano_aluno')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Trimestral').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao_salvar_plano_aluno')));
    await tester.pumpAndSettle();

    expect(find.text('Plano atribuído ao aluno.'), findsOneWidget);
    expect(find.byKey(const Key('nome_plano_aluno')), findsOneWidget);
    final membership = (await db.collection('memberships').get()).docs.single;
    expect(membership['startDate'], '2026-02-20');
    expect(membership['createdBy'], 'admin1');
  });

  testWidgets('mostra as mensalidades e o total em atraso', (tester) async {
    await atribuir();
    await abrir(tester);

    expect(find.text('Em atraso'), findsWidgets);
    expect(find.text(r'2 mensalidades em atraso · R$ 259,80'), findsOneWidget);
    expect(find.text('1ª · vence 10/01/2026'), findsOneWidget);
    expect(find.text('3ª · vence 10/03/2026'), findsOneWidget);
    expect(find.text('A vencer'), findsOneWidget);
  });

  testWidgets('registra e desfaz o pagamento de uma mensalidade', (
    tester,
  ) async {
    final id = await atribuir();
    await abrir(tester);

    await tester.tap(find.byKey(const Key('botao_registrar_pagamento_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao_confirmar_pagamento')));
    await tester.pumpAndSettle();

    expect(
      find.text('Pagamento da 1ª mensalidade registrado.'),
      findsOneWidget,
    );
    expect(find.text(r'1 mensalidade em atraso · R$ 129,90'), findsOneWidget);
    expect(find.text(r'R$ 129,90 · pago em 20/02/2026 · Pix'), findsOneWidget);
    final pago = (await db.collection('memberships').doc(id).get());
    expect((pago['payments'] as List).single['recordedBy'], 'admin1');

    await tester.tap(find.byKey(const Key('botao_desfazer_pagamento_1')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('botao_confirmar_desfazer_pagamento')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pagamento desfeito.'), findsOneWidget);
    expect(find.text(r'2 mensalidades em atraso · R$ 259,80'), findsOneWidget);
  });

  testWidgets('encerra o plano após confirmar', (tester) async {
    final id = await atribuir();
    await abrir(tester);

    await tester.tap(find.byKey(const Key('botao_encerrar_plano')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao_confirmar_encerrar_plano')));
    await tester.pumpAndSettle();

    expect(find.text('Plano encerrado.'), findsOneWidget);
    expect(find.text('Este aluno ainda não tem plano.'), findsOneWidget);
    expect(
      (await db.collection('memberships').doc(id).get())['status'],
      'closed',
    );
  });

  testWidgets('catálogo vazio avisa onde cadastrar planos', (tester) async {
    await abrir(tester);

    await tester.tap(find.byKey(const Key('botao_atribuir_plano')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nenhum plano no catálogo'), findsOneWidget);
  });
}
