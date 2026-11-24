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
        // Sem createdAt no modelo, o toJson não inventa uma data nova.
        expect(json, isNot(contains('createdAt')));
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
      registrationProfile: RegistrationProfile(
        measurements: BodyMeasurements(age: 28, heightCm: 165, weightKg: 68.5),
        gender: Gender.female,
        primaryGoal: PrimaryGoal.conditioning,
        health: HealthProfile(
          conditions: ['Joelho'],
          notes: 'Cuidado com impacto',
          restrictions: ['Asma/Bronquite'],
        ),
        emergencyContact: EmergencyContact(
          name: 'Carlos',
          relationship: 'Cônjuge / Parceiro(a)',
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
    expect(parsed.registrationProfile?.health.conditions, ['Joelho']);
    expect(parsed.registrationProfile?.emergencyContact.phone, '11999999999');
    expect(json['registrationProfile']['gender'], 'female');
    expect(parsed.registrationProfile?.gender, Gender.female);
  });

  test('perfil anterior ao campo gender é lido sem gênero', () {
    final profile = RegistrationProfile.fromJson({
      'measurements': {'age': 28, 'heightCm': 165, 'weightKg': 68.5},
      'primaryGoal': 'conditioning',
    });

    expect(profile.gender, isNull);
    expect(profile.toJson(), isNot(contains('gender')));
  });

  group('GB-003 | createdAt e novos campos |', () {
    test('grava createdAt em UTC e o lê de volta sem alterar', () {
      final criadoEm = DateTime.utc(2026, 3, 10, 14, 30);
      final user = UserModel(
        id: 'u1',
        name: 'Ana',
        email: 'ana@example.com',
        createdAt: criadoEm,
      );

      final json = user.toJson();
      expect(json['createdAt'], '2026-03-10T14:30:00.000Z');

      final lido = UserModel.fromJson(json, 'u1');
      expect(lido.createdAt, criadoEm);
      expect(lido.toJson()['createdAt'], json['createdAt']);
    });

    test('copyWith mantém createdAt e os novos campos', () {
      final user = UserModel(
        id: 'p1',
        name: 'Prof',
        email: 'prof@example.com',
        type: UserType.instructor,
        createdAt: DateTime.utc(2026, 1, 1),
        specialty: 'Pilates',
        studentCapacity: 25,
      );

      final copia = user.copyWith(registrationCode: '1234');

      expect(copia.createdAt, DateTime.utc(2026, 1, 1));
      expect(copia.specialty, 'Pilates');
      expect(copia.studentCapacity, 25);
      expect(copia.registrationCode, '1234');
    });

    test('serializa e lê unidade, modalidade, especialidade e capacidade', () {
      final aluno = UserModel(
        id: 'a1',
        name: 'Aluno',
        email: 'a@example.com',
        unitId: 'unidade-centro',
        modality: StudentModality.remote,
      );
      final professor = UserModel(
        id: 'p1',
        name: 'Prof',
        email: 'p@example.com',
        type: UserType.instructor,
        specialty: 'Musculação',
        studentCapacity: 40,
      );

      final alunoJson = aluno.toJson();
      expect(alunoJson['unitId'], 'unidade-centro');
      expect(alunoJson['modality'], 'remote');
      final alunoLido = UserModel.fromJson(alunoJson, 'a1');
      expect(alunoLido.unitId, 'unidade-centro');
      expect(alunoLido.modality, StudentModality.remote);

      final professorLido = UserModel.fromJson(professor.toJson(), 'p1');
      expect(professorLido.specialty, 'Musculação');
      expect(professorLido.studentCapacity, 40);
    });

    test('documento antigo sem os campos novos é lido sem erro', () {
      final user = UserModel.fromJson({
        'name': 'Antigo',
        'email': 'antigo@example.com',
        'type': 'user',
        'modality': 'valor-desconhecido',
      }, 'old');

      expect(user.createdAt, isNull);
      expect(user.responsable, isNull);
      expect(user.unitId, isNull);
      expect(user.modality, isNull);
      expect(user.specialty, isNull);
      expect(user.studentCapacity, isNull);
      expect(
        user.toJson().keys,
        isNot(
          anyOf(
            contains('createdAt'),
            contains('unitId'),
            contains('modality'),
          ),
        ),
      );
    });
  });

  group('photoUrl |', () {
    test('serializa e lê a photoUrl', () {
      final user = UserModel(
        id: '1',
        name: 'Grazi',
        email: 'grazi@example.com',
        photoUrl: 'https://res.cloudinary.com/demo/image/upload/a.jpg',
      );

      final json = user.toJson();
      expect(
        json['photoUrl'],
        'https://res.cloudinary.com/demo/image/upload/a.jpg',
      );
      expect(UserModel.fromJson(json, '1').photoUrl, json['photoUrl']);
    });

    test('omite a photoUrl quando não há foto', () {
      final user = UserModel(id: '1', name: 'Grazi', email: 'g@example.com');

      expect(user.toJson().containsKey('photoUrl'), isFalse);
      expect(UserModel.fromJson({}, '1').photoUrl, isNull);
    });

    test('copyWith troca a photoUrl e mantém o restante', () {
      final user = UserModel(id: '1', name: 'Grazi', email: 'g@example.com');
      final updated = user.copyWith(photoUrl: 'https://x/y.jpg');

      expect(updated.photoUrl, 'https://x/y.jpg');
      expect(updated.name, 'Grazi');
    });
  });
}
