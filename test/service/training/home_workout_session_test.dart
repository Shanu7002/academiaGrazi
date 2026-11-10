import 'package:academiagrazi/models/training/training_plan.dart';
import 'package:academiagrazi/models/training/home_workout_plan.dart';
import 'package:academiagrazi/models/training/training_routine.dart';
import 'package:academiagrazi/models/training/training_exercise.dart';
import 'package:academiagrazi/models/training/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sessao de casa usa snapshot independente do treino presencial', () {
    const r = TrainingRoutine(id:'casa-a', letter:'A', name:'Em casa',focus:'Geral',
      estimatedMinutes:20,exercises:[TrainingExercise(id:'x',
        catalogExerciseId:'manual-x',name:'Agachamento', muscleGroup:'Pernas',
        instructions:'Apoie os pés no chão.',sets:3,repetitions:12,restSeconds:30)]);
    const home = HomeWorkoutPlan(studentId:'a',instructorId:'p',version:2,routines:[r]);
    final fakePlan = TrainingPlan(id:'home',studentId:home.studentId,
      instructorId:home.instructorId,name:'Treinar em casa', version:home.version,
      status:TrainingPlanStatus.published,routines:home.routines,weeklySchedule:const {});
    final session=TrainingSession.fromRoutine(sessionId:'s', plan:fakePlan,
      routine:r, startedAt:DateTime.utc(2026,11,9));
    expect(session.planId,'home');
    expect(session.planVersion,2);
    expect(session.exercises.single.name,'Agachamento');
    expect(TrainingSession.fromMap(session.toMap(),'s').routineName,'Em casa');
  });
}
