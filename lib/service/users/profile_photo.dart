import 'dart:convert';
import 'dart:typed_data';

import 'package:academiagrazi/config/cloudinary_config.dart';
import 'package:http/http.dart' as http;

/// Envia a foto de perfil para o Cloudinary e devolve a URL pública.
class ProfilePhotoService {
  final http.Client _client;
  final String _cloudName;
  final String _uploadPreset;

  // coverage:ignore-start
  ProfilePhotoService({
    http.Client? client,
    String cloudName = CloudinaryConfig.cloudName,
    String uploadPreset = CloudinaryConfig.uploadPreset,
  }) : _client = client ?? http.Client(),
       _cloudName = cloudName,
       _uploadPreset = uploadPreset;
  // coverage:ignore-end

  Future<String> upload({
    required Uint8List bytes,
    required String fileName,
    required String userId,
  }) async {
    if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
      throw Exception(
        'Erro ao enviar a foto: Cloudinary não configurado '
        '(CLOUDINARY_CLOUD_NAME / CLOUDINARY_UPLOAD_PRESET).',
      );
    }

    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse(
              'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
            ),
          )
          ..fields['upload_preset'] = _uploadPreset
          ..fields['public_id'] =
              '${userId}_${DateTime.now().millisecondsSinceEpoch}'
          ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: fileName),
          );

    try {
      final response = await http.Response.fromStream(
        await _client.send(request),
      );

      if (response.statusCode != 200) {
        throw Exception('status ${response.statusCode} - ${response.body}');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final url = body['secure_url'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('resposta sem secure_url');
      }
      return url;
    } catch (e) {
      throw Exception('Erro ao enviar a foto: $e');
    }
  }

  /// Gera a URL de uma miniatura quadrada, recortada no rosto.
  static String thumbnailUrl(String url, {int size = 160}) {
    const marker = '/image/upload/';
    if (!url.contains(marker)) return url;
    return url.replaceFirst(
      marker,
      '${marker}c_fill,g_face,w_$size,h_$size,q_auto,f_auto/',
    );
  }
}
