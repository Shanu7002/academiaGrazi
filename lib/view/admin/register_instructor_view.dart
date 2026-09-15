import 'package:flutter/material.dart';

import '../../controller/users/register_instructor.dart';
import '../../service/users/register.dart';
import '../model/register_model.dart';

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
        return RegisterInstructorController(
          RegisterService(),
        ).registerInstructor(
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
