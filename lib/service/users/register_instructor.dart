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

/// Código de convite atual de um professor e o fim da sua validade.
class InstructorInviteCode {
  final String code;
  final DateTime expiresAt;

  const InstructorInviteCode({required this.code, required this.expiresAt});
}

/// Gerencia os códigos de convite dos professores.
///
/// Cada professor tem sempre um código numérico de [codeLength] dígitos,
/// válido por [codeLifetime]. Não existe backend para renovar os códigos
/// sozinho: quando o código é pedido (perfil do professor ou detalhes no
/// admin) e já venceu, um novo é gerado na hora. Códigos vencidos são
/// recusados na validação e podem ser reaproveitados por outro professor.
class RegisterInstructorService {
  static const int codeLength = 4;
  static const Duration codeLifetime = Duration(minutes: 15);
  static const int _maxAttempts = 20;

  final FirebaseFirestore _db;
  final DateTime Function() _clock;

  // coverage:ignore-start
  RegisterInstructorService({FirebaseFirestore? db, DateTime Function()? clock})
    : _db = db ?? FirebaseFirestore.instance,
      _clock = clock ?? DateTime.now;
  // coverage:ignore-end

  CollectionReference<Map<String, dynamic>> get _codes =>
      _db.collection('instructorCodes');

  /// Cria o perfil do professor já com o primeiro código de convite.
  Future<String> registerInstructor(
    UserModel instructor, {
    String Function()? codeGenerator,
  }) async {
    final invite = await _issueCode(
      instructorId: instructor.id,
      newInstructor: instructor,
      codeGenerator: codeGenerator,
    );
    return invite.code;
  }

  /// Código válido do professor, renovando-o se tiver vencido (ou se o
  /// professor ainda não tiver um).
  Future<InstructorInviteCode> getCurrentInviteCode(
    String instructorId, {
    String Function()? codeGenerator,
  }) {
    return _issueCode(instructorId: instructorId, codeGenerator: codeGenerator);
  }

  Future<InstructorCodeInfo?> validateInstructorCode(String rawCode) async {
    final code = rawCode.trim();

    if (code.isEmpty) {
      return null;
    }

    final codeSnapshot = await _codes.doc(code).get();
    final codeData = codeSnapshot.data();

    if (!codeSnapshot.exists ||
        codeData == null ||
        codeData['active'] != true ||
        !_isStillValid(codeData)) {
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

  bool _isStillValid(Map<String, dynamic> codeData) {
    final expiresAtMillis = codeData['expiresAtMillis'];
    return expiresAtMillis is int &&
        expiresAtMillis > _clock().millisecondsSinceEpoch;
  }

  /// Emite um código novo dentro de uma transação. Se [newInstructor] for
  /// informado, o perfil do professor é criado junto; caso contrário, o
  /// código atual é devolvido enquanto ainda for válido.
  Future<InstructorInviteCode> _issueCode({
    required String instructorId,
    UserModel? newInstructor,
    String Function()? codeGenerator,
  }) async {
    final generator = codeGenerator ?? _generateCode;

    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      final candidate = generator().trim();

      try {
        return await _db.runTransaction((transaction) async {
          final userReference = _db.collection('users').doc(instructorId);
          final now = _clock();

          String instructorName;
          String? previousCode;

          if (newInstructor == null) {
            final userSnapshot = await transaction.get(userReference);
            final userData = userSnapshot.data();
            if (!userSnapshot.exists || userData == null) {
              throw ArgumentError('Instructor not found');
            }
            final instructor = UserModel.fromJson(userData, userSnapshot.id);
            if (instructor.type != UserType.instructor) {
              throw ArgumentError('Only instructors can have invite codes');
            }

            final currentCode = instructor.registrationCode?.trim();
            final currentExpiry = instructor.registrationCodeExpiresAt;
            if (currentCode != null &&
                currentCode.isNotEmpty &&
                currentExpiry != null &&
                currentExpiry.isAfter(now)) {
              return InstructorInviteCode(
                code: currentCode,
                expiresAt: currentExpiry,
              );
            }

            instructorName = instructor.name;
            previousCode =
                currentCode == null || currentCode.isEmpty ? null : currentCode;
          } else {
            instructorName = newInstructor.name;
          }

          final codeReference = _codes.doc(candidate);
          final existing = await transaction.get(codeReference);
          final existingData = existing.data();
          final previousReference =
              previousCode != null && previousCode != candidate
                  ? _codes.doc(previousCode)
                  : null;
          final previousSnapshot =
              previousReference == null
                  ? null
                  : await transaction.get(previousReference);

          // Só reaproveita códigos vencidos, desativados ou do próprio
          // professor.
          if (existing.exists &&
              existingData != null &&
              existingData['instructorId'] != instructorId &&
              existingData['active'] == true &&
              _isStillValid(existingData)) {
            throw StateError('Instructor code collision');
          }

          final expiresAt = now.add(codeLifetime).toUtc();

          if (newInstructor != null) {
            transaction.set(
              userReference,
              newInstructor
                  .copyWith(
                    registrationCode: candidate,
                    registrationCodeExpiresAt: expiresAt,
                  )
                  .toJson(),
            );
          } else {
            transaction.update(userReference, {
              'registrationCode': candidate,
              'registrationCodeExpiresAt': expiresAt.toIso8601String(),
            });
          }

          transaction.set(codeReference, {
            'instructorId': instructorId,
            'instructorName': instructorName,
            'active': true,
            'createdAt': now.toIso8601String(),
            'expiresAtMillis': expiresAt.millisecondsSinceEpoch,
          });

          if (previousSnapshot != null &&
              previousSnapshot.exists &&
              previousSnapshot.data()?['instructorId'] == instructorId) {
            transaction.update(previousReference!, {'active': false});
          }

          return InstructorInviteCode(code: candidate, expiresAt: expiresAt);
        });
      } on StateError {
        if (attempt == _maxAttempts - 1) {
          rethrow;
        }
      }
    }

    throw StateError('Unable to generate a unique instructor code');
  }

  String _generateCode() {
    final random = Random.secure();
    return List.generate(codeLength, (_) => random.nextInt(10)).join();
  }
}
