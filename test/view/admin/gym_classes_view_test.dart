import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/units/gym_class_model.dart';
import 'package:academiagrazi/service/admin/admin_dashboard.dart';
import 'package:academiagrazi/service/units/gym_class_service.dart';
import 'package:academiagrazi/service/units/unit_service.dart';
import 'package:academiagrazi/view/admin/gym_classes_view.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Falha na primeira assinatura e funciona nas seguintes.
class _GymClassServiceInstavel extends GymClassService {
  var assinaturas = 0;

  _GymClassServiceInstavel(FakeFirebaseFirestore db) : super(db: db);

  @override
  Stream<List<GymClassModel>> streamClasses({
    String? unitId,
    bool includeInactive = false,
  }) {
    assinaturas++;
    if (assinaturas == 1) return Stream.error(Exception('offline'));
    return super.streamClasses(
      unitId: unitId,
      includeInactive: includeInactive,
    );
  }
}

void main() {
  late FakeFirebaseFirestore db;

  setUp(() async {
    await locator.reset();
    db = FakeFirebaseFirestore();
    await db.collection('users').doc('prof1').set({
      'name': 'Prof. Lucas',
      'type': 'instructor',
    });
    locator.registerSingleton<UnitService>(UnitService(db: db));
    locator.registerSingleton<GymClassService>(GymClassService(db: db));
    locator.registerSingleton<AdminDashboardService>(
      AdminDashboardService(db: db),
    );
  });

  tearDown(() async => locator.reset());

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: GymClassesView()));
    await tester.pumpAndSettle();
  }

  Future<String> criarBloco() =>
      locator<UnitService>().createUnit(name: 'Bloco A');

  Future<void> preencherESalvar(
    WidgetTester tester, {
    required String nome,
    required String horario,
  }) async {
    await tester.enterText(find.byKey(const Key('campo_nome_aula')), nome);
    await tester.enterText(
      find.byKey(const Key('campo_horario_aula')),
      horario,
    );
    await tester.tap(find.byKey(const Key('botao_salvar_aula')));
    await tester.pumpAndSettle();
  }

  testWidgets('sem aulas mostra o estado vazio', (tester) async {
    await abrir(tester);

    expect(find.textContaining('Nenhuma aula na grade.'), findsOneWidget);
  });

  testWidgets('sem bloco ativo pede para cadastrar um antes', (tester) async {
    await abrir(tester);

    await tester.tap(find.byKey(const Key('botao_nova_aula')));
    await tester.pumpAndSettle();

    expect(
      find.text('Cadastre um bloco ativo antes de criar aulas.'),
      findsOneWidget,
    );
    expect(find.text('Nova aula'), findsOneWidget); // só o botão
  });

  testWidgets('cadastra uma aula e mostra agrupada pelo dia', (tester) async {
    await criarBloco();
    await abrir(tester);

    await tester.tap(find.byKey(const Key('botao_nova_aula')));
    await tester.pumpAndSettle();
    await preencherESalvar(tester, nome: 'Spinning', horario: '1900');

    expect(find.text('Aula cadastrada.'), findsOneWidget);
    expect(find.text('SEGUNDA'), findsOneWidget);
    expect(find.text('19:00'), findsOneWidget);
    expect(find.text('Spinning'), findsOneWidget);
    expect(find.text('60 min · Bloco A'), findsOneWidget);
    final docs = (await db.collection('gym_classes').get()).docs;
    expect(docs.single.data()['startTime'], '19:00');
  });

  testWidgets('recusa horário fora do formato', (tester) async {
    await criarBloco();
    await abrir(tester);

    await tester.tap(find.byKey(const Key('botao_nova_aula')));
    await tester.pumpAndSettle();
    await preencherESalvar(tester, nome: 'Spinning', horario: '2560');

    expect(find.text('Use o formato HH:mm (ex.: 19:00).'), findsOneWidget);
    expect((await db.collection('gym_classes').get()).docs, isEmpty);
  });

  testWidgets('edita tocando na aula e mostra o professor', (tester) async {
    final bloco = await criarBloco();
    final id = await locator<GymClassService>().createClass(
      GymClassModel(
        id: '',
        name: 'Pilates',
        unitId: bloco,
        instructorId: 'prof1',
        weekday: DateTime.friday,
        startTime: '08:00',
        durationMinutes: 50,
        capacity: 12,
      ),
    );
    await abrir(tester);

    expect(
      find.text('50 min · Bloco A · Prof. Lucas · 12 vagas'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(Key('card_aula_$id')));
    await tester.pumpAndSettle();
    await preencherESalvar(tester, nome: 'Pilates Solo', horario: '0930');

    expect(find.text('Aula atualizada.'), findsOneWidget);
    expect(find.text('Pilates Solo'), findsOneWidget);
    expect(find.text('09:30'), findsOneWidget);
  });

  testWidgets('retira da grade com confirmação', (tester) async {
    final bloco = await criarBloco();
    final id = await locator<GymClassService>().createClass(
      GymClassModel(
        id: '',
        name: 'Zumba',
        unitId: bloco,
        weekday: DateTime.monday,
        startTime: '20:00',
        durationMinutes: 45,
      ),
    );
    await abrir(tester);

    await tester.tap(find.byKey(Key('botao_ativar_aula_$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao_confirmar_desativar_aula')));
    await tester.pumpAndSettle();

    expect(find.text('Fora da grade'), findsOneWidget);
    expect(
      (await db.collection('gym_classes').doc(id).get()).data()!['active'],
      isFalse,
    );
  });

  testWidgets('na falha mostra erro e tenta de novo', (tester) async {
    await locator.unregister<GymClassService>();
    locator.registerSingleton<GymClassService>(_GymClassServiceInstavel(db));
    await abrir(tester);

    expect(
      find.text('Não conseguimos carregar a grade de aulas agora.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('botao_tentar_aulas')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nenhuma aula na grade.'), findsOneWidget);
  });
}
