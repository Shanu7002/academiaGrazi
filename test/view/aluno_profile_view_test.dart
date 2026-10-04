import 'package:academiagrazi/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/users/register_user.dart';
import 'package:academiagrazi/view/user/aluno_profile_view.dart';

@GenerateMocks([RegisterUserService, FirebaseAuth, User])
import 'aluno_profile_view_test.mocks.dart';

void main() {
  late MockRegisterUserService mockUserService;
  late MockFirebaseAuth mockAuth;
  late MockUser mockFirebaseUser;

  setUp(() {
    locator.reset();
    locator.allowReassignment = true;

    mockUserService = MockRegisterUserService();
    mockAuth = MockFirebaseAuth();
    mockFirebaseUser = MockUser();

    locator.registerSingleton<RegisterUserService>(mockUserService);
    locator.registerSingleton<FirebaseAuth>(mockAuth);
  });

  testWidgets('AlunoProfileView renders user data properly', (
    WidgetTester tester,
  ) async {
    when(mockFirebaseUser.uid).thenReturn("uid_123");
    when(mockAuth.currentUser).thenReturn(mockFirebaseUser);

    final testUserModel = UserModel(
      id: 'uid_123',
      name: 'Test',
      email: 'test@example.com',
      responsable: 'resp_456',
    );

    final testResponsableModel = UserModel(
      id: 'resp_456',
      name: 'Prof. Marcos',
      email: 'marcos@example.com',
    );

    when(
      mockUserService.getUserById("uid_123"),
    ).thenAnswer((_) async => testUserModel);
    when(
      mockUserService.getResponsableData("resp_456"),
    ).thenAnswer((_) async => testResponsableModel);

    await tester.pumpWidget(MaterialApp(home: AlunoProfileView()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Test'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);

    verify(mockAuth.currentUser).called(1);
    verify(mockUserService.getUserById('uid_123')).called(1);
  });
}
