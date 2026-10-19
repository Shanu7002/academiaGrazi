import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/users/register_user.dart';
import 'package:academiagrazi/view/admin/register_instructor_view.dart';
import 'package:academiagrazi/view/tab_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/view/welcome_view.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = locator<FirebaseAuth>();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authSnapshot.hasData) {
          final currentUid = authSnapshot.data!.uid;

          return FutureBuilder<UserType>(
            future: locator<RegisterUserService>().getUserRole(currentUid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (roleSnapshot.hasError) {
                return const Scaffold(
                  body: Center(child: Text('Authentication Error')),
                );
              }

              final type = roleSnapshot.data;

              if (type == UserType.user) {
                return const MainShell();
              } else if (type == UserType.instructor) {
                return const MainShell();
              } else {
                return const RegisterInstructorView();
              }
            },
          );
        }

        return const WelcomeView();
      },
    );
  }
}
