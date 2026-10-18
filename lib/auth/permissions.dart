import "package:academiagrazi/models/users/user_model.dart";

class Permissions {
  static bool canCreateInstructor(UserModel currentUser) {
    return currentUser.type == UserType.admin;
  }
}
