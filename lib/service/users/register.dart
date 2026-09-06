import "package:cloud_firestore/cloud_firestore.dart";
import "../../models/users/user_model.dart";

class RegisterService {
  final FirebaseFirestore _db;

  // coverage:ignore-start
  RegisterService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  // coverage:ignore-end

  Future<void> registerUser(UserModel user) async {
    await _db.collection("users").doc(user.id).set(user.toJson());
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (!doc.exists) {
      return null;
    }

    return UserModel.fromJson(doc.data()!, doc.id);
  }
}
