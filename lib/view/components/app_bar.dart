import 'package:academiagrazi/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Cabeçalho compartilhado entre aluno e professor.
///
/// Centraliza a identidade visual e permite que cada tela
/// configure seu título, suas ações e sua cor de fundo.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Color backgroundColor;
  final VoidCallback? onNotificationPressed;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.backgroundColor = Colors.blue, // Cor padrão caso nenhuma seja enviada
    this.onNotificationPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Exibe a seta somente quando existe
    // uma página anterior para retornar.
    final bool podeVoltar = ModalRoute.of(context)?.canPop ?? false;

    return AppBar(
      // A seta de voltar é desenhada no título; sem isso o Flutter
      // adiciona uma segunda seta quando a tela pode voltar.
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 16,

      title: Row(
        children: [
          if (showBackButton) ...[
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.completedBorder,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFD6D6D6),
            child: Icon(Icons.person, color: Color(0xFF8A8A8A)),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),

      // Se a tela informar ações próprias, utiliza essas.
      // Caso contrário, mantém o ícone de notificação.
      actions:
          actions ??
          [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                key: const Key('appbar_notificacoes'),
                tooltip: 'Notificações',
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
                onPressed: onNotificationPressed,
              ),
            ),
          ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
