import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../controller/users/register_user.dart';
import '../../service/users/register.dart';
import '../model/register_mod.dart';

class RegisterUserView extends StatelessWidget {
  final RegisterUserController controller;
  final RegisterService userService;
  final FirebaseAuth authInstance;

  const RegisterUserView({
    super.key,
    required this.controller,
    required this.userService,
    required this.authInstance,
  });

  @override
  Widget build(BuildContext context) {
    return RegisterView(
      userService: userService,
      authInstance: authInstance,
      registerFunction: ({
        required currentUser,
        required email,
        required name,
        required password,
        required passwordCheck,
      }) {
        return controller.registerUser(
          currentUser: currentUser,
          email: email,
          name: name,
          password: password,
          passwordCheck: passwordCheck,
        );
      },
    );
  }
}
