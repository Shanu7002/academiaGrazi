import "dart:developer";
import "package:academiagrazi/auth/permissions.dart";
import "package:academiagrazi/models/users/user_model.dart";
import "package:academiagrazi/service/users/register.dart";
import "package:firebase_auth/firebase_auth.dart";

class RegisterUserController {
  final FirebaseAuth _auth;
  final RegisterService _userService;

  // coverage:ignore-start
  RegisterUserController(this._userService, {FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;
  // coverage:ignore-end

  Future<bool> registerUser({
    required UserModel currentUser,
    required String email,
    required String name,
    required String password,
    required String passwordCheck,
  }) async {
    if (!Permissions.canCreateUser(currentUser)) {
      return false;
    }
    try {
      if (password != passwordCheck) {
        return false;
      }

      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final String generatedUid = credential.user!.uid;

      final userModel = UserModel(
        id: generatedUid,
        name: name,
        email: email,
        type: UserType.user,
      );

      await _userService.registerUser(userModel);

      return true;
    } on FirebaseAuthException catch (e) {
      log("Error occurred in register", error: e);
      return false;
    } on Exception catch (e) {
      log("Generic error occurred in register", error: e);
      return false;
    }
  }
}
