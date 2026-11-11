import 'package:academiagrazi/models/training/training_exercise.dart';
import 'package:academiagrazi/models/training/training_plan.dart';
import 'package:academiagrazi/models/training/training_routine.dart';
import 'package:academiagrazi/service/training/training_plan_service.dart';
import 'package:academiagrazi/service/training/training_session_service.dart';
import 'package:academiagrazi/view/user/aluno_historico_sessoes_view.dart';
import 'package:academiagrazi/view/user/aluno_sessao_treino_view.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late TrainingSessionService sessions;

  setUp(() async {
    db = FakeFirebaseFirestore();
    sessions = TrainingSessionService(
      db: db,
      planService: TrainingPlanService(db: db),
      clock: () => DateTime.utc(2026, 11, 7, 10),
    );
    final plan = TrainingPlan(
      id: 'ficha-1',
      studentId: 'aluno-1',
      instructorId: 'prof-1',
      name: 'Ciclo atual',
      version: 1,
      status: TrainingPlanStatus.published,
      weeklySchedule: const {1: 'treino-a'},
      routines: [
        TrainingRoutine(
          id: 'treino-a',
          letter: 'A',
          name: 'Treino A',
          focus: 'Pernas',
          estimatedMinutes: 40,
          exercises: [
            TrainingExercise(
              id: 'item-1',
              catalogExerciseId: 'agachamento',
              name: 'Agachamento',
              muscleGroup: 'Pernas',
              sets: 2,
              repetitions: 12,
              restSeconds: 60,
            ),
          ],
        ),
      ],
    );
    await db.collection('users').doc('aluno-1').set({
      'type': 'user',
      'name': 'Ana',
      'responsable': 'prof-1',
    });
    await db
        .collection('users')
        .doc('aluno-1')
        .collection('trainingPlans')
        .doc(plan.id)
        .set(plan.toMap());
    await db
        .collection('users')
        .doc('aluno-1')
        .collection('trainingState')
        .doc('current')
        .set({'activePlanId': plan.id, 'instructorId': 'prof-1'});
  });

  testWidgets('aluno inicia sessao real e registra serie', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AlunoSessaoTreinoView(
          studentId: 'aluno-1',
          planId: 'ficha-1',
          routineId: 'treino-a',
          service: sessions,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Agachamento'), findsOneWidget);
    expect(find.text('0 de 2 séries concluídas'), findsOneWidget);
    final checkbox = find.byKey(const Key('serie_concluida_item-1_1'));
    await tester.ensureVisible(checkbox);
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    expect((await sessions.getInProgress('aluno-1'))?.completedSets, 1);
  });

  testWidgets('historico mostra uma sessao finalizada', (tester) async {
    final created = await sessions.startSession(
      studentId: 'aluno-1',
      planId: 'ficha-1',
      routineId: 'treino-a',
    );
    await sessions.recordSet(
      studentId: 'aluno-1',
      sessionId: created.id,
      exerciseItemId: 'item-1',
      setNumber: 1,
      completed: true,
      loadKg: 20,
    );
    await sessions.finishSession(studentId: 'aluno-1', sessionId: created.id);
    await tester.pumpWidget(
      MaterialApp(
        home: AlunoHistoricoSessoesView(
          studentId: 'aluno-1',
          service: sessions,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Treino A'), findsOneWidget);
    expect(find.textContaining('1/2 séries'), findsOneWidget);
  });
}
