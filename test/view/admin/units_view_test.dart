import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/units/unit_model.dart';
import 'package:academiagrazi/service/units/unit_service.dart';
import 'package:academiagrazi/view/admin/units_view.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Falha na primeira assinatura e funciona nas seguintes.
class _UnitServiceInstavel extends UnitService {
  var assinaturas = 0;

  _UnitServiceInstavel(FakeFirebaseFirestore db) : super(db: db);

  @override
  Stream<List<UnitModel>> streamUnits({bool includeInactive = false}) {
    assinaturas++;
    if (assinaturas == 1) return Stream.error(Exception('offline'));
    return super.streamUnits(includeInactive: includeInactive);
  }
}

void main() {
  late FakeFirebaseFirestore db;

  setUp(() async {
    await locator.reset();
    db = FakeFirebaseFirestore();
    locator.registerSingleton<UnitService>(UnitService(db: db));
  });

  tearDown(() async => locator.reset());

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: UnitsView()));
    await tester.pumpAndSettle();
  }

  Future<void> preencherESalvar(
    WidgetTester tester, {
    required String nome,
    String endereco = '',
  }) async {
    await tester.enterText(find.byKey(const Key('campo_nome_bloco')), nome);
    await tester.enterText(
      find.byKey(const Key('campo_endereco_bloco')),
      endereco,
    );
    await tester.tap(find.byKey(const Key('botao_salvar_bloco')));
    await tester.pumpAndSettle();
  }

  testWidgets('sem blocos mostra o estado vazio', (tester) async {
    await abrir(tester);

    expect(find.textContaining('Nenhum bloco cadastrado.'), findsOneWidget);
  });

  testWidgets('cadastra um bloco novo', (tester) async {
    await abrir(tester);

    await tester.tap(find.byKey(const Key('botao_novo_bloco')));
    await tester.pumpAndSettle();
    await preencherESalvar(tester, nome: 'Bloco A', endereco: 'Rua 1, 100');

    expect(find.text('Bloco A'), findsOneWidget);
    expect(find.text('Rua 1, 100'), findsOneWidget);
    expect(find.text('Bloco cadastrado.'), findsOneWidget);
    final docs = (await db.collection('units').get()).docs;
    expect(docs.single.data()['name'], 'Bloco A');
  });

  testWidgets('não salva bloco sem nome', (tester) async {
    await abrir(tester);

    await tester.tap(find.byKey(const Key('botao_novo_bloco')));
    await tester.pumpAndSettle();
    await preencherESalvar(tester, nome: '   ');

    expect(find.text('Informe o nome do bloco.'), findsOneWidget);
    expect((await db.collection('units').get()).docs, isEmpty);
  });

  testWidgets('edita o nome tocando no bloco', (tester) async {
    final id = await locator<UnitService>().createUnit(name: 'Bloco A');
    await abrir(tester);

    await tester.tap(find.byKey(Key('card_bloco_$id')));
    await tester.pumpAndSettle();
    await preencherESalvar(tester, nome: 'Bloco Central');

    expect(find.text('Bloco Central'), findsOneWidget);
    expect(find.text('Bloco atualizado.'), findsOneWidget);
  });

  testWidgets('desativa com confirmação e reativa', (tester) async {
    final id = await locator<UnitService>().createUnit(name: 'Bloco A');
    await abrir(tester);

    await tester.tap(find.byKey(Key('botao_ativar_bloco_$id')));
    await tester.pumpAndSettle();
    expect(find.text('Desativar Bloco A?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('botao_confirmar_desativar_bloco')));
    await tester.pumpAndSettle();

    expect(find.text('Desativado'), findsOneWidget);
    expect(
      (await db.collection('units').doc(id).get()).data()!['active'],
      isFalse,
    );

    // Reativar não pede confirmação.
    await tester.tap(find.byKey(Key('botao_ativar_bloco_$id')));
    await tester.pumpAndSettle();

    expect(find.text('Desativado'), findsNothing);
    expect(find.text('Bloco reativado.'), findsOneWidget);
  });

  testWidgets('cancelar a desativação mantém o bloco ativo', (tester) async {
    final id = await locator<UnitService>().createUnit(name: 'Bloco A');
    await abrir(tester);

    await tester.tap(find.byKey(Key('botao_ativar_bloco_$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Desativado'), findsNothing);
    expect(
      (await db.collection('units').doc(id).get()).data()!['active'],
      isTrue,
    );
  });

  testWidgets('na falha mostra erro e tenta de novo', (tester) async {
    final service = _UnitServiceInstavel(db);
    await locator.reset();
    locator.registerSingleton<UnitService>(service);
    await service.createUnit(name: 'Bloco A');
    await abrir(tester);

    expect(find.text('Não foi possível carregar os blocos.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('botao_tentar_blocos')));
    await tester.pumpAndSettle();

    expect(find.text('Bloco A'), findsOneWidget);
  });
}
