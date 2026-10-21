import 'registration_profile.dart';

enum UserType { admin, instructor, user }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserType type;
  String? responsable;
  final String? registrationCode;
  final DateTime? registrationCodeExpiresAt;
  final RegistrationProfile? registrationProfile;
  final bool onboardingCompleted;
  final DateTime? termsAcceptedAt;
  final String? photoUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.type = UserType.user,
    this.responsable,
    this.registrationCode,
    this.registrationCodeExpiresAt,
    this.registrationProfile,
    this.onboardingCompleted = false,
    this.termsAcceptedAt,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'type': type.name,
    'createdAt': DateTime.now().toIso8601String(),
    'responsable': responsable,
    if (registrationCode != null) 'registrationCode': registrationCode,
    if (registrationCodeExpiresAt != null)
      'registrationCodeExpiresAt':
          registrationCodeExpiresAt!.toUtc().toIso8601String(),
    if (registrationProfile != null)
      'registrationProfile': registrationProfile!.toJson(),
    'onboardingCompleted': onboardingCompleted,
    if (termsAcceptedAt != null)
      'termsAcceptedAt': termsAcceptedAt!.toIso8601String(),
    if (photoUrl != null) 'photoUrl': photoUrl,
  };

  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    return UserModel(
      id: documentId,
      name: json['name'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      type: _parseUserType(json['type'] as String?),
      responsable: json['responsable'] as String? ?? '',
      registrationCode: json['registrationCode'] as String?,
      registrationCodeExpiresAt: _parseDateTime(
        json['registrationCodeExpiresAt'],
      ),
      registrationProfile:
          json['registrationProfile'] is Map
              ? RegistrationProfile.fromJson(
                Map<String, dynamic>.from(json['registrationProfile'] as Map),
              )
              : null,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      termsAcceptedAt: _parseDateTime(json['termsAcceptedAt']),
      photoUrl: json['photoUrl'] as String?,
    );
  }

  UserModel copyWith({
    String? registrationCode,
    DateTime? registrationCodeExpiresAt,
    String? photoUrl,
  }) {
    return UserModel(
      id: id,
      name: name,
      email: email,
      type: type,
      responsable: responsable,
      registrationCode: registrationCode ?? this.registrationCode,
      registrationCodeExpiresAt:
          registrationCodeExpiresAt ?? this.registrationCodeExpiresAt,
      registrationProfile: registrationProfile,
      onboardingCompleted: onboardingCompleted,
      termsAcceptedAt: termsAcceptedAt,
      photoUrl: photoUrl ?? this.photoUrl,
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
