import "package:academiagrazi/models/users/user_model.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mockito/mockito.dart";
import "package:mockito/annotations.dart";
import "package:academiagrazi/controller/users/register_user.dart";
import "package:academiagrazi/models/users/registration_profile.dart";
import "package:academiagrazi/service/users/register.dart";

@GenerateMocks([RegisterService, FirebaseAuth, UserCredential, User])
import "register_test.mocks.dart";

void main() {
  late MockRegisterService mockRegisterService;
  late MockFirebaseAuth mockAuth;
  late MockUserCredential mockCredential;
  late MockUser mockUser;
  late RegisterUserController controller;

  final instructorUser = UserModel(
    id: "instructor_uid",
    name: "Instructor",
    email: "instructor@test.com",
    type: UserType.instructor,
    responsable: 'test',
  );

  setUp(() {
    mockRegisterService = MockRegisterService();
    mockAuth = MockFirebaseAuth();
    mockCredential = MockUserCredential();
    mockUser = MockUser();

    controller = RegisterUserController(mockRegisterService, auth: mockAuth);
  });

  group("RegisterController Tests sucessfully", () {
    test("Should return true when Auth and DB insertion succeed", () async {
      when(mockUser.uid).thenReturn("fake_uid_777");
      when(mockCredential.user).thenReturn(mockUser);
      when(
        mockAuth.createUserWithEmailAndPassword(
          email: "test@test.com",
          password: "password123",
        ),
      ).thenAnswer((_) async => mockCredential);

      when(
        mockRegisterService.registerUser(any),
      ).thenAnswer((_) async => Future.value());

      final result = await controller.registerUser(
        currentUser: instructorUser,
        email: "test@test.com",
        name: "test",
        password: "password123",
        passwordCheck: "password123",
      );

      expect(result, isTrue);
      verify(
        mockAuth.createUserWithEmailAndPassword(
          email: "test@test.com",
          password: "password123",
        ),
      ).called(1);

      final capturedModel =
          verify(mockRegisterService.registerUser(captureAny)).captured.first
              as UserModel;
      expect(capturedModel.id, "fake_uid_777");
      expect(capturedModel.email, "test@test.com");
      expect(capturedModel.type, UserType.user);
    });

    test("Should return true and default to type user when omitted", () async {
      when(mockUser.uid).thenReturn("uid_777");
      when(mockCredential.user).thenReturn(mockUser);
      when(
        mockAuth.createUserWithEmailAndPassword(
          email: "test@test.com",
          password: "password123",
        ),
      ).thenAnswer((_) async => mockCredential);

      when(
        mockRegisterService.registerUser(any),
      ).thenAnswer((_) async => Future.value());

      final result = await controller.registerUser(
        currentUser: instructorUser,
        email: "test@test.com",
        name: "test",
        password: "password123",
        passwordCheck: "password123",
      );

      expect(result, isTrue);

      final capturedModel =
          verify(mockRegisterService.registerUser(captureAny)).captured.first
              as UserModel;
      expect(capturedModel.type, UserType.user);
    });
  });

  group("RegisterController Tests failed", () {
    test("Should return false immediately if passwords do not match", () async {
      final result = await controller.registerUser(
        currentUser: instructorUser,
        email: "test@test.com",
        name: "test",
        password: "password123",
        passwordCheck: "wrongpassword",
      );

      expect(result, isFalse);
      verifyNever(
        mockAuth.createUserWithEmailAndPassword(
          email: anyNamed("email"),
          password: anyNamed("password"),
        ),
      );
    });

    test("Should return false when FirebaseAuthException is thrown", () async {
      when(
        mockAuth.createUserWithEmailAndPassword(
          email: "test@test.com",
          password: "password123",
        ),
      ).thenThrow(FirebaseAuthException(code: "email-already-in-use"));

      final result = await controller.registerUser(
        currentUser: instructorUser,
        email: "test@test.com",
        name: "test",
        password: "password123",
        passwordCheck: "password123",
      );

      expect(result, isFalse);
      verifyNever(mockRegisterService.registerUser(any));
    });

    test("should return error if database is unreachable", () async {
      when(
        mockAuth.createUserWithEmailAndPassword(
          email: anyNamed("email"),
          password: anyNamed("password"),
        ),
      ).thenThrow(Exception("Internal server error"));

      final result = await controller.registerUser(
        currentUser: instructorUser,
        name: "test",
        email: "test@test.com",
        password: "password123",
        passwordCheck: "password123",
      );

      verify(
        mockAuth.createUserWithEmailAndPassword(
          email: anyNamed("email"),
          password: anyNamed("password"),
        ),
      ).called(1);

      expect(result, isFalse);
      verifyNever(mockRegisterService.registerUser(any));
    });
  });

  group('Self registration |', () {
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

    const codeInfo = InstructorCodeInfo(
      code: 'ABCD2345',
      instructorId: 'instructor_uid',
      instructorName: 'Instructor',
    );

    test('creates Auth and complete Firestore profile', () async {
      when(
        mockRegisterService.validateInstructorCode('ABCD2345'),
      ).thenAnswer((_) async => codeInfo);
      when(mockUser.uid).thenReturn('new-user');
      when(mockCredential.user).thenReturn(mockUser);
      when(
        mockAuth.createUserWithEmailAndPassword(
          email: 'aluna@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => mockCredential);
      when(mockRegisterService.registerUser(any)).thenAnswer((_) async {});

      final result = await controller.registerSelf(draft: validDraft());

      expect(result.status, SelfRegistrationStatus.success);
      final saved =
          verify(mockRegisterService.registerUser(captureAny)).captured.single
              as UserModel;
      expect(saved.responsable, 'instructor_uid');
      expect(saved.onboardingCompleted, isTrue);
      expect(saved.registrationProfile?.primaryGoal, PrimaryGoal.conditioning);
    });

    test('does not create Auth when instructor code is invalid', () async {
      when(
        mockRegisterService.validateInstructorCode('ABCD2345'),
      ).thenAnswer((_) async => null);

      final result = await controller.registerSelf(draft: validDraft());

      expect(result.status, SelfRegistrationStatus.invalidInstructorCode);
      verifyNever(
        mockAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      );
    });

    test('deletes Auth user when Firestore persistence fails', () async {
      when(
        mockRegisterService.validateInstructorCode('ABCD2345'),
      ).thenAnswer((_) async => codeInfo);
      when(mockUser.uid).thenReturn('new-user');
      when(mockCredential.user).thenReturn(mockUser);
      when(
        mockAuth.createUserWithEmailAndPassword(
          email: 'aluna@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => mockCredential);
      when(
        mockRegisterService.registerUser(any),
      ).thenThrow(Exception('Firestore unavailable'));
      when(mockUser.delete()).thenAnswer((_) async {});

      final result = await controller.registerSelf(draft: validDraft());

      expect(result.status, SelfRegistrationStatus.persistenceError);
      verify(mockUser.delete()).called(1);
    });
  });
}
