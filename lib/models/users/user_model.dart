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
}
