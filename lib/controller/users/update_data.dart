import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateDataController {
  final FirebaseFirestore _db;

  // coverage:ignore-start
  UpdateDataController({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  // coverage:ignore-end

  Future<void> updateHealthProfile({
    required String userId,
    required List<String> conditions,
    required List<String> restrictions,
    required String notes,
  }) async {
    try {
      await _db.collection('users').doc(userId).set({
        'registrationProfile': {
          'health': {
            'conditions': conditions,
            'restrictions': restrictions,
            'notes': notes,
          },
        },
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Erro ao atualizar a ficha de saúde: $e');
    }
  }

  Future<void> updateEmergencyContact({
    required String userId,
    required String name,
    required String phone,
    required String relationship,
  }) async {
    try {
      await _db.collection('users').doc(userId).set({
        'registrationProfile': {
          'emergencyContact': {
            'name': name,
            'phone': phone,
            'relationship': relationship,
          },
        },
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Erro ao atualizar contato de emergência: $e');
    }
  }

  Future<void> updatePhotoUrl({
    required String userId,
    required String photoUrl,
  }) async {
    try {
      await _db.collection('users').doc(userId).set({
        'photoUrl': photoUrl,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Erro ao atualizar a foto de perfil: $e');
    }
  }
}
