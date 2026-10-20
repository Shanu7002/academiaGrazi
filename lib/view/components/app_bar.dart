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

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.backgroundColor = AppColors.surface,
    this.onNotificationPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Exibe a seta somente quando existe
    // uma página anterior para retornar.
    final bool podeVoltar = ModalRoute.of(context)?.canPop ?? false;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 16,

      title: Row(
        children: [
          if (podeVoltar) ...[
            IconButton(
              key: const Key('appbar_voltar'),
              tooltip: 'Voltar',
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context).maybePop();
              },
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.completedBorder,
                size: 18,
              ),
            ),
            const SizedBox(width: 6),
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
