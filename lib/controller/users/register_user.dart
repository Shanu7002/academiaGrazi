import "dart:developer";
import "package:academiagrazi/models/users/user_model.dart";
import "package:academiagrazi/models/users/registration_profile.dart";
import "package:academiagrazi/service/users/register.dart";
import "package:firebase_auth/firebase_auth.dart";

enum SelfRegistrationStatus {
  success,
  invalidData,
  invalidInstructorCode,
  emailAlreadyInUse,
  weakPassword,
  networkError,
  persistenceError,
}

class SelfRegistrationResult {
  final SelfRegistrationStatus status;
  final UserModel? user;

  const SelfRegistrationResult(this.status, {this.user});

  bool get isSuccess => status == SelfRegistrationStatus.success;
}

class RegisterUserController {
  final FirebaseAuth _auth;
  final RegisterService _userService;

  // coverage:ignore-start
  RegisterUserController(this._userService, {FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;
  // coverage:ignore-end
  Future<InstructorCodeInfo?> validateInstructorCode(String code) {
    return _userService.validateInstructorCode(code);
  }

  Future<SelfRegistrationResult> registerSelf({
    required RegistrationDraft draft,
  }) async {
    if (draft.name.trim().isEmpty ||
        draft.email.trim().isEmpty ||
        draft.password.length < 8 ||
        draft.password != draft.passwordConfirmation ||
        draft.termsAcceptedAt == null ||
        draft.primaryGoal == null) {
      return const SelfRegistrationResult(SelfRegistrationStatus.invalidData);
    }

    User? createdUser;
    try {
      final codeInfo = await _userService.validateInstructorCode(
        draft.instructorCode,
      );
      if (codeInfo == null) {
        return const SelfRegistrationResult(
          SelfRegistrationStatus.invalidInstructorCode,
        );
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: draft.email.trim(),
        password: draft.password,
      );
      createdUser = credential.user;
      if (createdUser == null) {
        return const SelfRegistrationResult(
          SelfRegistrationStatus.persistenceError,
        );
      }

      final userModel = UserModel(
        id: createdUser.uid,
        name: draft.name.trim(),
        email: draft.email.trim(),
        type: UserType.user,
        responsable: codeInfo.instructorId,
        registrationProfile: draft.toProfile(),
        onboardingCompleted: true,
        termsAcceptedAt: draft.termsAcceptedAt,
      );
      await _userService.registerUser(userModel);

      return SelfRegistrationResult(
        SelfRegistrationStatus.success,
        user: userModel,
      );
    } on FirebaseAuthException catch (error) {
      return SelfRegistrationResult(_authErrorStatus(error.code));
    } on FirebaseException catch (error) {
      await _rollbackCreatedUser(createdUser);
      final isNetworkError =
          error.code == 'network-request-failed' ||
          error.code == 'unavailable' ||
          error.code == 'deadline-exceeded';
      return SelfRegistrationResult(
        isNetworkError
            ? SelfRegistrationStatus.networkError
            : SelfRegistrationStatus.persistenceError,
      );
    } on Exception catch (error) {
      log("Generic error occurred in self registration", error: error);
      await _rollbackCreatedUser(createdUser);
      return const SelfRegistrationResult(
        SelfRegistrationStatus.persistenceError,
      );
    }
  }

  SelfRegistrationStatus _authErrorStatus(String code) {
    switch (code) {
      case 'email-already-in-use':
        return SelfRegistrationStatus.emailAlreadyInUse;
      case 'weak-password':
        return SelfRegistrationStatus.weakPassword;
      case 'network-request-failed':
        return SelfRegistrationStatus.networkError;
      default:
        return SelfRegistrationStatus.persistenceError;
    }
  }

  Future<void> _rollbackCreatedUser(User? user) async {
    if (user == null) return;
    try {
      await user.delete();
    } on Exception catch (error) {
      log("Unable to roll back Auth user", error: error);
      await _auth.signOut();
    }
  }
}
