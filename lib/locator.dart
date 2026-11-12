import 'package:academiagrazi/controller/teachers/teacher_user_searcher.dart';
import 'package:academiagrazi/controller/users/update_data.dart';
import 'package:academiagrazi/service/admin/admin_dashboard.dart';
import 'package:academiagrazi/service/admin/admin_student_service.dart';
import 'package:academiagrazi/service/evaluations/physical_evaluation_service.dart';
import 'package:academiagrazi/service/training/exercise_catalog_service.dart';
import 'package:academiagrazi/service/training/home_workout_service.dart';
import 'package:academiagrazi/service/training/student_training_view_data_service.dart';
import 'package:academiagrazi/service/training/training_plan_service.dart';
import 'package:academiagrazi/service/training/training_session_service.dart';
import 'package:academiagrazi/service/units/gym_class_service.dart';
import 'package:academiagrazi/service/units/instructor_shift_service.dart';
import 'package:academiagrazi/service/units/unit_service.dart';
import 'package:academiagrazi/service/users/register_instructor.dart';
import 'package:academiagrazi/view/preferences_service.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:academiagrazi/service/users/register_user.dart';
import 'package:academiagrazi/service/users/login.dart';
import 'package:academiagrazi/service/users/profile_photo.dart';
import 'package:academiagrazi/controller/users/login.dart';
import 'package:academiagrazi/controller/users/register_user.dart';
import 'package:academiagrazi/controller/users/register_instructor.dart';

final locator = GetIt.instance;

Future<void> setupLocator() async {
  // Preferences
  final prefsService = PreferencesService();
  await prefsService.init();
  locator.registerSingleton<PreferencesService>(prefsService);

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

  // Profile photo
  locator.registerLazySingleton<ProfilePhotoService>(
    () => ProfilePhotoService(),
  );

  // Teacher
  locator.registerLazySingleton<TeacherUserSearcher>(
    () => TeacherUserSearcher(),
  );

  // Physical evaluations
  locator.registerLazySingleton<PhysicalEvaluationService>(
    () => PhysicalEvaluationService(),
  );

  // Training (fichas, sessões e treino em casa do aluno)
  locator.registerLazySingleton<ExerciseCatalogService>(
    () => ExerciseCatalogService(),
  );
  locator.registerLazySingleton<TrainingPlanService>(
    () => TrainingPlanService(),
  );
  locator.registerLazySingleton<TrainingSessionService>(
    () => TrainingSessionService(planService: locator<TrainingPlanService>()),
  );
  locator.registerLazySingleton<HomeWorkoutService>(() => HomeWorkoutService());
  locator.registerLazySingleton<StudentTrainingViewDataService>(
    () => StudentTrainingViewDataService(
      planService: locator<TrainingPlanService>(),
      userService: locator<RegisterUserService>(),
      catalogService: locator<ExerciseCatalogService>(),
    ),
  );

  // Units and instructor schedule
  locator.registerLazySingleton<UnitService>(() => UnitService());
  locator.registerLazySingleton<InstructorShiftService>(
    () => InstructorShiftService(),
  );
  locator.registerLazySingleton<GymClassService>(() => GymClassService());

  // Update data
  locator.registerLazySingleton<UpdateDataController>(
    () => UpdateDataController(),
  );

  // Instructor register
  locator.registerLazySingleton<RegisterInstructorController>(
    () => RegisterInstructorController(locator<RegisterInstructorService>()),
  );
  locator.registerLazySingleton<RegisterInstructorService>(
    () => RegisterInstructorService(),
  );

  // Admin dashboard
  locator.registerLazySingleton<AdminDashboardService>(
    () => AdminDashboardService(),
  );
  locator.registerLazySingleton<AdminStudentService>(
    () => AdminStudentService(),
  );

  // Login
  locator.registerLazySingleton<LoginController>(
    () => LoginController(locator<LoginService>()),
  );
  locator.registerLazySingleton<LoginService>(() => LoginService());
}
