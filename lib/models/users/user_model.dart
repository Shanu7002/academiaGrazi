import 'registration_profile.dart';

enum UserType { admin, instructor, user }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserType type;
  String? responsable;
  final String? registrationCode;
  final RegistrationProfile? registrationProfile;
  final bool onboardingCompleted;
  final DateTime? termsAcceptedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.type = UserType.user,
    this.responsable,
    this.registrationCode,
    this.registrationProfile,
    this.onboardingCompleted = false,
    this.termsAcceptedAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'type': type.name,
    'createdAt': DateTime.now().toIso8601String(),
    'responsable': responsable,
    if (registrationCode != null) 'registrationCode': registrationCode,
    if (registrationProfile != null)
      'registrationProfile': registrationProfile!.toJson(),
    'onboardingCompleted': onboardingCompleted,
    if (termsAcceptedAt != null)
      'termsAcceptedAt': termsAcceptedAt!.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    return UserModel(
      id: documentId,
      name: json['name'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      type: _parseUserType(json['type'] as String?),
      responsable: json['responsable'] as String? ?? '',
      registrationCode: json['registrationCode'] as String?,
      registrationProfile:
          json['registrationProfile'] is Map
              ? RegistrationProfile.fromJson(
                Map<String, dynamic>.from(json['registrationProfile'] as Map),
              )
              : null,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      termsAcceptedAt: _parseDateTime(json['termsAcceptedAt']),
    );
  }

  UserModel copyWith({String? registrationCode}) {
    return UserModel(
      id: id,
      name: name,
      email: email,
      type: type,
      responsable: responsable,
      registrationCode: registrationCode ?? this.registrationCode,
      registrationProfile: registrationProfile,
      onboardingCompleted: onboardingCompleted,
      termsAcceptedAt: termsAcceptedAt,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static UserType _parseUserType(String? typeString) {
    switch (typeString) {
      case 'admin':
        return UserType.admin;
      case 'instructor':
        return UserType.instructor;
      case 'user':
      default:
        return UserType.user;
    }
  }

  // helper func to print json as string
  // (tava com problema de debugar os tests e achei isso viavel)
  // coverage:ignore-start
  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, type: ${type.name})';
  }
  // coverage:ignore-end
}
