import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'src/test_user_creation/users/auth/auth_repository.dart';
import 'src/test_user_creation/users/user_repository.dart';
import 'src/test_user_creation/users/user_model.dart';
import 'src/test_user_creation/users/user_service.dart';
import 'login_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academia Grazi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const LoginView(),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isLoading = false;

  Future<void> _handleRegistration() async {
    setState(() => _isLoading = true);

    try {
      final authRepo = AuthRepository();
      final userRepo = UserRepository();
      final userService = UserService(authRepo, userRepo);

      await userService.registerStudent(
        'Eduardo Müller2',
        'eduardo2@academiagrazi.com',
        'SecurePass123!',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SUCCESS: User registered and saved.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('AUTH EXCEPTION: ${e.code}');
    } catch (e) {
      debugPrint('SYSTEM ERROR: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Student')),
      body: Center(
        child:
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _handleRegistration,
                  child: const Text('Execute Secure Registration'),
                ),
      ),
    );
  }

  // Future<void> _testFirewallRejection() async {
  //   setState(() => _isLoading = true);

  //   try {
  //     await FirebaseAuth.instance.signOut();

  //     final userRepo = UserRepository();
  //     final unauthorizedUser = UserModel(
  //       id: 'unauthorized-123',
  //       name: 'Hacker',
  //       email: 'hacker@academiagrazi.com',
  //     );

  //     await userRepo.createUser(unauthorizedUser);

  //     debugPrint(
  //       'CRITICAL FAILURE: The firewall allowed an unauthorized write.',
  //     );
  //   } on FirebaseException catch (e) {
  //     debugPrint('FIREWALL SUCCESS: Network request blocked -> ${e.code}');
  //   } catch (e) {
  //     debugPrint('SYSTEM ERROR: $e');
  //   } finally {
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(title: const Text('Register Student')),
  //     body: Center(
  //       child:
  //           _isLoading
  //               ? const CircularProgressIndicator()
  //               : ElevatedButton(
  //                 onPressed: _testFirewallRejection,
  //                 child: const Text('Test Firewall Rejection'),
  //               ),
  //     ),
  //   );
  // }
}
