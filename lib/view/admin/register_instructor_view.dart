import 'package:flutter/material.dart';
import 'package:academiagrazi/locator.dart';
import '../../controller/users/register_instructor.dart';
import '../model/register_mod.dart';

class RegisterInstructorView extends StatelessWidget {
  const RegisterInstructorView({super.key});

  @override
  Widget build(BuildContext context) {
    return RegisterView(
      registerFunction: ({
        required currentUser,
        required email,
        required name,
        required password,
        required passwordCheck,
      }) {
        return locator<RegisterInstructorController>().registerInstructor(
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
