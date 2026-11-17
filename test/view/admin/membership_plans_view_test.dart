import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/memberships/membership_service.dart';
import 'package:academiagrazi/view/admin/membership_plans_view.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MembershipService service;

  setUp(() async {
    await locator.reset();
    db = FakeFirebaseFirestore();
    service = MembershipService(db: db);
    locator.registerSingleton<MembershipService>(service);
  });

  tearDown(() async => locator.reset());

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MembershipPlansView()));
    await tester.pumpAndSettle();
  }

  testWidgets('sem planos mostra o estado vazio', (tester) async {
    await abrir(tester);

    expect(find.textContaining('Nenhum plano cadastrado.'), findsOneWidget);
  });

  testWidgets('cadastra plano com valor em reais e duração', (tester) async {
    await abrir(tester);

    await tester.tap(find.byKey(const Key('botao_novo_plano')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('campo_nome_plano')),
      'Plano Conexão Semestral',
    );
    await tester.enterText(
      find.byKey(const Key('campo_valor_plano')),
      '129,90',
    );
    await tester.enterText(find.byKey(const Key('campo_duracao_plano')), '6');
    await tester.enterText(
      find.byKey(const Key('campo_modalidades_plano')),
      'Musculação + Pilates',
    );
    await tester.tap(find.byKey(const Key('botao_salvar_plano')));
    await tester.pumpAndSettle();

    expect(find.text('Plano cadastrado.'), findsOneWidget);
    expect(find.text('Plano Conexão Semestral'), findsOneWidget);
    expect(find.text(r'R$ 129,90/mês · 6 meses'), findsOneWidget);
    final data = (await db.collection('membershipPlans').get()).docs.single;
    expect(data['monthlyPriceCents'], 12990);
    expect(data['durationMonths'], 6);
    expect(data['modalities'], 'Musculação + Pilates');
  });

  testWidgets('valida valor e duração antes de salvar', (tester) async {
    await abrir(tester);

    await tester.tap(find.byKey(const Key('botao_novo_plano')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('campo_nome_plano')), 'X');
    await tester.enterText(find.byKey(const Key('campo_valor_plano')), 'abc');
    await tester.enterText(find.byKey(const Key('campo_duracao_plano')), '40');
    await tester.tap(find.byKey(const Key('botao_salvar_plano')));
    await tester.pumpAndSettle();

    expect(find.text('Informe um valor, como 129,90.'), findsOneWidget);
    expect(find.text('Informe de 1 a 36 meses.'), findsOneWidget);
    expect((await db.collection('membershipPlans').get()).docs, isEmpty);
  });

  testWidgets('edita o plano com o valor já preenchido', (tester) async {
    final id = await service.createPlan(
      name: 'Mensal',
      monthlyPriceCents: 15000,
      durationMonths: 1,
    );
    await abrir(tester);

    await tester.tap(find.byKey(Key('card_plano_$id')));
    await tester.pumpAndSettle();
    expect(find.text('150,00'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('campo_valor_plano')), '139,9');
    await tester.tap(find.byKey(const Key('botao_salvar_plano')));
    await tester.pumpAndSettle();

    expect(find.text('Plano atualizado.'), findsOneWidget);
    expect(find.text(r'R$ 139,90/mês · 1 mês'), findsOneWidget);
  });

  testWidgets('retira o plano do catálogo após confirmar', (tester) async {
    final id = await service.createPlan(
      name: 'Mensal',
      monthlyPriceCents: 15000,
      durationMonths: 1,
    );
    await abrir(tester);

    await tester.tap(find.byKey(Key('botao_ativar_plano_$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao_confirmar_retirar_plano')));
    await tester.pumpAndSettle();

    expect(find.text('Fora do catálogo'), findsOneWidget);
    expect(
      (await db.collection('membershipPlans').doc(id).get())['active'],
      isFalse,
    );
  });
}
