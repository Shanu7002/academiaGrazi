import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/models/users/registration_profile.dart';
import 'package:academiagrazi/controller/users/register_user.dart';
import 'package:academiagrazi/service/users/register_user.dart';
import 'package:academiagrazi/service/users/register_instructor.dart';

@GenerateMocks([
  RegisterUserService,
  RegisterInstructorService,
  FirebaseAuth,
  UserCredential,
  User,
])
import 'register_user_test.mocks.dart';

void main() {
  late MockRegisterUserService mockRegisterUserService;
  late MockRegisterInstructorService mockRegisterInstructorService;
  late MockFirebaseAuth mockAuth;
  late MockUserCredential mockCredential;
  late MockUser mockUser;
  late RegisterUserController controller;

  setUp(() {
    mockRegisterUserService = MockRegisterUserService();
    mockRegisterInstructorService = MockRegisterInstructorService();
    mockAuth = MockFirebaseAuth();
    mockCredential = MockUserCredential();
    mockUser = MockUser();

    controller = RegisterUserController(
      mockRegisterUserService,
      mockRegisterInstructorService,
      auth: mockAuth,
    );
  });

  group('User Self Registration |', () {
    RegistrationDraft validDraft() {
      return RegistrationDraft()
        ..name = 'Aluna Teste'
        ..email = 'aluna@example.com'
        ..password = 'password123'
        ..passwordConfirmation = 'password123'
        ..termsAcceptedAt = DateTime.utc(2026, 9, 29)
        ..instructorCode = 'ABCD2345'
        ..primaryGoal = PrimaryGoal.conditioning
        ..emergencyName = 'Contato'
        ..emergencyRelationship = 'friend'
        ..emergencyPhone = '11999999999';
    }

    test('creates Auth and complete Firestore profile', () async {
      when(mockUser.uid).thenReturn('new-user-123');
      when(mockCredential.user).thenReturn(mockUser);
      when(
        mockAuth.createUserWithEmailAndPassword(
          email: 'aluna@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => mockCredential);

      when(mockRegisterUserService.registerUser(any)).thenAnswer((_) async {});

      final result = await controller.registerUser(
        draft: validDraft(),
        instructorId: 'instructor_uid_456',
      );

      expect(result.status, SelfRegistrationStatus.success);

      final savedUser =
          verify(
                mockRegisterUserService.registerUser(captureAny),
              ).captured.single
              as UserModel;

      expect(savedUser.id, 'new-user-123');
      expect(savedUser.type, UserType.user);
      expect(savedUser.responsable, 'instructor_uid_456');
      expect(savedUser.onboardingCompleted, isTrue);
      expect(
        savedUser.registrationProfile?.primaryGoal,
        PrimaryGoal.conditioning,
      );
    });

    test(
      'executes compensating transaction (deletes Auth) when Firestore fails',
      () async {
        when(mockUser.uid).thenReturn('new-user-123');
        when(mockCredential.user).thenReturn(mockUser);
        when(
          mockAuth.createUserWithEmailAndPassword(
            email: 'aluna@example.com',
            password: 'password123',
          ),
        ).thenAnswer((_) async => mockCredential);

        when(
          mockRegisterUserService.registerUser(any),
        ).thenThrow(Exception('Firestore unavailable'));
        when(mockUser.delete()).thenAnswer((_) async {});

        final result = await controller.registerUser(
          draft: validDraft(),
          instructorId: 'instructor_uid_456',
        );

        expect(result.status, SelfRegistrationStatus.persistenceError);

        verify(mockUser.delete()).called(1);
      },
    );
  });
}
