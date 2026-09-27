import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../controller/users/register_instructor.dart';
import '../../service/users/register.dart';
import '../model/register_mod.dart';

class RegisterInstructorView extends StatelessWidget {
  final RegisterInstructorController controller;
  final RegisterService userService;
  final FirebaseAuth authInstance;

  const RegisterInstructorView({
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
        return controller.registerInstructor(
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
