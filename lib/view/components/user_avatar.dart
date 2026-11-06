import 'package:academiagrazi/service/users/profile_photo.dart';
import 'package:flutter/material.dart';

/// Avatar circular com a foto de perfil (Cloudinary) de um usuário.
///
/// Sem foto, enquanto carrega ou se a imagem falhar, mostra o ícone padrão.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.photoUrl,
    this.size = 44,
    required this.backgroundColor,
    required this.iconColor,
  });

  final String? photoUrl;
  final double size;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final placeholder = Icon(Icons.person, color: iconColor);
    final url = photoUrl;

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: backgroundColor),
            if (url == null || url.isEmpty)
              placeholder
            else
              Image.network(
                // Pede ao Cloudinary o dobro do tamanho lógico para telas
                // de alta densidade.
                ProfilePhotoService.thumbnailUrl(url, size: (size * 2).round()),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                frameBuilder:
                    (_, child, frame, wasSynchronouslyLoaded) =>
                        wasSynchronouslyLoaded || frame != null
                            ? child
                            : placeholder,
                errorBuilder: (_, __, ___) => placeholder,
              ),
          ],
        ),
      ),
    );
  }
}
