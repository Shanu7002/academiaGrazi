import "package:academiagrazi/controller/users/login.dart";
import "package:academiagrazi/models/users/user_model.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mockito/annotations.dart";
import "package:academiagrazi/service/users/login.dart";
import "package:mockito/mockito.dart";

@GenerateMocks([LoginService, FirebaseAuth, UserCredential, User])
import "login_test.mocks.dart";

void main() {
  late MockLoginService mockLoginService;
  late MockFirebaseAuth mockAuth;
  late MockUserCredential mockCredential;
  late MockUser mockUser;
  late LoginController controller;

  const id = "fake_uid_777";
  const name = "test";
  const email = "test@test.com";
  const password = "password123";

  setUp(() {
    mockLoginService = MockLoginService();
    mockAuth = MockFirebaseAuth();
    mockCredential = MockUserCredential();
    mockUser = MockUser();

    controller = LoginController(mockLoginService, auth: mockAuth);

    when(mockUser.uid).thenReturn(id);
    when(mockCredential.user).thenReturn(mockUser);

    when(
      mockAuth.signInWithEmailAndPassword(email: email, password: password),
    ).thenAnswer((_) async => mockCredential);
  });

  group("LoginController Tests sucessfully", () {
    test("Should return the user when credentials are valid", () async {
      final userModel = UserModel(id: id, name: name, email: email);

      when(
        mockLoginService.getUserProfile(id),
      ).thenAnswer((_) async => userModel);

      final result = await controller.loginUser(
        email: email,
        password: password,
      );

      verify(
        mockAuth.signInWithEmailAndPassword(email: email, password: password),
      ).called(1);

      verify(mockLoginService.getUserProfile(id)).called(1);

      expect(result?.id, id);
      expect(result?.name, name);
      expect(result?.email, email);
      expect(result?.type, UserType.user);
    });

    test(
      "Should return the user when credentials are valid for admin login",
      () async {
        final userModel = UserModel(
          id: id,
          name: name,
          email: email,
          type: UserType.admin,
        );

        when(
          mockLoginService.getUserProfile(id),
        ).thenAnswer((_) async => userModel);

        final result = await controller.loginUser(
          email: email,
          password: password,
        );

        verify(
          mockAuth.signInWithEmailAndPassword(email: email, password: password),
        ).called(1);

        verify(mockLoginService.getUserProfile(id)).called(1);

        expect(result?.id, id);
        expect(result?.name, name);
        expect(result?.email, email);
        expect(result?.type, UserType.admin);
      },
    );

    test(
      "Should return the user when credentials are valid for professor login",
      () async {
        final userModel = UserModel(
          id: id,
          name: name,
          email: email,
          type: UserType.professor,
        );

        when(
          mockLoginService.getUserProfile(id),
        ).thenAnswer((_) async => userModel);

        final result = await controller.loginUser(
          email: email,
          password: password,
        );

        verify(
          mockAuth.signInWithEmailAndPassword(email: email, password: password),
        ).called(1);

        verify(mockLoginService.getUserProfile(id)).called(1);

        expect(result?.id, id);
        expect(result?.name, name);
        expect(result?.email, email);
        expect(result?.type, UserType.professor);
      },
    );
  });

  group("LoginController Tests failed", () {
    test("Should return null with error when email invalid", () async {
      when(
        mockAuth.signInWithEmailAndPassword(
          email: anyNamed("email"),
          password: anyNamed("password"),
        ),
      ).thenThrow(FirebaseAuthException(code: "invalid-credentials"));

      final result = await controller.loginUser(
        email: "wrongEmail@test.com",
        password: password,
      );

      expect(result, isNull);

      verify(
        mockAuth.signInWithEmailAndPassword(
          email: "wrongEmail@test.com",
          password: password,
        ),
      ).called(1);

      verifyNever(mockLoginService.getUserProfile(any));
    });

    test("Should return null with error when password invalid", () async {
      when(
        mockAuth.signInWithEmailAndPassword(
          email: anyNamed("email"),
          password: anyNamed("password"),
        ),
      ).thenThrow(FirebaseAuthException(code: "invalid-credentials"));

      final result = await controller.loginUser(
        email: email,
        password: "wrongPassword",
      );

      expect(result, isNull);

      verify(
        mockAuth.signInWithEmailAndPassword(
          email: email,
          password: "wrongPassword",
        ),
      ).called(1);

      verifyNever(mockLoginService.getUserProfile(any));
    });

    test("Should return null with generic when server has problems", () async {
      when(
        mockAuth.signInWithEmailAndPassword(
          email: anyNamed("email"),
          password: anyNamed("password"),
        ),
      ).thenThrow(Exception("Internal Server Error"));

      final result = await controller.loginUser(
        email: email,
        password: password,
      );

      expect(result, isNull);

      verify(
        mockAuth.signInWithEmailAndPassword(email: email, password: password),
      ).called(1);

      verifyNever(mockLoginService.getUserProfile(any));
    });
  });
}
