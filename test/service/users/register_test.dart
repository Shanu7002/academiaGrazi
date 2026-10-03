import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter_test/flutter_test.dart";
import "package:fake_cloud_firestore/fake_cloud_firestore.dart";
import "package:academiagrazi/models/users/user_model.dart";
import "package:academiagrazi/service/users/register_user.dart";
import "package:mockito/annotations.dart";
import "package:mockito/mockito.dart";

@GenerateMocks([FirebaseFirestore, CollectionReference, DocumentReference])
import "register_test.mocks.dart";

void main() {
  late FakeFirebaseFirestore fakeDb;
  late RegisterService registerService;
  final mockDb = MockFirebaseFirestore();
  final mockCollection = MockCollectionReference<Map<String, dynamic>>();
  final mockDocument = MockDocumentReference<Map<String, dynamic>>();

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    registerService = RegisterService(db: fakeDb);
  });

  group("registerService Tests |", () {
    test(
      "registerUser should successfully insert a document including the serialized enum",
      () async {
        final user = UserModel(
          id: "user_777",
          name: "Teste da Silva",
          email: "test@test.com",
          type: UserType.admin,
          responsable: 'test',
        );

        await registerService.registerUser(user);

        final snapshot = await fakeDb.collection("users").doc("user_777").get();
        expect(snapshot.exists, isTrue);

        final data = snapshot.data() as Map<String, dynamic>;
        expect(data["name"], "Teste da Silva");
        expect(data["email"], "test@test.com");
        expect(data["type"], "admin");
        expect(data["createdAt"], isNotNull);
      },
    );
  });
  group("registerService Tests |", () {
    test("registerUser should throw an error when insert fails", () async {
      final user = UserModel(
        id: "user_777",
        name: "Teste da Silva",
        email: "test@test.com",
        type: UserType.admin,
        responsable: 'test',
      );

      when(mockDb.collection("users")).thenReturn(mockCollection);
      when(mockCollection.doc(user.id)).thenReturn(mockDocument);

      when(mockDocument.set(any)).thenThrow(Exception("Internal server error"));

      final service = RegisterService(db: mockDb);

      expect(service.registerUser(user), throwsA(isA<Exception>()));
    });
  });

  group('instructor codes |', () {
    test('atomically registers an instructor and reusable code', () async {
      final instructor = UserModel(
        id: 'instructor-1',
        name: 'Marina',
        email: 'marina@example.com',
        type: UserType.instructor,
      );

      final code = await registerService.registerInstructorWithCode(
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

      final result = await registerService.validateInstructorCode(
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
      });

      expect(await registerService.validateInstructorCode('LEGACY12'), isNull);
    });

    test('rejects inactive and unknown instructor codes', () async {
      await fakeDb.collection('instructorCodes').doc('INACTIVE').set({
        'instructorId': 'instructor-1',
        'active': false,
      });

      expect(await registerService.validateInstructorCode('INACTIVE'), isNull);
      expect(await registerService.validateInstructorCode('UNKNOWN1'), isNull);
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

      final code = await registerService.ensureInstructorCode(
        instructor,
        codeGenerator: () => 'WXYZ6789',
      );

      final user = await fakeDb.collection('users').doc(instructor.id).get();
      expect(code, 'WXYZ6789');
      expect(user.data()?['registrationCode'], code);
    });
  });
}
