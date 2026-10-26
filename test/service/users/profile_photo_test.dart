import 'dart:convert';
import 'dart:typed_data';

import 'package:academiagrazi/service/users/profile_photo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final bytes = Uint8List.fromList([1, 2, 3]);

  group('ProfilePhotoService |', () {
    test('upload envia o preset e devolve a secure_url', () async {
      late http.BaseRequest sentRequest;
      String? sentBody;

      final client = MockClient.streaming((request, bodyStream) async {
        sentRequest = request;
        sentBody = await bodyStream.bytesToString();
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              jsonEncode({
                'secure_url':
                    'https://res.cloudinary.com/demo/image/upload/a.jpg',
              }),
            ),
          ),
          200,
        );
      });

      final service = ProfilePhotoService(
        client: client,
        cloudName: 'demo',
        uploadPreset: 'avatars_unsigned',
      );

      final url = await service.upload(
        bytes: bytes,
        fileName: 'foto.jpg',
        userId: 'uid_123',
      );

      expect(url, 'https://res.cloudinary.com/demo/image/upload/a.jpg');
      expect(
        sentRequest.url.toString(),
        'https://api.cloudinary.com/v1_1/demo/image/upload',
      );
      expect(sentBody, contains('avatars_unsigned'));
      expect(sentBody, contains('uid_123_'));
      expect(sentBody, contains('filename="foto.jpg"'));
    });

    test('upload lança exceção quando o Cloudinary recusa', () async {
      final client = MockClient(
        (_) async => http.Response('{"error":{"message":"bad"}}', 400),
      );

      final service = ProfilePhotoService(
        client: client,
        cloudName: 'demo',
        uploadPreset: 'avatars_unsigned',
      );

      expect(
        () => service.upload(bytes: bytes, fileName: 'a.jpg', userId: 'u'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Erro ao enviar a foto'),
          ),
        ),
      );
    });

    test('upload lança exceção quando não está configurado', () async {
      final service = ProfilePhotoService(
        client: MockClient((_) async => http.Response('', 200)),
        cloudName: '',
        uploadPreset: '',
      );

      expect(
        () => service.upload(bytes: bytes, fileName: 'a.jpg', userId: 'u'),
        throwsA(isA<Exception>()),
      );
    });

    test('thumbnailUrl insere a transformação na URL do Cloudinary', () {
      expect(
        ProfilePhotoService.thumbnailUrl(
          'https://res.cloudinary.com/demo/image/upload/v1/avatars/a.jpg',
          size: 100,
        ),
        'https://res.cloudinary.com/demo/image/upload/'
        'c_fill,g_face,w_100,h_100,q_auto,f_auto/v1/avatars/a.jpg',
      );
      expect(
        ProfilePhotoService.thumbnailUrl('https://outro.com/a.jpg'),
        'https://outro.com/a.jpg',
      );
    });
  });
}
