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

  group("Parse json Tests |", () {
    const name = "Test";
    const email = "test@gmail.com";
    test("Correct json parser with default type", () {
      Map<String, dynamic> userMap = {"name": name, "email": email};

      final user = UserModel.fromJson(userMap, "1");

      expect(user.id, "1");
      expect(user.name, name);
      expect(user.email, email);
      expect(user.type, UserType.user);
    });

    test("Correct json parser with admin type", () {
      Map<String, dynamic> userMap = {
        "name": name,
        "email": email,
        "type": "admin",
      };

      final user = UserModel.fromJson(userMap, "2");

      expect(user.id, "2");
      expect(user.name, name);
      expect(user.email, email);
      expect(user.type, UserType.admin);
    });

    test("Correct json parser with admin type", () {
      Map<String, dynamic> userMap = {
        "name": name,
        "email": email,
        "type": "professor",
      };

      final user = UserModel.fromJson(userMap, "3");

      expect(user.id, "3");
      expect(user.name, name);
      expect(user.email, email);
      expect(user.type, UserType.professor);
    });

    test("Correct json parser with full default pattern", () {
      Map<String, dynamic> userMap = {};

      final user = UserModel.fromJson(userMap, "4");

      expect(user.id, "4");
      expect(user.name, "Unknown");
      expect(user.email, "");
      expect(user.type, UserType.user);
    });
  });
}
