import 'package:academiagrazi/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Usa a ilustracao real quando ela existe. Falhas de rede nao quebram a tela.
/// Nao simula um player de video: o catalogo fornece fotos ilustrativas.
class StudentExercisePhoto extends StatelessWidget {
  final String? url;
  final double size;

  /// Altura própria para faixas largas; sem ela a foto é quadrada ([size]).
  final double? height;
  final BorderRadius? radius;

  const StudentExercisePhoto({
    super.key,
    required this.url,
    this.size = 64,
    this.height,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = radius ?? BorderRadius.circular(14);
    final uri = Uri.tryParse(url ?? '');
    final valid = uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
    Widget fallback() => Container(
      width: size,
      height: height ?? size,
      decoration: BoxDecoration(
        color: AppColors.thumbnailStart,
        borderRadius: borderRadius,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.fitness_center_outlined, color: AppColors.primary),
    );
    if (!valid) return fallback();
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        url!,
        width: size,
        height: height ?? size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback(),
      ),
    );
  }
}
