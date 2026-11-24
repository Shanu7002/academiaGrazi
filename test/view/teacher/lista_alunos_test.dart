import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/teachers/teacher_dashboard.dart';
import 'package:academiagrazi/service/teachers/teacher_students.dart';
import 'package:academiagrazi/service/units/unit_service.dart';
import 'package:academiagrazi/view/teacher/lista_alunos.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUser extends Fake implements User {
  @override
  String get uid => 'prof-1';
}

class _FakeAuth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => _FakeUser();
}

/// Falha no primeiro carregamento e funciona depois (conexão que voltou).
class _FlakyService extends TeacherDashboardService {
  _FlakyService(FakeFirebaseFirestore db) : super(db: db, clock: () => _now);

  var _calls = 0;

  @override
  Future<List<TeacherStudentSnapshot>> loadStudents(String teacherId) async {
    if (_calls++ == 0) throw StateError('sem conexão');
    return super.loadStudents(teacherId);
  }
}

// Quinta, 12/11/2026, 15:00.
final _now = DateTime(2026, 11, 12, 15);
String _daysAgo(int days) =>
    DateTime(2026, 11, 12 - days, 9).toUtc().toIso8601String();

void main() {
  late FakeFirebaseFirestore db;

  Future<void> addStudent(
    String id,
    String name, {
    String teacher = 'prof-1',
    int? trainedDaysAgo,
    bool hasPlan = true,
    int? assessedDaysAgo = 10,
    String? unitId,
  }) async {
    final ref = db.collection('users').doc(id);
    await ref.set({
      'name': name,
      'email': '$id@example.com',
      'type': 'user',
      'responsable': teacher,
      'createdAt': _daysAgo(200),
      if (unitId != null) 'unitId': unitId,
    });
    if (trainedDaysAgo != null) {
      await ref.collection('trainingSessions').add({
        'status': 'finished',
        'finishedAt': _daysAgo(trainedDaysAgo),
      });
    }
    if (hasPlan) {
      await ref.collection('trainingState').doc('current').set({
        'activePlanId': 'ficha-1',
        'instructorId': teacher,
      });
      // Treino na sexta: "Próximo treino amanhã" para quem está em dia.
      await ref.collection('trainingPlans').doc('ficha-1').set({
        'weeklySchedule': {'5': 'treino-a'},
      });
    }
    if (assessedDaysAgo != null) {
      await ref.collection('evaluations').add({
        'date': Timestamp.fromDate(DateTime(2026, 11, 12 - assessedDaysAgo)),
      });
    }
  }

  setUp(() async {
    await locator.reset();
    db = FakeFirebaseFirestore();
    locator.registerSingleton<FirebaseAuth>(_FakeAuth());
    locator.registerSingleton<TeacherDashboardService>(
      TeacherDashboardService(db: db, clock: () => _now),
    );
    final units = UnitService(db: db);
    locator.registerSingleton<UnitService>(units);
    await db.collection('units').doc('centro').set({
      'name': 'Bloco Centro',
      'active': true,
    });
    await db.collection('units').doc('jardim').set({
      'name': 'Bloco Jardim',
      'active': true,
    });

    await addStudent('ana', 'Ana Lima', trainedDaysAgo: 1, unitId: 'centro');
    await addStudent(
      'bruno',
      'Bruno Alves',
      trainedDaysAgo: 15,
      unitId: 'jardim',
    );
    await addStudent(
      'carla',
      'Carla Souza',
      trainedDaysAgo: 40,
      hasPlan: false,
      assessedDaysAgo: 120,
      unitId: 'centro',
    );
    await addStudent('outro', 'Aluno de outro', teacher: 'prof-2');
  });

  tearDown(() async => locator.reset());

  Future<void> pumpList(
    WidgetTester tester, {
    TeacherStudentFilter filter = TeacherStudentFilter.all,
    ValueChanged<String>? onOpenStudent,
    ValueChanged<String>? onEditTraining,
  }) async {
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // A lista é aberta por cima do painel: as ações fecham a lista.
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => TextButton(
                key: const Key('abrir_lista'),
                onPressed:
                    () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder:
                            (_) => ListaAlunosView(
                              initialFilter: filter,
                              onOpenStudent: onOpenStudent,
                              onEditTraining: onEditTraining,
                            ),
                      ),
                    ),
                child: const Text('Painel'),
              ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('abrir_lista')));
    await tester.pumpAndSettle();
  }

  List<String> visibleStudents(WidgetTester tester) => [
    for (final card in tester.widgetList<CardAluno>(find.byType(CardAluno)))
      card.row.id,
  ];

  /// Os filtros ficam numa fileira com rolagem horizontal.
  Future<void> tapChip(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  bool isSelected(WidgetTester tester, String key) =>
      tester.widget<ChoiceChip>(find.byKey(Key(key))).selected;

  testWidgets('lista só os alunos do professor com a situação real', (
    tester,
  ) async {
    await pumpList(tester, onOpenStudent: (_) {}, onEditTraining: (_) {});

    expect(visibleStudents(tester), ['ana', 'bruno', 'carla']);
    expect(find.text('Aluno de outro'), findsNothing);
    expect(find.text('Próximo treino amanhã'), findsOneWidget);
    expect(find.text('15 dias sem treinar'), findsOneWidget);
    expect(find.text('Inativo (40 dias)'), findsOneWidget);
    expect(find.text('Avaliação física pendente'), findsOneWidget);
    expect(find.text('Mensagem'), findsNothing);
    // Sem ficha, o botão é "Montar treino".
    expect(
      find.descendant(
        of: find.byKey(const Key('botao_editar_treino_carla')),
        matching: find.text('Montar treino'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('botao_editar_treino_ana')),
        matching: find.text('Editar treino'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('busca por nome sem diferenciar acentos', (tester) async {
    await pumpList(tester);

    await tester.enterText(find.byKey(const Key('campo_busca_aluno')), 'ALV');
    await tester.pumpAndSettle();
    expect(visibleStudents(tester), ['bruno']);

    await tester.enterText(find.byKey(const Key('campo_busca_aluno')), 'xyz');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('texto_sem_resultado')), findsOneWidget);
  });

  testWidgets('filtros destacam a opção ativa e filtram a lista', (
    tester,
  ) async {
    await pumpList(tester);
    expect(isSelected(tester, 'filtro_todos'), isTrue);

    await tapChip(tester, 'filtro_inativos');
    expect(isSelected(tester, 'filtro_inativos'), isTrue);
    expect(isSelected(tester, 'filtro_todos'), isFalse);
    expect(visibleStudents(tester), ['carla']);

    await tapChip(tester, 'filtro_avaliacao_pendente');
    expect(visibleStudents(tester), ['carla']);

    await tapChip(tester, 'filtro_unidade_jardim');
    expect(isSelected(tester, 'filtro_unidade_jardim'), isTrue);
    expect(visibleStudents(tester), ['bruno']);
  });

  testWidgets('abre já filtrada em risco de evasão', (tester) async {
    await pumpList(tester, filter: TeacherStudentFilter.atRisk);

    expect(isSelected(tester, 'filtro_risco'), isTrue);
    expect(visibleStudents(tester), ['bruno']);
  });

  testWidgets('as ações fecham a lista e levam o aluno certo', (tester) async {
    final opened = <String>[];
    final edited = <String>[];
    await pumpList(
      tester,
      onOpenStudent: opened.add,
      onEditTraining: edited.add,
    );

    await tester.tap(find.byKey(const Key('botao_ver_perfil_bruno')));
    await tester.pumpAndSettle();
    expect(find.byType(ListaAlunosView), findsNothing);

    await tester.tap(find.byKey(const Key('abrir_lista')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao_editar_treino_carla')));
    await tester.pumpAndSettle();

    expect(opened, ['bruno']);
    expect(edited, ['carla']);
  });

  testWidgets('sem alunos mostra como convidar', (tester) async {
    db = FakeFirebaseFirestore();
    locator.allowReassignment = true;
    locator.registerSingleton<TeacherDashboardService>(
      TeacherDashboardService(db: db, clock: () => _now),
    );

    await pumpList(tester);

    expect(find.byKey(const Key('texto_sem_alunos')), findsOneWidget);
  });

  testWidgets('falha ao carregar permite tentar de novo', (tester) async {
    locator.allowReassignment = true;
    locator.registerSingleton<TeacherDashboardService>(_FlakyService(db));

    await pumpList(tester);
    expect(find.byKey(const Key('botao_tentar_novamente')), findsOneWidget);
    expect(find.byType(CardAluno), findsNothing);

    await tester.tap(find.byKey(const Key('botao_tentar_novamente')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('botao_tentar_novamente')), findsNothing);
    expect(visibleStudents(tester), ['ana', 'bruno', 'carla']);
  });
}
