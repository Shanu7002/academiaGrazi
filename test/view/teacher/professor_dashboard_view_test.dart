import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/teachers/teacher_dashboard.dart';
import 'package:academiagrazi/service/units/instructor_shift_service.dart';
import 'package:academiagrazi/service/units/unit_service.dart';
import 'package:academiagrazi/view/teacher/lista_alunos.dart';
import 'package:academiagrazi/view/teacher/professor_dashboard_view.dart';
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

class _FailingDashboardService extends TeacherDashboardService {
  _FailingDashboardService() : super(db: FakeFirebaseFirestore());

  @override
  Future<TeacherDashboardData> load(String teacherId) async =>
      throw StateError('sem conexão');
}

// Quinta, 12/11/2026, 15:00.
final _now = DateTime(2026, 11, 12, 15);
String _daysAgo(int days) =>
    DateTime(2026, 11, 12 - days, 9).toUtc().toIso8601String();

void main() {
  late FakeFirebaseFirestore db;

  Future<void> addStudent(
    String id, {
    String teacher = 'prof-1',
    int joinedDaysAgo = 200,
    int? trainedDaysAgo,
    bool hasPlan = true,
    int? assessedDaysAgo = 10,
  }) async {
    final ref = db.collection('users').doc(id);
    await ref.set({
      'name': 'Aluno $id',
      'email': '$id@example.com',
      'type': 'user',
      'responsable': teacher,
      'createdAt': _daysAgo(joinedDaysAgo),
    });
    if (trainedDaysAgo != null) {
      await ref.collection('trainingSessions').add({
        'status': 'finished',
        'startedAt': _daysAgo(trainedDaysAgo),
        'finishedAt': _daysAgo(trainedDaysAgo),
      });
    }
    if (hasPlan) {
      await ref.collection('trainingState').doc('current').set({
        'activePlanId': 'ficha-1',
        'instructorId': teacher,
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
  });

  tearDown(() async => locator.reset());

  Future<void> pumpDashboard(
    WidgetTester tester, {
    ValueChanged<String>? onEditStudentTraining,
    ValueChanged<String>? onOpenStudentTraining,
    ValueChanged<String>? onOpenStudentAssessments,
  }) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: ProfessorDashboardView(
          onEditStudentTraining: onEditStudentTraining,
          onOpenStudentTraining: onOpenStudentTraining,
          onOpenStudentAssessments: onOpenStudentAssessments,
        ),
      ),
    );
  }

  String metric(WidgetTester tester, String cardKey) {
    final texts = tester.widgetList<Text>(
      find.descendant(
        of: find.byKey(Key(cardKey)),
        matching: find.byType(Text),
      ),
    );
    return texts.map((text) => text.data).join(' | ');
  }

  testWidgets('contadores e prioridades batem com os dados do Firestore', (
    tester,
  ) async {
    await addStudent('hoje', trainedDaysAgo: 0);
    await addStudent('semana', trainedDaysAgo: 4);
    await addStudent('risco', trainedDaysAgo: 15);
    await addStudent('inativo', trainedDaysAgo: 40, assessedDaysAgo: 120);
    await addStudent(
      'novo',
      joinedDaysAgo: 3,
      hasPlan: false,
      assessedDaysAgo: null,
    );
    await addStudent('de-outro', teacher: 'prof-2', trainedDaysAgo: 0);

    await pumpDashboard(tester);
    expect(find.text('…'), findsNWidgets(3));
    await tester.pumpAndSettle();

    expect(metric(tester, 'card_alunos_ativos'), contains('| 2 |'));
    expect(metric(tester, 'card_presencas'), contains('| 1 |'));
    expect(metric(tester, 'card_risco_evasao'), contains('| 1 |'));
    expect(find.text('4 Alertas'), findsOneWidget);
    expect(
      find.byKey(const Key('card_prioridade_inactive_inativo')),
      findsOneWidget,
    );
    expect(find.text('40 dias sem treinar (inativo).'), findsOneWidget);
    expect(find.text('15 dias sem treinar.'), findsOneWidget);
    expect(
      find.byKey(const Key('card_prioridade_noPlan_novo')),
      findsOneWidget,
    );
    expect(find.text('Última avaliação há 120 dias.'), findsOneWidget);
    expect(find.text('Aluno de-outro'), findsNothing);

    // Ordem por gravidade: inativo, risco, sem ficha, avaliação.
    final order =
        [
          'card_prioridade_inactive_inativo',
          'card_prioridade_atRisk_risco',
          'card_prioridade_noPlan_novo',
          'card_prioridade_assessmentOverdue_inativo',
        ].map((key) => tester.getTopLeft(find.byKey(Key(key))).dy).toList();
    expect(order, [...order]..sort());
  });

  testWidgets('sem pendências mostra o estado vazio', (tester) async {
    await addStudent('em-dia', trainedDaysAgo: 1);

    await pumpDashboard(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('texto_sem_pendencias')), findsOneWidget);
    expect(find.byKey(const Key('badge_alertas')), findsNothing);
  });

  testWidgets('cada ação navega para a tela certa', (tester) async {
    await addStudent('risco', trainedDaysAgo: 15);
    await addStudent('sem-ficha', trainedDaysAgo: 1, hasPlan: false);
    await addStudent('avaliar', trainedDaysAgo: 1, assessedDaysAgo: 100);
    final training = <String>[];
    final edits = <String>[];
    final assessments = <String>[];

    await pumpDashboard(
      tester,
      onOpenStudentTraining: training.add,
      onEditStudentTraining: edits.add,
      onOpenStudentAssessments: assessments.add,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('card_prioridade_noPlan_sem-ficha')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('card_prioridade_assessmentOverdue_avaliar')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('card_prioridade_atRisk_risco')));
    await tester.pumpAndSettle();
    expect(training, ['sem-ficha', 'risco']);
    expect(assessments, ['avaliar']);

    // O card Alunos abre a lista completa.
    await tester.tap(find.byKey(const Key('card_alunos_ativos')));
    await tester.pumpAndSettle();
    expect(find.byType(ListaAlunosView), findsOneWidget);
    expect(find.byType(CardAluno), findsNWidgets(3));
    await tester.tap(find.byKey(const Key('botao_editar_treino_sem-ficha')));
    await tester.pumpAndSettle();
    expect(find.byType(ListaAlunosView), findsNothing);
    expect(edits, ['sem-ficha']);

    // O card de risco abre a lista já filtrada.
    await tester.tap(find.byKey(const Key('card_risco_evasao')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ChoiceChip>(find.byKey(const Key('filtro_risco'))).selected,
      isTrue,
    );
    expect(find.byType(CardAluno), findsOneWidget);
    await tester.tap(find.byKey(const Key('botao_ver_perfil_risco')));
    await tester.pumpAndSettle();
    expect(find.byType(ListaAlunosView), findsNothing);
    expect(training, ['sem-ficha', 'risco', 'risco']);
  });

  testWidgets('mostra até 5 prioridades e expande em "Ver todas"', (
    tester,
  ) async {
    for (var i = 1; i <= 7; i++) {
      await addStudent('s$i', trainedDaysAgo: 1, hasPlan: false);
    }

    await pumpDashboard(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('card_prioridade_noPlan_s6')), findsNothing);
    await tester.tap(find.byKey(const Key('botao_ver_todas_prioridades')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('card_prioridade_noPlan_s7')), findsOneWidget);
  });

  testWidgets('falha ao carregar mostra aviso e permite tentar de novo', (
    tester,
  ) async {
    locator.allowReassignment = true;
    locator.registerSingleton<TeacherDashboardService>(
      _FailingDashboardService(),
    );

    await pumpDashboard(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('botao_tentar_novamente')), findsOneWidget);
    expect(metric(tester, 'card_presencas'), contains('—'));

    locator.registerSingleton<TeacherDashboardService>(
      TeacherDashboardService(db: db, clock: () => _now),
    );
    await addStudent('volta', trainedDaysAgo: 0);
    await tester.tap(find.byKey(const Key('botao_tentar_novamente')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('botao_tentar_novamente')), findsNothing);
    expect(metric(tester, 'card_presencas'), contains('| 1 |'));
  });

  testWidgets('mostra o bloco atual e o próximo turno da escala', (
    tester,
  ) async {
    final units = UnitService(db: db);
    final shifts = InstructorShiftService(db: db);
    locator.registerSingleton<UnitService>(units);
    locator.registerSingleton<InstructorShiftService>(shifts);
    final unit = await units.createUnit(name: 'Bloco Norte');
    // Um turno em cada dia: sempre há um "próximo".
    for (var day = 1; day <= 7; day++) {
      await shifts.addShift(
        instructorId: 'prof-1',
        unitId: unit,
        weekday: day,
        startTime: '00:00',
        endTime: '00:01',
      );
    }

    await pumpDashboard(tester);
    await tester.pumpAndSettle();

    expect(find.text('Bloco Norte'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('texto_turno_atual'))).data,
      isNot(contains('Bloco A')),
    );
  });
}
