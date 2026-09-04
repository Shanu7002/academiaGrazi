import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/users/register.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late UserService userService;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    userService = UserService(db: fakeDb);
  });

  group('UserService Tests |', () {
    test(
      'registerUser should successfully insert a document including the serialized enum',
      () async {
        final user = UserModel(
          id: 'user_777',
          name: 'Teste da Silva',
          email: 'test@test.com',
          type: UserType.admin,
        );

        await userService.registerUser(user);

        final snapshot = await fakeDb.collection('users').doc('user_777').get();
        expect(snapshot.exists, isTrue);

        final data = snapshot.data() as Map<String, dynamic>;
        expect(data['name'], 'Teste da Silva');
        expect(data['email'], 'test@test.com');
        expect(data['type'], 'admin');
        expect(data['createdAt'], isNotNull);
      },
    );
  });
}
