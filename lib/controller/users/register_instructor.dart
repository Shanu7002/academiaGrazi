import "package:academiagrazi/auth/permissions.dart";
import "package:academiagrazi/firebase_options.dart";
import "package:academiagrazi/models/users/user_model.dart";
import "package:academiagrazi/service/users/register_instructor.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_core/firebase_core.dart";
import "package:flutter/foundation.dart";

enum InstructorRegistrationResult {
  success,
  notAllowed,
  passwordMismatch,
  emailInUse,
  invalidEmail,
  weakPassword,
  networkError,
  permissionDenied,
  unknown,
}

class RegisterInstructorController {
  // Nome do app Firebase secundário usado só para criar contas de professor.
  static const String _registrationAppName = 'instructorRegistration';

  final RegisterInstructorService _userService;
  final Future<FirebaseAuth> Function() _registrationAuth;

  // coverage:ignore-start
  RegisterInstructorController(this._userService, {FirebaseAuth? auth})
    : _registrationAuth =
          auth != null ? (() async => auth) : _secondaryRegistrationAuth;

  /// O createUserWithEmailAndPassword loga automaticamente na conta criada.
  /// Usando uma instância secundária do Firebase, a sessão do admin no app
  /// principal continua intacta.
  static Future<FirebaseAuth> _secondaryRegistrationAuth() async {
    final app =
        Firebase.apps.any((app) => app.name == _registrationAppName)
            ? Firebase.app(_registrationAppName)
            : await Firebase.initializeApp(
              name: _registrationAppName,
              options: DefaultFirebaseOptions.currentPlatform,
            );
    return FirebaseAuth.instanceFor(app: app);
  }
  // coverage:ignore-end

  Future<InstructorRegistrationResult> registerInstructor({
    required UserModel currentUser,
    required String email,
    required String name,
    required String password,
    required String passwordCheck,
  }) async {
    if (!Permissions.canCreateInstructor(currentUser)) {
      return InstructorRegistrationResult.notAllowed;
    }

    if (password != passwordCheck) {
      return InstructorRegistrationResult.passwordMismatch;
    }

    FirebaseAuth? auth;
    User? createdUser;

    try {
      auth = await _registrationAuth();

      final UserCredential credential = await auth
          .createUserWithEmailAndPassword(email: email, password: password);

      createdUser = credential.user!;

      final userModel = UserModel(
        id: createdUser.uid,
        name: name,
        email: email,
        type: UserType.instructor,
        responsable: currentUser.id,
      );

      // A gravação usa o Firestore principal, autenticado como o admin.
      await _userService.registerInstructor(userModel);

      return InstructorRegistrationResult.success;
    } on FirebaseAuthException catch (e) {
      debugPrint("[RegisterInstructor] Auth error: ${e.code} ${e.message}");
      await _rollback(createdUser);
      return _fromAuthCode(e.code);
    } on FirebaseException catch (e) {
      debugPrint(
        "[RegisterInstructor] Firebase error (${e.plugin}): "
        "${e.code} ${e.message}",
      );
      await _rollback(createdUser);
      return e.code == 'permission-denied'
          ? InstructorRegistrationResult.permissionDenied
          : InstructorRegistrationResult.unknown;
    } catch (e) {
      debugPrint("[RegisterInstructor] Unexpected error: $e");
      await _rollback(createdUser);
      return InstructorRegistrationResult.unknown;
    } finally {
      await auth?.signOut();
    }
  }

  static InstructorRegistrationResult _fromAuthCode(String code) {
    switch (code) {
      case 'email-already-in-use':
        return InstructorRegistrationResult.emailInUse;
      case 'invalid-email':
        return InstructorRegistrationResult.invalidEmail;
      case 'weak-password':
        return InstructorRegistrationResult.weakPassword;
      case 'network-request-failed':
        return InstructorRegistrationResult.networkError;
      default:
        return InstructorRegistrationResult.unknown;
    }
  }

  /// Remove a conta do Auth se o perfil não pôde ser gravado no Firestore,
  /// para o e-mail não ficar preso sem cadastro.
  Future<void> _rollback(User? createdUser) async {
    if (createdUser == null) return;
    try {
      await createdUser.delete();
    } catch (e) {
      debugPrint("[RegisterInstructor] Could not rollback auth account: $e");
    }
  }
}
