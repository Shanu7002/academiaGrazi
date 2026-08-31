import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  // Required to bind native channels before UI rendering
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // Routes directly to the database test screen
      home: const TestScreen(),
    );
  }
}

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  Future<void> _executeTestWrite() async {
    try {
      // Executes an O(1) network write directly to the Firestore edge node
      await FirebaseFirestore.instance
          .collection('users')
          .doc('test-user-123')
          .set({
            'name': 'Test User',
            'email': 'test@academiagrazi.com',
            'role': 'student',
            'createdAt': FieldValue.serverTimestamp(),
          });

      debugPrint('SUCCESS: Document written to Firestore.');
    } on FirebaseException catch (e) {
      debugPrint('FIREBASE EXCEPTION: ${e.code} - ${e.message}');
    } catch (e) {
      debugPrint('SYSTEM ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('DB Integration Test'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _executeTestWrite,
          child: const Text('Execute Write Operation'),
        ),
      ),
    );
  }
}
