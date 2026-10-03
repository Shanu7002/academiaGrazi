import 'dart:math';

import "package:cloud_firestore/cloud_firestore.dart";
import "../../models/users/user_model.dart";

class InstructorCodeInfo {
  final String code;
  final String instructorId;
  final String instructorName;

  const InstructorCodeInfo({
    required this.code,
    required this.instructorId,
    required this.instructorName,
  });
}

class RegisterInstructorService {
  final FirebaseFirestore _db;

  // coverage:ignore-start
  RegisterInstructorService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  // coverage:ignore-end

  Future<String> registerInstructor(
    UserModel instructor, {
    String Function()? codeGenerator,
  }) async {
    return _reserveInstructorCode(instructor, createUserDocument: true);
  }

  Future<String> ensureInstructorCode(
    UserModel instructor, {
    String Function()? codeGenerator,
  }) async {
    final existingCode = instructor.registrationCode?.trim();

    if (existingCode != null && existingCode.isNotEmpty) {
      return existingCode;
    }

    if (instructor.type != UserType.instructor) {
      throw ArgumentError('Only instructors can have registration codes');
    }

    return _reserveInstructorCode(instructor, createUserDocument: false);
  }

  Future<InstructorCodeInfo?> validateInstructorCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();

    if (code.isEmpty) {
      return null;
    }

    final codeSnapshot =
        await _db.collection('instructorCodes').doc(code).get();

    final codeData = codeSnapshot.data();

    if (!codeSnapshot.exists ||
        codeData == null ||
        codeData['active'] != true) {
      return null;
    }

    final instructorId = codeData['instructorId'] as String?;
    final instructorName = codeData['instructorName'] as String?;

    if (instructorId == null ||
        instructorId.isEmpty ||
        instructorName == null ||
        instructorName.trim().isEmpty) {
      return null;
    }

    return InstructorCodeInfo(
      code: code,
      instructorId: instructorId,
      instructorName: instructorName.trim(),
    );
  }

  Future<String> _reserveInstructorCode(
    UserModel instructor, {
    required bool createUserDocument,
  }) async {
    final generator = _generateCode;

    for (var attempt = 0; attempt < 5; attempt++) {
      final code = generator().trim().toUpperCase();

      try {
        await _db.runTransaction((transaction) async {
          final codeReference = _db.collection('instructorCodes').doc(code);

          final userReference = _db.collection('users').doc(instructor.id);

          final existingCode = await transaction.get(codeReference);

          if (existingCode.exists) {
            throw StateError('Instructor code collision');
          }

          final instructorWithCode = instructor.copyWith(
            registrationCode: code,
          );

          if (createUserDocument) {
            transaction.set(userReference, instructorWithCode.toJson());
          } else {
            transaction.update(userReference, {'registrationCode': code});
          }

          transaction.set(codeReference, {
            'instructorId': instructor.id,
            'instructorName': instructor.name,
            'active': true,
            'createdAt': DateTime.now().toIso8601String(),
          });
        });

        return code;
      } on StateError {
        if (attempt == 4) {
          rethrow;
        }
      }
    }

    throw StateError('Unable to generate a unique instructor code');
  }

  String _generateCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();

    return List.generate(
      8,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }
}
