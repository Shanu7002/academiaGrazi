import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/users/register_instructor.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late RegisterInstructorService registerInstructorService;

  setUp(() {
    // Hermetic execution: fresh database for every test
    fakeDb = FakeFirebaseFirestore();
    registerInstructorService = RegisterInstructorService(db: fakeDb);
  });

  group('RegisterInstructorService - Instructor Codes |', () {
    test('atomically registers an instructor and reusable code', () async {
      final instructor = UserModel(
        id: 'instructor-1',
        name: 'Marina',
        email: 'marina@example.com',
        type: UserType.instructor,
      );

      final code = await registerInstructorService.registerInstructor(
        instructor,
        codeGenerator: () => 'ABCD2345',
      );

      final user = await fakeDb.collection('users').doc(instructor.id).get();
      final codeDocument =
          await fakeDb.collection('instructorCodes').doc(code).get();

      expect(code, 'ABCD2345');
      expect(user.data()?['registrationCode'], code);
      expect(codeDocument.data()?['instructorId'], instructor.id);
      expect(codeDocument.data()?['instructorName'], instructor.name);
      expect(codeDocument.data()?['active'], isTrue);
    });

    test('validates a normalized active instructor code', () async {
      await fakeDb.collection('instructorCodes').doc('ABCD2345').set({
        'instructorId': 'instructor-1',
        'instructorName': 'Marina',
        'active': true,
      });

      final result = await registerInstructorService.validateInstructorCode(
        '  abcd2345 ',
      );

      expect(result?.code, 'ABCD2345');
      expect(result?.instructorId, 'instructor-1');
      expect(result?.instructorName, 'Marina');
    });

    test('rejects a code without its public instructor name', () async {
      await fakeDb.collection('instructorCodes').doc('LEGACY12').set({
        'instructorId': 'instructor-1',
        'active': true,
        // Missing instructorName simulates legacy data
      });

      expect(
        await registerInstructorService.validateInstructorCode('LEGACY12'),
        isNull,
      );
    });

    test('rejects inactive and unknown instructor codes', () async {
      await fakeDb.collection('instructorCodes').doc('INACTIVE').set({
        'instructorId': 'instructor-1',
        'active': false,
      });

      expect(
        await registerInstructorService.validateInstructorCode('INACTIVE'),
        isNull,
      );
      expect(
        await registerInstructorService.validateInstructorCode('UNKNOWN1'),
        isNull,
      );
    });

    test('generates a code for an existing instructor', () async {
      final instructor = UserModel(
        id: 'instructor-2',
        name: 'Ana',
        email: 'ana@example.com',
        type: UserType.instructor,
      );
      await fakeDb
          .collection('users')
          .doc(instructor.id)
          .set(instructor.toJson());

      final code = await registerInstructorService.ensureInstructorCode(
        instructor,
        codeGenerator: () => 'WXYZ6789',
      );

      final user = await fakeDb.collection('users').doc(instructor.id).get();
      expect(code, 'WXYZ6789');
      expect(user.data()?['registrationCode'], code);
    });
  });
}
