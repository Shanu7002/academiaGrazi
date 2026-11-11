import 'dart:async';

import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/users/register_user.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/components/user_avatar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Cabeçalho compartilhado entre aluno e professor.
///
/// Centraliza a identidade visual (fundo branco) e permite que cada tela
/// configure seu título e suas ações.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onNotificationPressed;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onNotificationPressed,
  });

  @override
  Widget build(BuildContext context) {
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
          const _CurrentUserAvatar(),

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

/// Foto do usuário logado no cabeçalho. Escuta o documento dele no Firestore,
/// então a foto troca na hora quando ele atualiza o perfil.
class _CurrentUserAvatar extends StatefulWidget {
  const _CurrentUserAvatar();

  @override
  State<_CurrentUserAvatar> createState() => _CurrentUserAvatarState();
}

class _CurrentUserAvatarState extends State<_CurrentUserAvatar> {
  StreamSubscription<UserModel?>? _subscription;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    // Telas testadas isoladamente podem não registrar esses serviços; nesse
    // caso o cabeçalho só mostra o ícone padrão.
    if (!locator.isRegistered<FirebaseAuth>() ||
        !locator.isRegistered<RegisterUserService>()) {
      return;
    }
    try {
      final uid = locator<FirebaseAuth>().currentUser?.uid;
      if (uid == null) return;
      _subscription = locator<RegisterUserService>().watchUserById(uid).listen((
        user,
      ) {
        if (mounted) setState(() => _photoUrl = user?.photoUrl);
      }, onError: (_) {});
    } catch (_) {
      // Sem foto não é motivo para quebrar o cabeçalho.
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UserAvatar(
      key: const Key('appbar_user_avatar'),
      photoUrl: _photoUrl,
      size: 40,
      backgroundColor: const Color(0xFFD6D6D6),
      iconColor: const Color(0xFF8A8A8A),
    );
  }
}
