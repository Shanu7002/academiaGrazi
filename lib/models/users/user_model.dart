import 'registration_profile.dart';

enum UserType { admin, instructor, user }

/// Como o aluno treina; definida pelo professor responsável ou pelo admin.
enum StudentModality { onSite, remote }

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

  /// Gravado uma única vez, na criação do documento (ver [toJson]).
  final DateTime? createdAt;

  // Aluno
  final String? unitId;
  final StudentModality? modality;

  // Professor
  final String? specialty;
  final int? studentCapacity;

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
    this.createdAt,
    this.unitId,
    this.modality,
    this.specialty,
    this.studentCapacity,
  });

  /// Documento completo, usado somente na criação. Edições posteriores
  /// gravam apenas os campos alterados, para não sobrescrever `createdAt`.
  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'type': type.name,
    if (createdAt != null) 'createdAt': createdAt!.toUtc().toIso8601String(),
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
    if (unitId != null) 'unitId': unitId,
    if (modality != null) 'modality': modality!.name,
    if (specialty != null) 'specialty': specialty,
    if (studentCapacity != null) 'studentCapacity': studentCapacity,
  };

  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    return UserModel(
      id: documentId,
      name: json['name'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      type: _parseUserType(json['type'] as String?),
      responsable: json['responsable'] as String?,
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
      createdAt: _parseDateTime(json['createdAt']),
      unitId: json['unitId'] as String?,
      modality: StudentModality.values.asNameMap()[json['modality']],
      specialty: json['specialty'] as String?,
      studentCapacity: (json['studentCapacity'] as num?)?.toInt(),
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
      createdAt: createdAt,
      unitId: unitId,
      modality: modality,
      specialty: specialty,
      studentCapacity: studentCapacity,
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
