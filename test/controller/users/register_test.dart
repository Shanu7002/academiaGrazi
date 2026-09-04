import 'package:academiagrazi/models/users/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:academiagrazi/controller/users/register.dart';
import 'package:academiagrazi/service/users/register.dart';

@GenerateMocks([UserService, FirebaseAuth, UserCredential, User])
import 'register_test.mocks.dart';

void main() {
  late MockUserService mockUserService;
  late MockFirebaseAuth mockAuth;
  late MockUserCredential mockCredential;
  late MockUser mockUser;
  late RegisterController controller;

  setUp(() {
    mockUserService = MockUserService();
    mockAuth = MockFirebaseAuth();
    mockCredential = MockUserCredential();
    mockUser = MockUser();

    controller = RegisterController(mockUserService, auth: mockAuth);
  });

  group('RegisterController Tests |', () {
    test(
      'Should return false immediately if passwords do not match in O(1) time',
      () async {
        final result = await controller.registerUser(
          'test@test.com',
          'test',
          'password123',
          'wrongpassword',
        );

        expect(result, isFalse);
        verifyNever(
          mockAuth.createUserWithEmailAndPassword(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        );
      },
    );

    test('Should return true when Auth and DB insertion succeed', () async {
      when(mockUser.uid).thenReturn('fake_uid_777');
      when(mockCredential.user).thenReturn(mockUser);
      when(
        mockAuth.createUserWithEmailAndPassword(
          email: 'test@test.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => mockCredential);

      when(
        mockUserService.registerUser(any),
      ).thenAnswer((_) async => Future.value());

      final result = await controller.registerUser(
        'test@test.com',
        'test',
        'password123',
        'password123',
      );

      expect(result, isTrue);
      verify(
        mockAuth.createUserWithEmailAndPassword(
          email: 'test@test.com',
          password: 'password123',
        ),
      ).called(1);

      final capturedModel =
          verify(mockUserService.registerUser(captureAny)).captured.first
              as UserModel;
      expect(capturedModel.id, 'fake_uid_777');
      expect(capturedModel.email, 'test@test.com');
      expect(capturedModel.type, UserType.user);
    });

    test('Should return false when FirebaseAuthException is thrown', () async {
      when(
        mockAuth.createUserWithEmailAndPassword(
          email: 'test@test.com',
          password: 'password123',
        ),
      ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      final result = await controller.registerUser(
        'test@test.com',
        'test',
        'password123',
        'password123',
      );

      expect(result, isFalse);
      verifyNever(mockUserService.registerUser(any));
    });
  });
}
