import 'package:flutter/material.dart';

import '../../controller/users/register_user.dart';
import '../../service/users/register.dart';
import '../model/register_model.dart';

class RegisterUserView extends StatelessWidget {
  const RegisterUserView({super.key});

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
        return RegisterUserController(RegisterService()).registerUser(
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
