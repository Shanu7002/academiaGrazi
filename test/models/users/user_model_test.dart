import 'package:flutter_test/flutter_test.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/models/users/registration_profile.dart';

void main() {
  group('UserModel Tests |', () {
    test(
      'Constructor should allocate object with correct properties in memory',
      () {
        final user = UserModel(
          id: '123',
          name: 'Teste da Silva',
          email: 'test@test.com',
          responsable: 'test',
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
        responsable: 'test',
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
          type: UserType.instructor,
          responsable: 'test',
        );

        final Map<String, dynamic> json = user.toJson();

        expect(json['name'], 'Teste da Silva');
        expect(json['type'], 'instructor');
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
        "type": "instructor",
      };

      final user = UserModel.fromJson(userMap, "3");

      expect(user.id, "3");
      expect(user.name, name);
      expect(user.email, email);
      expect(user.type, UserType.instructor);
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

  test('serializes and parses the complete onboarding profile', () {
    final acceptedAt = DateTime.utc(2026, 9, 29);
    final user = UserModel(
      id: 'student-1',
      name: 'Grazi',
      email: 'grazi@example.com',
      responsable: 'instructor-1',
      onboardingCompleted: true,
      termsAcceptedAt: acceptedAt,
      registrationProfile: const RegistrationProfile(
        measurements: BodyMeasurements(age: 28, heightCm: 165, weightKg: 68.5),
        primaryGoal: PrimaryGoal.conditioning,
        health: HealthProfile(
          conditions: ['knee'],
          notes: 'Cuidado com impacto',
          restrictions: ['asthmaBronchitis'],
        ),
        emergencyContact: EmergencyContact(
          name: 'Carlos',
          relationship: 'partner',
          phone: '11999999999',
        ),
      ),
    );

    final json = user.toJson();
    final parsed = UserModel.fromJson(json, user.id);

    expect(json, isNot(contains('password')));
    expect(parsed.onboardingCompleted, isTrue);
    expect(parsed.termsAcceptedAt, acceptedAt);
    expect(parsed.registrationProfile?.measurements.weightKg, 68.5);
    expect(parsed.registrationProfile?.primaryGoal, PrimaryGoal.conditioning);
    expect(parsed.registrationProfile?.health.conditions, ['knee']);
    expect(parsed.registrationProfile?.emergencyContact.phone, '11999999999');
  });
}
