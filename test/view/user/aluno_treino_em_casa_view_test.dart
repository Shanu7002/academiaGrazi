import 'package:academiagrazi/models/training/home_workout_plan.dart';
import 'package:academiagrazi/models/training/training_exercise.dart';
import 'package:academiagrazi/models/training/training_routine.dart';
import 'package:academiagrazi/view/user/aluno_treino_em_casa_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('aluno ve somente treino publicado e pode iniciar', (tester) async {
    const plan = HomeWorkoutPlan(studentId:'aluno',instructorId:'prof',version:1,
      routines: [TrainingRoutine(id:'casa-1',letter:'A',name:'Casa A',focus:'Mobilidade',
        estimatedMinutes:20,warmupInstructions:'Mobilidade de quadril',exercises:[
          TrainingExercise(id:'item1',catalogExerciseId:'manual-1',name:'Agachamento',
            muscleGroup:'Pernas',instructions:'Desça com controle.',
            sets:3,repetitions:10,restSeconds:60)
        ])]);
    String? started;
    await tester.pumpWidget(MaterialApp(home: AlunoTreinoEmCasaView(
      plan:plan,onStart:(id)=>started=id,onHistory:(){})));
    expect(find.text('TREINAR EM CASA'), findsOneWidget);
    expect(find.text('Desça com controle.'), findsOneWidget);
    final button=find.byKey(const Key('iniciar_casa_casa-1'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    expect(started,'casa-1');
  });
}
