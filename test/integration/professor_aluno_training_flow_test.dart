import 'package:academiagrazi/models/training/training_exercise.dart';
import 'package:academiagrazi/models/training/training_plan.dart';
import 'package:academiagrazi/models/training/training_routine.dart';
import 'package:academiagrazi/models/training/training_session.dart';
import 'package:academiagrazi/service/training/training_plan_service.dart';
import 'package:academiagrazi/service/training/training_session_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'professor publica ficha; aluno executa; historico e preservado',
    () async {
      final db = FakeFirebaseFirestore();
      final plans = TrainingPlanService(db: db);
      final time = DateTime.utc(2026, 11, 6, 15);
      var clock = time;
      final sessions = TrainingSessionService(
        db: db,
        planService: plans,
        clock: () => clock,
      );

      await db.collection('users').doc('aluno-1').set({
        'type': 'user',
        'name': 'Ana',
        'responsable': 'prof-1',
      });

      final draft = TrainingPlan(
        id: '',
        studentId: 'aluno-1',
        instructorId: 'prof-1',
        name: 'Treino semanal',
        version: 1,
        status: TrainingPlanStatus.draft,
        weeklySchedule: const {1: 'treino-a', 2: null, 4: 'treino-a'},
        routines: [
          TrainingRoutine(
            id: 'treino-a',
            letter: 'A',
            name: 'Treino A - Pernas',
            focus: 'Pernas',
            estimatedMinutes: 40,
            exercises: [
              TrainingExercise(
                id: 'item-1',
                catalogExerciseId: 'agachamento',
                name: 'Agachamento',
                muscleGroup: 'Pernas',
                sets: 3,
                repetitions: 12,
                restSeconds: 60,
              ),
            ],
          ),
        ],
      );

      final planId = await plans.createDraft(draft);
      expect(await plans.getActivePlan('aluno-1'), isNull);
      await plans.publishDraft(
        studentId: 'aluno-1',
        instructorId: 'prof-1',
        planId: planId,
      );
      final published = await plans.getActivePlan('aluno-1');
      expect(published?.status, TrainingPlanStatus.published);

      final started = await sessions.startSession(
        studentId: 'aluno-1',
        planId: planId,
        routineId: 'treino-a',
        sessionId: 'sessao-1',
      );
      expect(started.totalSets, 3);
      final progress = await sessions.recordSet(
        studentId: 'aluno-1',
        sessionId: started.id,
        exerciseItemId: 'item-1',
        setNumber: 1,
        completed: true,
        loadKg: 30,
      );
      expect(progress.completedSets, 1);
      clock = time.add(const Duration(minutes: 25));
      await sessions.finishSession(studentId: 'aluno-1', sessionId: started.id);
      final history = await sessions.watchHistory('aluno-1').first;
      expect(history.single.status, TrainingSessionStatus.finished);
      expect(history.single.exercises.single.sets.first.loadKg, 30);
      expect((await plans.getActivePlan('aluno-1'))?.id, planId);
    },
  );
}
