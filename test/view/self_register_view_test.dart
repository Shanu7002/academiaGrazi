import 'package:academiagrazi/controller/users/register_user.dart';
import 'package:academiagrazi/service/users/register_user.dart';
import 'package:academiagrazi/view/user/self_register_view.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  late FakeFirebaseFirestore db;
  late RegisterService service;
  late RegisterUserController controller;

  setUp(() async {
    db = FakeFirebaseFirestore();
    service = RegisterService(db: db);
    controller = RegisterUserController(service, auth: _MockFirebaseAuth());
    await db.collection('users').doc('instructor-1').set({
      'name': 'Marina',
      'email': 'marina@example.com',
      'type': 'instructor',
    });
    await db.collection('instructorCodes').doc('ABCD2345').set({
      'instructorId': 'instructor-1',
      'instructorName': 'Marina',
      'active': true,
    });
  });

  Future<void> pumpView(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SelfRegisterView(
          controller: controller,
          userService: service,
          authInstance: _MockFirebaseAuth(),
        ),
      ),
    );
  }

  Future<void> completeAccountStep(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('registrationName')),
      'Aluna Teste',
    );
    await tester.enterText(
      find.byKey(const Key('registrationEmail')),
      'aluna@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('registrationPassword')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const Key('registrationPasswordConfirmation')),
      'password123',
    );
    await tester.ensureVisible(find.byKey(const Key('registrationTerms')));
    await tester.tap(find.byKey(const Key('registrationTerms')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('registrationContinueButton')));
    await tester.pumpAndSettle();
  }

  testWidgets('validates account data before advancing', (tester) async {
    await pumpView(tester);

    await tester.tap(find.byKey(const Key('registrationContinueButton')));
    await tester.pump();

    expect(find.text('Informe seu nome e um e-mail válido.'), findsOneWidget);
    expect(find.text('ETAPA 1 DE 6'), findsOneWidget);
  });

  testWidgets('preserves data and validates instructor code', (tester) async {
    await pumpView(tester);
    await completeAccountStep(tester);
    expect(find.text('ETAPA 2 DE 6'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('registrationInstructorCode')),
      'abcd2345',
    );
    await tester.tap(find.byKey(const Key('registrationContinueButton')));
    await tester.pumpAndSettle();

    expect(find.text('ETAPA 3 DE 6'), findsOneWidget);
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('Marina'), findsOneWidget);
    final codeField = tester.widget<TextField>(
      find.byKey(const Key('registrationInstructorCode')),
    );
    expect(codeField.controller?.text, 'ABCD2345');
  });

  testWidgets('keeps None mutually exclusive in health selections', (
    tester,
  ) async {
    await pumpView(tester);
    await completeAccountStep(tester);
    await tester.enterText(
      find.byKey(const Key('registrationInstructorCode')),
      'ABCD2345',
    );
    await tester.tap(find.byKey(const Key('registrationContinueButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('registrationContinueButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('goal-conditioning')));
    await tester.tap(find.byKey(const Key('registrationContinueButton')));
    await tester.pumpAndSettle();

    final noneFinder = find.byKey(const Key('health-none-Nenhuma dor'));
    final kneeFinder = find.byKey(const Key('health-knee-Joelho'));
    expect(tester.widget<FilterChip>(noneFinder).selected, isTrue);

    await tester.tap(kneeFinder);
    await tester.pump();

    expect(tester.widget<FilterChip>(noneFinder).selected, isFalse);
    expect(tester.widget<FilterChip>(kneeFinder).selected, isTrue);
  });
}
