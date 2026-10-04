import 'package:academiagrazi/service/users/register_instructor.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:academiagrazi/service/users/register_user.dart';
import 'package:academiagrazi/service/users/login.dart';
import 'package:academiagrazi/controller/users/login.dart';
import 'package:academiagrazi/controller/users/register_user.dart';
import 'package:academiagrazi/controller/users/register_instructor.dart';

final locator = GetIt.instance;

void setupLocator() {
  // Core Services
  locator.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);

  // User register
  locator.registerLazySingleton<RegisterUserController>(
    () => RegisterUserController(
      locator<RegisterUserService>(),
      locator<RegisterInstructorService>(),
    ),
  );
  locator.registerLazySingleton<RegisterUserService>(
    () => RegisterUserService(),
  );

  // Instructor register
  locator.registerLazySingleton<RegisterInstructorController>(
    () => RegisterInstructorController(locator<RegisterInstructorService>()),
  );
  locator.registerLazySingleton<RegisterInstructorService>(
    () => RegisterInstructorService(),
  );

  // Login
  locator.registerLazySingleton<LoginController>(
    () => LoginController(locator<LoginService>()),
  );
  locator.registerLazySingleton<LoginService>(() => LoginService());
}
