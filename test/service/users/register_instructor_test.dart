import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/users/register_instructor.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late RegisterInstructorService service;
  late DateTime now;

  setUp(() {
    // Hermetic execution: fresh database for every test
    fakeDb = FakeFirebaseFirestore();
    now = DateTime.utc(2026, 10, 21, 14, 0);
    service = RegisterInstructorService(db: fakeDb, clock: () => now);
  });

  final instructor = UserModel(
    id: 'instructor-1',
    name: 'Marina',
    email: 'marina@example.com',
    type: UserType.instructor,
  );

  String Function() codes(List<String> values) {
    final queue = [...values];
    return () => queue.removeAt(0);
  }

  Future<Map<String, dynamic>?> codeDoc(String code) async =>
      (await fakeDb.collection('instructorCodes').doc(code).get()).data();

  Future<Map<String, dynamic>?> userDoc(String id) async =>
      (await fakeDb.collection('users').doc(id).get()).data();

  group('RegisterInstructorService - Instructor Codes |', () {
    test('registers the instructor already with a 15-minute code', () async {
      final code = await service.registerInstructor(
        instructor,
        codeGenerator: () => '4821',
      );

      final user = await userDoc(instructor.id);
      final codeDocument = await codeDoc(code);
      final expiresAt = now.add(const Duration(minutes: 15));

      expect(code, '4821');
      expect(user?['registrationCode'], '4821');
      expect(user?['registrationCodeExpiresAt'], expiresAt.toIso8601String());
      expect(codeDocument?['instructorId'], instructor.id);
      expect(codeDocument?['instructorName'], 'Marina');
      expect(codeDocument?['active'], isTrue);
      expect(
        codeDocument?['expiresAtMillis'],
        expiresAt.millisecondsSinceEpoch,
      );
    });

    test('generates 4-digit numeric codes by default', () async {
      final code = await service.registerInstructor(instructor);

      expect(code, matches(RegExp(r'^\d{4}$')));
    });

    test('keeps the current code while it is still valid', () async {
      await service.registerInstructor(instructor, codeGenerator: () => '4821');
      now = now.add(const Duration(minutes: 14));

      final current = await service.getCurrentInviteCode(
        instructor.id,
        codeGenerator: () => '9999',
      );

      expect(current.code, '4821');
    });

    test('renews an expired code and deactivates the old one', () async {
      await service.registerInstructor(instructor, codeGenerator: () => '4821');
      now = now.add(const Duration(minutes: 16));

      final current = await service.getCurrentInviteCode(
        instructor.id,
        codeGenerator: () => '1357',
      );

      expect(current.code, '1357');
      expect(current.expiresAt, now.add(const Duration(minutes: 15)));
      expect((await userDoc(instructor.id))?['registrationCode'], '1357');
      expect((await codeDoc('1357'))?['active'], isTrue);
      expect((await codeDoc('4821'))?['active'], isFalse);
    });

    test('gives a code to an instructor that never had one', () async {
      await fakeDb
          .collection('users')
          .doc(instructor.id)
          .set(instructor.toJson());

      final current = await service.getCurrentInviteCode(
        instructor.id,
        codeGenerator: () => '0042',
      );

      expect(current.code, '0042');
      expect((await userDoc(instructor.id))?['registrationCode'], '0042');
    });

    test('skips codes still in use by another instructor', () async {
      await service.registerInstructor(instructor, codeGenerator: () => '4821');
      final other = UserModel(
        id: 'instructor-2',
        name: 'Ana',
        email: 'ana@example.com',
        type: UserType.instructor,
      );

      final code = await service.registerInstructor(
        other,
        codeGenerator: codes(['4821', '7777']),
      );

      expect(code, '7777');
      expect((await codeDoc('4821'))?['instructorId'], instructor.id);
    });

    test('reuses an expired code from another instructor', () async {
      await service.registerInstructor(instructor, codeGenerator: () => '4821');
      now = now.add(const Duration(minutes: 20));
      final other = UserModel(
        id: 'instructor-2',
        name: 'Ana',
        email: 'ana@example.com',
        type: UserType.instructor,
      );

      final code = await service.registerInstructor(
        other,
        codeGenerator: () => '4821',
      );

      expect(code, '4821');
      expect((await codeDoc('4821'))?['instructorId'], 'instructor-2');
    });

    test('refuses to issue codes for non-instructors', () async {
      await fakeDb
          .collection('users')
          .doc('student-1')
          .set(
            UserModel(
              id: 'student-1',
              name: 'Aluno',
              email: 'a@a.com',
            ).toJson(),
          );

      expect(
        () => service.getCurrentInviteCode('student-1'),
        throwsArgumentError,
      );
    });
  });

  group('validateInstructorCode |', () {
    test('validates a current code', () async {
      await service.registerInstructor(instructor, codeGenerator: () => '4821');

      final result = await service.validateInstructorCode(' 4821 ');

      expect(result?.code, '4821');
      expect(result?.instructorId, instructor.id);
      expect(result?.instructorName, 'Marina');
    });

    test('rejects an expired code', () async {
      await service.registerInstructor(instructor, codeGenerator: () => '4821');
      now = now.add(const Duration(minutes: 15, seconds: 1));

      expect(await service.validateInstructorCode('4821'), isNull);
    });

    test('rejects legacy codes without expiration', () async {
      await fakeDb.collection('instructorCodes').doc('ABCD2345').set({
        'instructorId': 'instructor-1',
        'instructorName': 'Marina',
        'active': true,
      });

      expect(await service.validateInstructorCode('ABCD2345'), isNull);
    });

    test('rejects a code without its public instructor name', () async {
      await fakeDb.collection('instructorCodes').doc('1234').set({
        'instructorId': 'instructor-1',
        'active': true,
        'expiresAtMillis':
            now.add(const Duration(minutes: 5)).millisecondsSinceEpoch,
      });

      expect(await service.validateInstructorCode('1234'), isNull);
    });

    test('rejects inactive, empty and unknown codes', () async {
      await fakeDb.collection('instructorCodes').doc('1111').set({
        'instructorId': 'instructor-1',
        'instructorName': 'Marina',
        'active': false,
        'expiresAtMillis':
            now.add(const Duration(minutes: 5)).millisecondsSinceEpoch,
      });

      expect(await service.validateInstructorCode('1111'), isNull);
      expect(await service.validateInstructorCode('   '), isNull);
      expect(await service.validateInstructorCode('9876'), isNull);
    });
  });
}
