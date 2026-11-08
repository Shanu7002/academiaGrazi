import 'package:academiagrazi/controller/teachers/teacher_user_searcher.dart';
import 'package:academiagrazi/service/training/training_plan_service.dart';
import 'package:academiagrazi/service/training/training_session_service.dart';
import 'package:academiagrazi/view/teacher/professor_ficha_treinos_view.dart';
import 'package:academiagrazi/view/teacher/professor_historico_aluno_view.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late TrainingSessionService service;

  setUp(() async {
    db = FakeFirebaseFirestore();
    service = TrainingSessionService(
      db: db,
      planService: TrainingPlanService(db: db),
    );
    await db.collection('users').doc('aluno-1').set({
      'type': 'user',
      'name': 'Ana Lima',
      'responsable': 'prof-1',
    });
    await db.collection('users').doc('aluno-2').set({
      'type': 'user',
      'name': 'Outro aluno',
      'responsable': 'prof-2',
    });
  });

  Future<void> seedFinishedSession() async {
    await db
        .collection('users')
        .doc('aluno-1')
        .collection('trainingSessions')
        .doc('sessao-1')
        .set({
          'schemaVersion': 1,
          'id': 'sessao-1',
          'studentId': 'aluno-1',
          'instructorId': 'prof-1',
          'planId': 'ficha-1',
          'planVersion': 1,
          'routineId': 'treino-a',
          'routineName': 'Treino A',
          'status': 'finished',
          'startedAt': '2026-11-07T10:00:00.000Z',
          'finishedAt': '2026-11-07T10:40:00.000Z',
          'warmupDone': true,
          'exercises': [
            {
              'itemId': 'item-1',
              'catalogExerciseId': 'agachamento',
              'name': 'Agachamento',
              'muscleGroup': 'Pernas',
              'instructions': '',
              'imageUrl': null,
              'repetitions': 12,
              'restSeconds': 60,
              'technique': 'Tradicional',
              'suggestedLoadKg': 20.0,
              'sets': [
                {'number': 1, 'completed': true, 'loadKg': 22.5},
                {'number': 2, 'completed': false, 'loadKg': null},
              ],
            },
          ],
        });
  }

  testWidgets('mostra estado vazio sem treinos finalizados', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProfessorHistoricoAlunoView(
          studentId: 'aluno-1',
          studentName: 'Ana Lima',
          service: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('ainda não finalizou nenhum treino'),
      findsOneWidget,
    );
  });

  testWidgets('professor consulta resumo, cargas e series', (tester) async {
    await seedFinishedSession();
    await tester.pumpWidget(
      MaterialApp(
        home: ProfessorHistoricoAlunoView(
          studentId: 'aluno-1',
          studentName: 'Ana Lima',
          service: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ana Lima'), findsOneWidget);
    expect(find.text('Treino A'), findsOneWidget);
    expect(find.text('Treinos concluídos'), findsOneWidget);
    expect(find.text('Séries concluídas'), findsOneWidget);
    expect(find.text('Duração média'), findsOneWidget);
    expect(find.text('40 min'), findsOneWidget);
    final expanded = find.byKey(const Key('professor_sessao_sessao-1'));
    await tester.ensureVisible(expanded);
    await tester.tap(expanded);
    await tester.pumpAndSettle();
    expect(find.text('Agachamento'), findsOneWidget);
    expect(find.textContaining('22,5 kg'), findsOneWidget);
  });

  testWidgets('botao da montagem abre historico do aluno selecionado', (
    tester,
  ) async {
    await seedFinishedSession();
    await tester.pumpWidget(
      MaterialApp(
        home: ProfessorFichaTreinosView(
          instructorId: 'prof-1',
          searcher: TeacherUserSearcher(db: db),
          service: TrainingPlanService(db: db),
          sessionService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Outro aluno'), findsNothing);
    await tester.tap(find.byKey(const Key('professor_aluno_aluno-1')));
    await tester.pumpAndSettle();
    final button = find.byKey(const Key('professor_acompanhar_treinos'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Acompanhamento de treinos'), findsOneWidget);
    expect(find.text('Ana Lima'), findsOneWidget);
    expect(find.text('Treino A'), findsOneWidget);
  });
}
