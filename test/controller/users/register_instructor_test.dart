import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/controller/users/register_instructor.dart';
import 'package:academiagrazi/service/users/register_instructor.dart';

@GenerateMocks([RegisterInstructorService, FirebaseAuth, UserCredential, User])
import 'register_instructor_test.mocks.dart';

void main() {
  late MockRegisterInstructorService mockRegisterInstructorService;
  late MockFirebaseAuth mockAuth;
  late MockUserCredential mockCredential;
  late MockUser mockUser;
  late RegisterInstructorController controller;

  setUp(() {
    mockRegisterInstructorService = MockRegisterInstructorService();
    mockAuth = MockFirebaseAuth();
    mockCredential = MockUserCredential();
    mockUser = MockUser();

    controller = RegisterInstructorController(
      mockRegisterInstructorService,
      auth: mockAuth,
    );
  });

  group('Instructor Registration |', () {
    test(
      'creates Auth and complete Firestore profile for Instructor',
      () async {
        final mockAdminUser = UserModel(
          id: 'admin_123',
          name: 'Admin',
          email: 'admin@nseioqnaoseioqla.com',
          type: UserType.admin,
        );

        when(mockUser.uid).thenReturn('new-instructor-789');
        when(mockCredential.user).thenReturn(mockUser);
        when(
          mockAuth.createUserWithEmailAndPassword(
            email: 'marina@example.com',
            password: 'password123',
          ),
        ).thenAnswer((_) async => mockCredential);

        when(
          mockRegisterInstructorService.registerInstructor(any),
        ).thenAnswer((_) async => 'success');

        final success = await controller.registerInstructor(
          currentUser: mockAdminUser,
          email: 'marina@example.com',
          name: 'Marina',
          password: 'password123',
          passwordCheck: 'password123',
        );

        expect(success, isTrue);

        final savedInstructor =
            verify(
                  mockRegisterInstructorService.registerInstructor(captureAny),
                ).captured.single
                as UserModel;

        expect(savedInstructor.id, 'new-instructor-789');
        expect(savedInstructor.name, 'Marina');
        expect(savedInstructor.email, 'marina@example.com');
        expect(savedInstructor.type, UserType.instructor);
        expect(savedInstructor.responsable, 'admin_123');
      },
    );

    test('aborts registration if passwords do not match', () async {
      final mockAdminUser = UserModel(
        id: 'admin_123',
        name: 'Admin',
        email: 'admin@nseioqnaoseioqla.com',
      );

      final success = await controller.registerInstructor(
        currentUser: mockAdminUser,
        email: 'marina@example.com',
        name: 'Marina',
        password: 'password123',
        passwordCheck: 'wrong_password',
      );

      expect(success, isFalse);
      verifyNever(
        mockAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      );
    });
  });
}
