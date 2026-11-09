import 'package:academiagrazi/models/training/training_session.dart';
import 'package:academiagrazi/service/training/training_session_service.dart';
import 'package:academiagrazi/view/teacher/professor_resumo_treinos_aluno.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('professor acompanha sessao finalizada via stream real', (tester) async {
    final db = FakeFirebaseFirestore();
    final service = TrainingSessionService(db: db);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(
      child: ProfessorResumoTreinosAluno(
        studentId: 'aluno', service: service, onHistorico: () {},
      ),
    ))));
    await tester.pumpAndSettle();
    await db.collection('users').doc('aluno').collection('trainingSessions')
        .doc('sessao-1').set(TrainingSession(
      id: 'sessao-1', studentId: 'aluno', instructorId: 'prof',
      planId: 'ficha', planVersion: 1, routineId: 'a',
      routineName: 'Treino A', status: TrainingSessionStatus.finished,
      startedAt: DateTime.now().subtract(const Duration(minutes: 40)),
      finishedAt: DateTime.now(), warmupDone: true, exercises: const [],
    ).toMap());
    await tester.pumpAndSettle();
    expect(find.textContaining('Treino A'), findsOneWidget);
    expect(find.byKey(const Key('professor_acompanhar_treinos')), findsOneWidget);
  });
}
