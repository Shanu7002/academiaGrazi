import 'package:academiagrazi/controller/teachers/teacher_user_searcher.dart';
import 'package:academiagrazi/models/training/training_plan.dart';
import 'package:academiagrazi/service/training/training_plan_service.dart';
import 'package:academiagrazi/view/components/user_avatar.dart';
import 'package:academiagrazi/view/teacher/professor_ficha_treinos_view.dart';
import 'package:academiagrazi/view/teacher/student_open_request.dart';
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
  await tester.pumpWidget(MaterialApp(
    home: ProfessorFichaTreinosView(
      instructorId: 'prof-1',
      searcher: TeacherUserSearcher(db: db),
      service: service,
    ),
  ));
  await tester.pumpAndSettle();
}

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

Future<void> openStudent(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('professor_aluno_aluno-1')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('professor_resumo_aluno')), findsOneWidget);
}

Future<void> openNewDraft(WidgetTester tester) async {
  await openStudent(tester);
  await tapVisible(tester, const Key('criar-ficha-aluno'));
  expect(find.byKey(const Key('professor_editor_ficha')), findsOneWidget);
  expect(find.byKey(const Key('treino-A')), findsOneWidget);
}

Future<void> addSupino(WidgetTester tester) async {
  await tapVisible(tester, const Key('abrir-catalogo-exercicios'));
  await tester.tap(find.byKey(const Key('catalogo-c1')));
  await tester.pumpAndSettle();
  expect(find.text('Supino Reto'), findsOneWidget);
}

Future<void> assignMondayAndPublish(WidgetTester tester) async {
  await tapVisible(tester, const Key('dia-1-null'));
  await tester.tap(find.text('Treino A').last);
  await tester.pumpAndSettle();
  await tapVisible(tester, const Key('publicar-ficha-aluno'));
  await tester.tap(find.text('Confirmar publicação'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('abre primeiro a lista de alunos vinculados', (tester) async {
    final setup = await createTestServices();
    await loadEditor(tester, setup.db, setup.service);
    expect(find.text('MEUS ALUNOS'), findsOneWidget);
    expect(find.text('Ana Lima'), findsOneWidget);
    expect(find.text('Aluno de outro professor'), findsNothing);
    expect(find.byKey(const Key('professor_editor_ficha')), findsNothing);
  });

  testWidgets('mostra a foto de perfil do aluno na lista', (tester) async {
    final setup = await createTestServices();
    const foto = 'https://res.cloudinary.com/demo/image/upload/ana.jpg';
    await setup.db.collection('users').doc('aluno-1').update({
      'photoUrl': foto,
    });
    await loadEditor(tester, setup.db, setup.service);

    final avatar = tester.widget<UserAvatar>(
      find.byKey(const Key('foto_aluno_aluno-1')),
    );
    expect(avatar.photoUrl, foto);
  });

  testWidgets('mostra estado vazio sem alunos vinculados', (tester) async {
    final setup = await createTestServices(withStudent: false);
    await loadEditor(tester, setup.db, setup.service);
    expect(find.textContaining('não possui alunos vinculados'), findsOneWidget);
  });

  testWidgets('abre resumo do aluno antes de criar ficha', (tester) async {
    final setup = await createTestServices();
    await loadEditor(tester, setup.db, setup.service);
    await openStudent(tester);
    expect(find.text('Nenhuma ficha publicada'), findsOneWidget);
    expect(find.byKey(const Key('criar-ficha-aluno')), findsOneWidget);
  });

  testWidgets('abre o aluno pedido por outra tela', (tester) async {
    final setup = await createTestServices();
    final request = StudentOpenRequest();
    addTearDown(request.dispose);
    await tester.pumpWidget(MaterialApp(
      home: ProfessorFichaTreinosView(
        instructorId: 'prof-1',
        searcher: TeacherUserSearcher(db: setup.db),
        service: setup.service,
        openRequest: request,
      ),
    ));
    await tester.pumpAndSettle();

    request.open('aluno-1');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('professor_resumo_aluno')), findsOneWidget);
    expect(find.byKey(const Key('professor_editor_ficha')), findsNothing);
  });

  testWidgets('"Montar treino" abre direto a montagem do aluno', (tester) async {
    final setup = await createTestServices();
    final request = StudentOpenRequest();
    addTearDown(request.dispose);
    await tester.pumpWidget(MaterialApp(
      home: ProfessorFichaTreinosView(
        instructorId: 'prof-1',
        searcher: TeacherUserSearcher(db: setup.db),
        service: setup.service,
        openRequest: request,
      ),
    ));
    await tester.pumpAndSettle();

    request.open('aluno-1', edit: true);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('professor_editor_ficha')), findsOneWidget);
    expect(find.byKey(const Key('treino-A')), findsOneWidget);
  });

  testWidgets('edicao sem publicar nao altera a ficha do aluno',
      (tester) async {
    final setup = await createTestServices();
    await loadEditor(tester, setup.db, setup.service);
    await openNewDraft(tester);
    await addSupino(tester);
    expect(find.byKey(const Key('salvar-rascunho-ficha')), findsNothing);
    expect(find.byKey(const Key('usar-treino-salvo')), findsNothing);
    final drafts = await setup.service.getDraftsForStudent(
      studentId: 'aluno-1', instructorId: 'prof-1',
    );
    expect(drafts, isEmpty);
    expect(await setup.service.getActivePlan('aluno-1'), isNull);
  });

  testWidgets('tocar no exercicio da ficha abre os detalhes', (tester) async {
    final setup = await createTestServices();
    await loadEditor(tester, setup.db, setup.service);
    await openNewDraft(tester);
    await addSupino(tester);

    await tester.ensureVisible(find.text('Supino Reto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supino Reto'));
    await tester.pumpAndSettle();

    final detalhes = find.byKey(const Key('detalhes_exercicio'));
    expect(detalhes, findsOneWidget);
    expect(
      find.descendant(of: detalhes, matching: find.text('Supino Reto')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: detalhes, matching: find.text('ORIENTAÇÕES')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('botao_fechar_detalhes_exercicio')));
    await tester.pumpAndSettle();
    expect(detalhes, findsNothing);
  });

  testWidgets('bloqueia publicacao sem programacao semanal', (tester) async {
    final setup = await createTestServices();
    await loadEditor(tester, setup.db, setup.service);
    await openNewDraft(tester);
    await addSupino(tester);
    await tapVisible(tester, const Key('publicar-ficha-aluno'));
    expect(find.textContaining('Revise a ficha'), findsOneWidget);
    expect(await setup.service.getActivePlan('aluno-1'), isNull);
  });

  testWidgets('professor publica segunda Treino A', (tester) async {
    final setup = await createTestServices();
    await loadEditor(tester, setup.db, setup.service);
    await openNewDraft(tester);
    await addSupino(tester);
    await assignMondayAndPublish(tester);

    final published = await setup.service.getActivePlan('aluno-1');
    expect(published, isNotNull);
    expect(published!.status, TrainingPlanStatus.published);
    expect(published.weeklySchedule[DateTime.monday], 'treino-a');
    expect(published.routines.single.exercises.single.name, 'Supino Reto');
    expect(find.byKey(const Key('professor_ver_ficha_atual')), findsOneWidget);
  });

  testWidgets('professor pode excluir ficha atual preservando historico',
      (tester) async {
    final setup = await createTestServices();
    await loadEditor(tester, setup.db, setup.service);
    await openNewDraft(tester);
    await addSupino(tester);
    await assignMondayAndPublish(tester);
    final original = await setup.service.getActivePlan('aluno-1');
    expect(original, isNotNull);
    await tapVisible(tester, const Key('excluir-ficha-completa'));
    expect(find.text('Excluir ficha completa?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmar-excluir-ficha')));
    await tester.pumpAndSettle();
    expect(await setup.service.getActivePlan('aluno-1'), isNull);
    expect(find.text('Nenhuma ficha publicada'), findsOneWidget);
    final old = await setup.db.collection('users').doc('aluno-1')
        .collection('trainingPlans').doc(original!.id).get();
    expect(old.exists, isTrue);
  });

  testWidgets('ficha publicada reaparece e vira nova versao sem sobrescrever',
      (tester) async {
    final setup = await createTestServices();
    await loadEditor(tester, setup.db, setup.service);
    await openNewDraft(tester);
    await addSupino(tester);
    await assignMondayAndPublish(tester);
    final original = await setup.service.getActivePlan('aluno-1');
    expect(original, isNotNull);

    // Nova instancia, como em uma reinicializacao do aplicativo.
    await tester.pumpWidget(const SizedBox.shrink());
    await loadEditor(tester, setup.db, setup.service);
    await openStudent(tester);
    expect(find.text('Ficha atual'), findsOneWidget);
    await tapVisible(tester, const Key('revisar-ficha-publicada'));
    // A lista usa slivers: o exercicio pode estar fora da area montada.
    await tester.scrollUntilVisible(
      find.text('Supino Reto'),
      230,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 35,
    );
    expect(find.text('Supino Reto'), findsOneWidget);
    // A revisão só é efetivada pelo botão Publicar.
    expect(find.byKey(const Key('salvar-rascunho-ficha')), findsNothing);
    expect((await setup.service.getActivePlan('aluno-1'))!.id, original!.id);
    await tapVisible(tester, const Key('publicar-ficha-aluno'));
    await tester.tap(find.text('Confirmar publicação'));
    await tester.pumpAndSettle();
    final current = await setup.service.getActivePlan('aluno-1');
    expect(current, isNotNull);
    expect(current!.id, isNot(original.id));
    final old = await setup.db.collection('users').doc('aluno-1')
        .collection('trainingPlans').doc(original.id).get();
    expect(old.exists, isTrue);
  });
}
