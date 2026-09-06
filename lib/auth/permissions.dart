import "package:academiagrazi/models/users/user_model.dart";

class Permissions {
  static bool canCreateInstructor(UserModel currentUser) {
    return currentUser.type == UserType.admin;
  }

  static bool canCreateUser(UserModel currentUser) {
    return currentUser.type == UserType.admin ||
        currentUser.type == UserType.instructor;
  }
}
