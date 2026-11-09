import 'package:academiagrazi/models/training/training_plan.dart';
import 'package:academiagrazi/service/training/training_plan_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late TrainingPlanService service;

  setUp(() async {
    db = FakeFirebaseFirestore();
    service = TrainingPlanService(db: db);
    await db.collection('users').doc('student-1').set({
      'type': 'user',
      'responsable': 'prof-1',
      'name': 'Ana',
    });
    await db.collection('users').doc('student-2').set({
      'type': 'user',
      'responsable': 'prof-2',
      'name': 'Carlos',
    });
  });

  test('recupera um rascunho anterior do professor correto', () async {
    const draft = TrainingPlan(
      id: '',
      studentId: 'student-1',
      instructorId: 'prof-1',
      name: 'Primeira ficha',
      version: 1,
      status: TrainingPlanStatus.draft,
      routines: [],
      weeklySchedule: {},
    );
    final id = await service.createDraft(draft);

    final drafts = await service.getDraftsForStudent(
      studentId: 'student-1',
      instructorId: 'prof-1',
    );

    expect(drafts, hasLength(1));
    expect(drafts.single.id, id);
    expect(drafts.single.name, 'Primeira ficha');
  });

  test('nao deixa professor nao vinculado consultar rascunhos', () async {
    expect(
      () => service.getDraftsForStudent(
        studentId: 'student-2',
        instructorId: 'prof-1',
      ),
      throwsStateError,
    );
  });
}
