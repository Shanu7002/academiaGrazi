import 'package:academiagrazi/controller/teachers/teacher_user_searcher.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/evaluations/physical_evaluation_service.dart';
import 'package:academiagrazi/view/teacher/professor_evolucao_view.dart';
import 'package:academiagrazi/view/teacher/student_open_request.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUser extends Fake implements User {
  @override
  String get uid => 'prof-1';
}

class _FakeAuth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => _FakeUser();
}

void main() {
  setUp(() async {
    await locator.reset();
    final db = FakeFirebaseFirestore();
    for (final (id, name) in [('a1', 'Ana Lima'), ('a2', 'Bruno Alves')]) {
      await db.collection('users').doc(id).set({
        'name': name,
        'type': 'user',
        'responsable': 'prof-1',
      });
    }
    locator.registerSingleton<FirebaseAuth>(_FakeAuth());
    locator.registerSingleton<TeacherUserSearcher>(TeacherUserSearcher(db: db));
    locator.registerSingleton<PhysicalEvaluationService>(
      PhysicalEvaluationService(db: db),
    );
  });

  tearDown(() async => locator.reset());

  testWidgets('seleciona o aluno pedido pelo painel', (tester) async {
    final request = StudentOpenRequest();
    addTearDown(request.dispose);
    await tester.pumpWidget(
      MaterialApp(home: ProfessorEvolucaoView(openRequest: request)),
    );
    await tester.pumpAndSettle();

    final selected = find.byType(DropdownButtonFormField<String>);
    expect(
      find.descendant(of: selected, matching: find.text('Bruno Alves')),
      findsNothing,
    );

    request.open('a2');
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: selected, matching: find.text('Bruno Alves')),
      findsOneWidget,
    );
  });
}
