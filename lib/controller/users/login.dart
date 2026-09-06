import 'dart:developer';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:academiagrazi/service/users/login.dart';

class LoginController {
  final FirebaseAuth _auth;
  final LoginService _userService;

  LoginController(this._userService, {FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  Future<UserModel?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = credential.user!.uid;

      final UserModel? userProfile = await _userService.getUserProfile(uid);

      if (userProfile == null) {
        log("User auth without database record");
      }

      return userProfile;
    } on FirebaseAuthException catch (e) {
      log('Error occurred in login', error: e);
      return null;
    }
  }
}
