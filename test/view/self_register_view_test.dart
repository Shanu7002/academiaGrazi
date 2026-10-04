import 'package:academiagrazi/controller/users/register_user.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/users/register_user.dart';
import 'package:academiagrazi/service/users/register_instructor.dart';
import 'package:academiagrazi/view/user/self_register_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([
  RegisterUserService,
  RegisterUserController,
  RegisterInstructorService,
  FirebaseAuth,
  User,
])
import 'self_register_view_test.mocks.dart';

void main() {
  late MockRegisterUserService mockUserService;
  late MockRegisterUserController mockUserController;
  late MockRegisterInstructorService mockInstructorService;
  late MockFirebaseAuth mockAuth;

  setUp(() async {
    locator.reset();
    locator.allowReassignment = true;

    mockUserService = MockRegisterUserService();
    mockUserController = MockRegisterUserController();
    mockInstructorService = MockRegisterInstructorService();
    mockAuth = MockFirebaseAuth();

    locator.registerSingleton<RegisterUserService>(mockUserService);
    locator.registerSingleton<RegisterUserController>(mockUserController);
    locator.registerSingleton<RegisterInstructorService>(mockInstructorService);
    locator.registerSingleton<FirebaseAuth>(mockAuth);

    when(mockUserController.validateInstructorCode('ABCD2345')).thenAnswer(
      (_) async => InstructorCodeInfo(
        code: 'ABCD2345',
        instructorId: '123',
        instructorName: 'Marina',
      ),
    );
  });

  tearDown(() {
    locator.reset();
  });

  // helpers

  Future<void> pumpView(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: SelfRegisterView()));
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

    await tester.ensureVisible(
      find.byKey(const Key('registrationContinueButton')),
    );
    await tester.tap(find.byKey(const Key('registrationContinueButton')));
    await tester.pumpAndSettle();
  }

  Future<void> completeInstructorStep(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('registrationInstructorCode')),
      'ABCD2345',
    );

    await tester.ensureVisible(
      find.byKey(const Key('registrationContinueButton')),
    );
    await tester.tap(find.byKey(const Key('registrationContinueButton')));
    await tester.pumpAndSettle();
  }

  Future<void> completePersonalDataStep(WidgetTester tester) async {
    await tester.ensureVisible(
      find.byKey(const Key('registrationContinueButton')),
    );
    await tester.tap(find.byKey(const Key('registrationContinueButton')));
    await tester.pumpAndSettle();
  }

  Future<void> completeGoalsStep(WidgetTester tester) async {
    final goalChip = find.byKey(const Key('goal-conditioning'));
    await tester.ensureVisible(goalChip);
    await tester.tap(goalChip);
    await tester.pump();

    await tester.ensureVisible(
      find.byKey(const Key('registrationContinueButton')),
    );
    await tester.tap(find.byKey(const Key('registrationContinueButton')));
    await tester.pumpAndSettle();
  }

  // actual tests

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
      'ABCD2345',
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
    await completeInstructorStep(tester);
    await completePersonalDataStep(tester);
    await completeGoalsStep(tester);

    final noneFinder = find.byKey(const Key('health-none-Nenhuma dor'));
    final kneeFinder = find.byKey(const Key('health-knee-Joelho'));

    await tester.ensureVisible(noneFinder);
    expect(tester.widget<FilterChip>(noneFinder).selected, isTrue);

    await tester.ensureVisible(kneeFinder);
    await tester.tap(kneeFinder);
    await tester.pump();

    expect(tester.widget<FilterChip>(noneFinder).selected, isFalse);
    expect(tester.widget<FilterChip>(kneeFinder).selected, isTrue);
  });
}
