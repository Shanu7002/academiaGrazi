import 'package:academiagrazi/firebase_options.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/theme/app_theme.dart';
import 'package:academiagrazi/view/welcome_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  setupLocator();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academia Grazi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const WelcomeView(),
    );
  }
}
