import 'package:academiagrazi/controller/teachers/teacher_user_searcher.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/view/teacher/professor_dashboard_view.dart';
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
    for (final id in ['a1', 'a2']) {
      await db.collection('users').doc(id).set({
        'name': id,
        'type': 'user',
        'responsable': 'prof-1',
      });
    }
    locator.registerSingleton<FirebaseAuth>(_FakeAuth());
    locator.registerSingleton<TeacherUserSearcher>(TeacherUserSearcher(db: db));
  });

  tearDown(() async => locator.reset());

  testWidgets('mostra "…" enquanto conta os alunos e depois o total', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: ProfessorDashboardView()));

    expect(find.text('…'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('…'), findsNothing);
    expect(find.text('2'), findsOneWidget);
  });
}
