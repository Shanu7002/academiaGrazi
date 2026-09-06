enum UserType { admin, professor, user }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserType type;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.type = UserType.user,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'type': type.name,
    'createdAt': DateTime.now().toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    return UserModel(
      id: documentId,
      name: json['name'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      type: _parseUserType(json['type'] as String?),
    );
  }

  static UserType _parseUserType(String? typeString) {
    switch (typeString) {
      case 'admin':
        return UserType.admin;
      case 'professor':
        return UserType.professor;
      case 'user':
      default:
        return UserType.user;
    }
  }
}
