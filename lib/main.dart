import 'package:academiagrazi/controller/users/login.dart';
import 'package:academiagrazi/controller/users/register_instructor.dart';
import 'package:academiagrazi/controller/users/register_user.dart';
import 'package:academiagrazi/service/users/login.dart';
import 'package:academiagrazi/service/users/register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'view/welcome_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final authInstance = FirebaseAuth.instance;
  final userService = RegisterService();
  final loginService = LoginService();

  final loginController = LoginController(loginService);
  final registerUserController = RegisterUserController(userService);
  final registerInstructorController = RegisterInstructorController(
    userService,
  );

  runApp(
    MyApp(
      authInstance: authInstance,
      userService: userService,
      loginController: loginController,
      registerUserController: registerUserController,
      registerInstructorController: registerInstructorController,
    ),
  );
}

class MyApp extends StatelessWidget {
  final LoginController loginController;
  final RegisterUserController registerUserController;
  final RegisterInstructorController registerInstructorController;
  final RegisterService userService;
  final FirebaseAuth authInstance;

  const MyApp({
    super.key,
    required this.loginController,
    required this.registerUserController,
    required this.registerInstructorController,
    required this.userService,
    required this.authInstance,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academia Grazi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        textTheme: GoogleFonts.barlowCondensedTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: WelcomeView(
        loginController: loginController,
        registerUserController: registerUserController,
        registerInstructorController: registerInstructorController,
        userService: userService,
        authInstance: authInstance,
      ),
    );
  }
}
