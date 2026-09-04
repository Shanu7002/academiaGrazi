import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/users/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> registerUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.id).set(user.toJson());
    } catch (e) {
      throw Exception('Failed to insert user into Firebase: $e');
    }
  }
}
