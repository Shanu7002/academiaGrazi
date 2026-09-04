import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/users/register.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterController {
  final FirebaseAuth _auth;
  final UserService _userService;

  RegisterController(this._userService, {FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  Future<bool> registerUser({
    required String email,
    required String name,
    required String password,
    required String passwordCheck,
    UserType type = UserType.user,
  }) async {
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
        type: type,
      );

      await _userService.registerUser(userModel);

      return true;
    } on FirebaseAuthException catch (e) {
      return false;
    }
  }
}
