import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter_test/flutter_test.dart";
import "package:fake_cloud_firestore/fake_cloud_firestore.dart";
import "package:academiagrazi/models/users/user_model.dart";
import "package:academiagrazi/service/users/register.dart";
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
      );

      when(mockDb.collection("users")).thenReturn(mockCollection);
      when(mockCollection.doc(user.id)).thenReturn(mockDocument);

      when(mockDocument.set(any)).thenThrow(Exception("Internal server error"));

      final service = RegisterService(db: mockDb);

      expect(service.registerUser(user), throwsA(isA<Exception>()));
    });
  });
}
