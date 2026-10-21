import 'dart:async';

import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/users/register_instructor.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Mostra o código de convite atual do professor. O código vale 15 minutos;
/// quando vence, o card busca (e, se preciso, gera) o próximo sozinho.
class InviteCodeCard extends StatefulWidget {
  final String instructorId;
  final String title;
  final String? description;

  const InviteCodeCard({
    super.key,
    required this.instructorId,
    this.title = 'Código de convite',
    this.description,
  });

  @override
  State<InviteCodeCard> createState() => _InviteCodeCardState();
}

class _InviteCodeCardState extends State<InviteCodeCard> {
  final RegisterInstructorService _service =
      locator<RegisterInstructorService>();
  late Future<InstructorInviteCode> _code;
  Timer? _renewTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _renewTimer?.cancel();
    super.dispose();
  }

  void _load() {
    _renewTimer?.cancel();
    final future = _service.getCurrentInviteCode(widget.instructorId);
    setState(() {
      _code = future;
    });
    future.then((invite) {
      if (!mounted) return;
      var wait = invite.expiresAt.difference(DateTime.now());
      if (wait.isNegative) wait = Duration.zero;
      _renewTimer = Timer(wait + const Duration(seconds: 1), () {
        if (mounted) _load();
      });
    }, onError: (_) {});
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Código de convite copiado.')));
  }

  static String _formatTime(DateTime date) {
    final local = date.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: .5,
      color: AppColors.slateText,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: AppColors.avatarBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: FutureBuilder<InstructorInviteCode>(
        future: _code,
        builder: (context, snapshot) {
          final invite = snapshot.data;

          Widget content;
          if (snapshot.hasError) {
            content = Text(
              'Não foi possível carregar o código.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.slateText,
              ),
            );
          } else if (invite == null) {
            content = const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            );
          } else {
            content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.code,
                  key: const Key('codigo_convite'),
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  'Válido até ${_formatTime(invite.expiresAt)} • '
                  'renova a cada 15 min',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.slateText,
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              const Icon(Icons.vpn_key_outlined, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title.toUpperCase(), style: labelStyle),
                    const SizedBox(height: 4),
                    content,
                    if (widget.description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.description!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.textBody,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (invite != null)
                IconButton(
                  key: const Key('botao_copiar_codigo'),
                  tooltip: 'Copiar código',
                  onPressed: () => _copy(invite.code),
                  icon: const Icon(Icons.copy, color: AppColors.primary),
                )
              else if (snapshot.hasError)
                IconButton(
                  key: const Key('botao_recarregar_codigo'),
                  tooltip: 'Tentar novamente',
                  onPressed: _load,
                  icon: const Icon(Icons.refresh, color: AppColors.primary),
                ),
            ],
          );
        },
      ),
    );
  }
}
