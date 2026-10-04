import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/users/register_user.dart';

@GenerateMocks([FirebaseFirestore, CollectionReference, DocumentReference])
import 'register_user_test.mocks.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late RegisterUserService registerUserService;

  late MockFirebaseFirestore mockDb;
  late MockCollectionReference<Map<String, dynamic>> mockCollection;
  late MockDocumentReference<Map<String, dynamic>> mockDocument;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    registerUserService = RegisterUserService(db: fakeDb);

    mockDb = MockFirebaseFirestore();
    mockCollection = MockCollectionReference<Map<String, dynamic>>();
    mockDocument = MockDocumentReference<Map<String, dynamic>>();
  });

  group('RegisterUserService Tests |', () {
    test(
      'successfully inserts a document including the serialized enum',
      () async {
        final user = UserModel(
          id: 'user_777',
          name: 'Teste da Silva',
          email: 'test@test.com',
          type: UserType.admin,
          responsable: 'test',
        );

        await registerUserService.registerUser(user);

        final snapshot = await fakeDb.collection('users').doc('user_777').get();
        expect(snapshot.exists, isTrue);

        final data = snapshot.data() as Map<String, dynamic>;
        expect(data['name'], 'Teste da Silva');
        expect(data['email'], 'test@test.com');
        expect(data['type'], 'admin');
        expect(data['createdAt'], isNotNull);
      },
    );

    test('throws an Exception when the database insert fails', () async {
      final user = UserModel(
        id: 'user_777',
        name: 'Teste da Silva',
        email: 'test@test.com',
        type: UserType.admin,
        responsable: 'test',
      );

      when(mockDb.collection('users')).thenReturn(mockCollection);
      when(mockCollection.doc(user.id)).thenReturn(mockDocument);
      when(mockDocument.set(any)).thenThrow(Exception('Internal server error'));

      final serviceWithMock = RegisterUserService(db: mockDb);

      expect(serviceWithMock.registerUser(user), throwsA(isA<Exception>()));
    });
  });
}
