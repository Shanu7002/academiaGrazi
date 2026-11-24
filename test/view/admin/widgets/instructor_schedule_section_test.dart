import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/units/instructor_shift_service.dart';
import 'package:academiagrazi/service/units/unit_service.dart';
import 'package:academiagrazi/view/admin/widgets/instructor_schedule_section.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late InstructorShiftService turnos;
  late String blocoA;

  setUp(() async {
    await locator.reset();
    db = FakeFirebaseFirestore();
    turnos = InstructorShiftService(db: db);
    locator.registerSingleton<InstructorShiftService>(turnos);
    locator.registerSingleton<UnitService>(UnitService(db: db));
    blocoA = await locator<UnitService>().createUnit(name: 'Bloco A');
  });

  tearDown(() async => locator.reset());

  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: InstructorScheduleSection(instructorId: 'p1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<String> turno(String inicio, String fim, {int dia = 1}) {
    return turnos.addShift(
      instructorId: 'p1',
      unitId: blocoA,
      weekday: dia,
      startTime: inicio,
      endTime: fim,
    );
  }

  Future<void> preencher(WidgetTester tester, String inicio, String fim) async {
    await tester.tap(find.byKey(const Key('botao_adicionar_turno')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('campo_inicio_turno')), inicio);
    await tester.enterText(find.byKey(const Key('campo_fim_turno')), fim);
    await tester.tap(find.byKey(const Key('botao_salvar_turno')));
    await tester.pumpAndSettle();
  }

  testWidgets('sem turnos mostra o estado vazio', (tester) async {
    await abrir(tester);

    expect(
      find.text('Nenhum turno na escala deste professor.'),
      findsOneWidget,
    );
  });

  testWidgets('lista os turnos por dia, com horário e bloco', (tester) async {
    await turno('14:00', '18:00', dia: DateTime.wednesday);
    await turno('07:00', '11:00');
    await abrir(tester);

    final textos =
        tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .whereType<String>()
            .where((t) => t.contains('·'))
            .toList();
    expect(textos, ['Segunda · 07:00–11:00', 'Quarta · 14:00–18:00']);
    expect(find.text('Bloco A'), findsNWidgets(2));
  });

  testWidgets('adiciona um turno', (tester) async {
    await abrir(tester);

    await preencher(tester, '0700', '1100');

    expect(find.text('Turno adicionado à escala.'), findsOneWidget);
    expect(find.text('Segunda · 07:00–11:00'), findsOneWidget);
    final docs = (await db.collection('instructorShifts').get()).docs;
    expect(docs.single.data()['startTime'], '07:00');
  });

  testWidgets('recusa turno sobreposto com mensagem clara', (tester) async {
    await turno('07:00', '11:00');
    await abrir(tester);

    await preencher(tester, '1000', '1200');

    expect(
      find.text('Este turno se sobrepõe a Segunda · 07:00–11:00 · Bloco A.'),
      findsOneWidget,
    );
    expect((await db.collection('instructorShifts').get()).docs.length, 1);
  });

  testWidgets('recusa fim antes do início', (tester) async {
    await abrir(tester);

    await preencher(tester, '1100', '0700');

    expect(find.text('O fim deve ser depois do início.'), findsOneWidget);
  });

  testWidgets('remove um turno com confirmação', (tester) async {
    final id = await turno('07:00', '11:00');
    await abrir(tester);

    await tester.tap(find.byKey(Key('botao_remover_turno_$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao_confirmar_remover_turno')));
    await tester.pumpAndSettle();

    expect(find.text('Turno removido da escala.'), findsOneWidget);
    expect((await db.collection('instructorShifts').get()).docs, isEmpty);
  });

  testWidgets('sem bloco ativo pede para cadastrar um', (tester) async {
    await locator<UnitService>().setUnitActive(blocoA, active: false);
    await abrir(tester);

    await tester.tap(find.byKey(const Key('botao_adicionar_turno')));
    await tester.pumpAndSettle();

    expect(
      find.text('Cadastre um bloco ativo antes de montar a escala.'),
      findsOneWidget,
    );
  });
}
