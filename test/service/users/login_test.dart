import "package:academiagrazi/service/users/login.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mockito/annotations.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:mockito/mockito.dart";

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
])
import "login_test.mocks.dart";

void main() {
  late MockFirebaseFirestore mockDb;
  late MockCollectionReference<Map<String, dynamic>> mockCollection;
  late MockDocumentReference<Map<String, dynamic>> mockDocument;
  late MockDocumentSnapshot<Map<String, dynamic>> mockSnapshot;

  late LoginService service;

  const id = "fake_uid_777";
  const name = "test";
  const email = "test@test.com";

  setUp(() async {
    mockDb = MockFirebaseFirestore();
    mockCollection = MockCollectionReference<Map<String, dynamic>>();
    mockDocument = MockDocumentReference<Map<String, dynamic>>();
    mockSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

    service = LoginService(db: mockDb);

    when(mockDb.collection("users")).thenReturn(mockCollection);

    when(mockCollection.doc(id)).thenReturn(mockDocument);

    when(mockDocument.get()).thenAnswer((_) async => mockSnapshot);
  });

  group("loginService Tests sucessfully | ", () {
    test("should find the user when document exist", () async {
      final data = {"name": name, "email": email};

      when(mockSnapshot.exists).thenReturn(true);
      when(mockSnapshot.data()).thenReturn(data);
      when(mockSnapshot.id).thenReturn(id);

      final result = await service.getUserProfile(id);

      expect(result?.id, id);
      expect(result?.name, "test");
      expect(result?.email, "test@test.com");

      verify(mockDb.collection("users")).called(1);
      verify(mockCollection.doc(id)).called(1);
      verify(mockDocument.get()).called(1);
    });

    test("should return null when document data is null", () async {
      when(mockSnapshot.exists).thenReturn(true);
      when(mockSnapshot.data()).thenReturn(null);

      final result = await service.getUserProfile(id);

      expect(result, isNull);
    });
  });
  group("loginService Tests failed", () {
    test("should return null when document not exist", () async {
      when(mockSnapshot.exists).thenReturn(false);
      when(mockSnapshot.data()).thenReturn(null);

      final result = await service.getUserProfile(id);

      expect(result, isNull);

      verify(mockDb.collection("users")).called(1);
      verify(mockCollection.doc(id)).called(1);
      verify(mockDocument.get()).called(1);
    });

    test("should return error if database is unreachable", () async {
      when(mockDocument.get()).thenThrow(Exception("Firestore error"));

      expect(() => service.getUserProfile(id), throwsA(isA<Exception>()));
    });
  });
}
