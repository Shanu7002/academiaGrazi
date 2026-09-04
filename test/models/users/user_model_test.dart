import 'package:flutter_test/flutter_test.dart';
import 'package:academiagrazi/models/users/user_model.dart'; // Update to your project name

void main() {
  group('UserModel Tests |', () {
    test(
      'Constructor should allocate object with correct properties in memory',
      () {
        final user = UserModel(
          id: '123',
          name: 'Teste da Silva',
          email: 'test@test.com',
        );

        expect(user.id, '123');
        expect(user.name, 'Teste da Silva');
        expect(user.email, 'test@test.com');
        expect(user.type, UserType.user);
      },
    );

    test('Constructor should accept explicit UserType memory allocation', () {
      final admin = UserModel(
        id: '456',
        name: 'Admin',
        email: 'admin@test.com',
        type: UserType.admin,
      );

      expect(admin.type, UserType.admin);
    });

    test(
      'toJson() should serialize enum to a valid String for network I/O',
      () {
        final user = UserModel(
          id: '123',
          name: 'Teste da Silva',
          email: 'test@test.com',
          type: UserType.professor,
        );

        final Map<String, dynamic> json = user.toJson();

        expect(json['name'], 'Teste da Silva');
        expect(json['type'], 'professor');
        expect(json['createdAt'], isA<String>());
      },
    );
  });
}
