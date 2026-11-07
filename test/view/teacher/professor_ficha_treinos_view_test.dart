import 'package:academiagrazi/controller/teachers/teacher_user_searcher.dart';
import 'package:academiagrazi/models/training/training_plan.dart';
import 'package:academiagrazi/service/training/training_plan_service.dart';
import 'package:academiagrazi/view/teacher/professor_ficha_treinos_view.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<({FakeFirebaseFirestore db, TrainingPlanService service})>
createTestServices({bool withStudent = true}) async {
  final db = FakeFirebaseFirestore();
  if (withStudent) {
    await db.collection('users').doc('aluno-1').set({
      'name': 'Ana Lima',
      'type': 'user',
      'responsable': 'prof-1',
    });
  }
  await db.collection('users').doc('aluno-outro').set({
    'name': 'Aluno de outro professor',
    'type': 'user',
    'responsable': 'prof-2',
  });
  return (db: db, service: TrainingPlanService(db: db));
}

Future<void> loadEditor(
  WidgetTester tester,
  FakeFirebaseFirestore db,
  TrainingPlanService service,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ProfessorFichaTreinosView(
        instructorId: 'prof-1',
        searcher: TeacherUserSearcher(db: db),
        service: service,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Rola a lista externa ate o widget estar na area clicavel do teste.
/// ensureVisible sozinho pode localizar um widget fora da janela de 800x600.
Future<void> tapVisible(WidgetTester tester, Key key) async {
  final target = find.byKey(key);
  await tester.scrollUntilVisible(
    target,
    250.0,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 40,
  );
  await tester.pumpAndSettle();
  expect(target, findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> addSupino(WidgetTester tester) async {
  await tapVisible(tester, const Key('catalogo-c1'));
  // Garante que o clique realmente adicionou o exercicio.
  expect(find.text('Supino Reto'), findsOneWidget);
}

void main() {
  testWidgets('somente mostra os alunos vinculados ao professor', (
    tester,
  ) async {
    final setup = await createTestServices();
    await loadEditor(tester, setup.db, setup.service);
    expect(find.text('Ana Lima'), findsOneWidget);
    expect(find.text('Aluno de outro professor'), findsNothing);
  });

  testWidgets('mostra estado vazio quando nao existem alunos vinculados', (
    tester,
  ) async {
    final setup = await createTestServices(withStudent: false);
    await loadEditor(tester, setup.db, setup.service);
    expect(find.textContaining('não possui alunos vinculados'), findsOneWidget);
  });

  testWidgets('professor monta Treino A e salva rascunho para o aluno', (
    tester,
  ) async {
    final setup = await createTestServices();
    await loadEditor(tester, setup.db, setup.service);
    expect(find.byKey(const Key('treino-A')), findsOneWidget);

    await addSupino(tester);
    await tapVisible(tester, const Key('salvar-rascunho-ficha'));

    final drafts = await setup.service.getDraftsForStudent(
      studentId: 'aluno-1',
      instructorId: 'prof-1',
    );
    expect(drafts, hasLength(1));
    expect(drafts.single.routines.single.exercises, hasLength(1));
    expect(drafts.single.routines.single.exercises.single.name, 'Supino Reto');
  });

  testWidgets('nao publica sem ao menos um dia agendado', (tester) async {
    final setup = await createTestServices();
    await loadEditor(tester, setup.db, setup.service);
    await addSupino(tester);
    await tapVisible(tester, const Key('publicar-ficha-aluno'));
    expect(find.textContaining('Revise a ficha'), findsOneWidget);
    expect(await setup.service.getActivePlan('aluno-1'), isNull);
  });

  testWidgets('programa segunda e publica Treino A', (tester) async {
    final setup = await createTestServices();
    await loadEditor(tester, setup.db, setup.service);
    await addSupino(tester);

    await tapVisible(tester, const Key('dia-1-null'));
    await tester.tap(find.text('Treino A').last);
    await tester.pumpAndSettle();

    await tapVisible(tester, const Key('publicar-ficha-aluno'));
    await tester.tap(find.text('Confirmar publicação'));
    await tester.pumpAndSettle();

    final published = await setup.service.getActivePlan('aluno-1');
    expect(published, isNotNull);
    expect(published!.status, TrainingPlanStatus.published);
    expect(published.weeklySchedule[DateTime.monday], 'treino-a');
    expect(published.routines.single.exercises, hasLength(1));
  });
}
