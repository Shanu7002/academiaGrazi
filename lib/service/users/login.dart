import 'dart:developer';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginService {
  final FirebaseFirestore _db;

  LoginService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final DocumentSnapshot snapshot =
          await _db.collection("users").doc(uid).get();

      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromJson(
          snapshot.data() as Map<String, dynamic>,
          snapshot.id,
        );
      }

      return null;
    } catch (e) {
      log("Database login failed", error: e);
      return null;
    }
  }
}
