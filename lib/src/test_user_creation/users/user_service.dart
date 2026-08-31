import 'auth/auth_repository.dart';
import 'user_repository.dart';
import 'user_model.dart';

class UserService {
  final AuthRepository _authRepo;
  final UserRepository _userRepo;

  UserService(this._authRepo, this._userRepo);

  Future<void> registerStudent(
    String name,
    String email,
    String password,
  ) async {
    if (name.trim().isEmpty || email.trim().isEmpty) {
      throw ArgumentError('Name and email cannot be empty.');
    }

    final authUser = await _authRepo.signUp(email, password);
    if (authUser == null) {
      throw Exception('Authentication failed to yield a valid user token.');
    }

    final userModel = UserModel(
      id: authUser.uid,
      name: name.trim(),
      email: email.trim(),
    );

    await _userRepo.createUser(userModel);
  }
}
