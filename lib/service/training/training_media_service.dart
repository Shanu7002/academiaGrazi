import 'dart:typed_data';

import 'package:academiagrazi/service/users/profile_photo.dart';

/// Reaproveita o servico de imagem ja configurado no projeto.
/// O upload e publico: usar fotos de demonstracao de exercicios, nao dados de saude.
class TrainingMediaService {
  final ProfilePhotoService _uploader;

  TrainingMediaService({ProfilePhotoService? uploader})
    : _uploader = uploader ?? ProfilePhotoService();

  Future<String> upload({
    required Uint8List bytes,
    required String teacherId,
    required String kind,
  }) async {
    if (teacherId.isEmpty ||
        bytes.isEmpty ||
        bytes.lengthInBytes > 8 * 1024 * 1024) {
      throw ArgumentError('Foto invalida. Limite: 8 MB.');
    }
    return _uploader.upload(
      bytes: bytes,
      fileName: '$kind.jpg',
      userId: 'treino_${kind}_$teacherId',
    );
  }
}
