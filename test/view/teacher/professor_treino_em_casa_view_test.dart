import 'package:academiagrazi/models/training/home_workout_plan.dart';
import 'package:academiagrazi/service/training/exercise_catalog_service.dart';
import 'package:academiagrazi/service/training/home_workout_service.dart';
import 'package:academiagrazi/view/teacher/professor_treino_em_casa_view.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ServicoQueFalha extends HomeWorkoutService {
  _ServicoQueFalha() : super(db: FakeFirebaseFirestore());

  @override
  Future<HomeWorkoutPlan?> getCurrent(String studentId) async =>
      throw Exception('permission-denied');
}

void main() {
  testWidgets('mostra o erro quando não consegue carregar os treinos', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProfessorTreinoEmCasaView(
          studentId: 'aluno-1',
          studentName: 'Ana',
          instructorId: 'prof-1',
          service: _ServicoQueFalha(),
          catalogService: ExerciseCatalogService(db: FakeFirebaseFirestore()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Não foi possível consultar os treinos em casa'),
      findsOneWidget,
    );
  });
}
