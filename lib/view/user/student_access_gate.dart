import 'package:academiagrazi/config/business_rules.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/memberships/membership_model.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/memberships/membership_schedule.dart';
import 'package:academiagrazi/service/memberships/membership_service.dart';
import 'package:academiagrazi/service/memberships/money.dart';
import 'package:academiagrazi/service/users/register_user.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/theme/app_font_size.dart';
import 'package:academiagrazi/view/components/brand_heading.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Libera a área do aluno só quando não há mensalidade vencida há mais de
/// [BusinessRules.membershipBlockGraceDays] dias (ver `isAccessBlocked`).
///
/// Escuta o plano em tempo real: quando o admin registra o pagamento, o app
/// libera sozinho. Se o plano não puder ser lido (sem conexão, por exemplo),
/// o acesso fica liberado; o bloqueio é uma regra de negócio, não de
/// segurança, e não deve travar quem está em dia.
class StudentAccessGate extends StatefulWidget {
  final String studentId;
  final Widget child;

  /// Relógio injetável para os testes.
  final DateTime Function() clock;

  const StudentAccessGate({
    super.key,
    required this.studentId,
    required this.child,
    this.clock = DateTime.now,
  });

  @override
  State<StudentAccessGate> createState() => _StudentAccessGateState();
}

class _StudentAccessGateState extends State<StudentAccessGate> {
  late final Stream<MembershipModel?> _membership = locator<MembershipService>()
      .streamActiveMembership(widget.studentId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MembershipModel?>(
      stream: _membership,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Erro ao conferir mensalidades: ${snapshot.error}');
          return widget.child;
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        final membership = snapshot.data;
        if (!isAccessBlocked(membership, widget.clock())) return widget.child;
        return OverdueBlockedView(
          studentId: widget.studentId,
          summary: summarizeMembership(membership!, widget.clock()),
        );
      },
    );
  }
}

/// Aviso de acesso bloqueado por mensalidade em atraso.
class OverdueBlockedView extends StatefulWidget {
  final String studentId;
  final MembershipSummary summary;

  const OverdueBlockedView({
    super.key,
    required this.studentId,
    required this.summary,
  });

  @override
  State<OverdueBlockedView> createState() => _OverdueBlockedViewState();
}

class _OverdueBlockedViewState extends State<OverdueBlockedView> {
  late final Future<String?> _instructorName = _loadInstructorName();

  Future<String?> _loadInstructorName() async {
    try {
      final users = locator<RegisterUserService>();
      final UserModel? student = await users.getUserById(widget.studentId);
      final instructorId = student?.responsable;
      if (instructorId == null) return null;
      final name = (await users.getUserById(instructorId))?.name.trim();
      return name == null || name.isEmpty ? null : name;
    } catch (error) {
      debugPrint('Erro ao carregar professor responsável: $error');
      return null;
    }
  }

  Future<void> _signOut() async {
    try {
      await locator<FirebaseAuth>().signOut();
    } catch (error) {
      debugPrint('Erro ao sair: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final body = GoogleFonts.barlowCondensed(
      fontSize: AppFontSize.body,
      color: AppColors.textSecondary,
      letterSpacing: 0.2,
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lock_clock_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  BrandHeading(
                    'Acesso pausado',
                    complement: 'Mensalidade em aberto',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Seu acesso ao app está pausado porque há mensalidade '
                    'vencida há mais de ${BusinessRules.membershipBlockGraceDays} '
                    'dias.',
                    style: body,
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<String?>(
                    future: _instructorName,
                    builder: (context, snapshot) {
                      final name = snapshot.data;
                      return Text(
                        name == null
                            ? 'Entre em contato com seu professor responsável '
                                'para regularizar.'
                            : 'Entre em contato com seu professor '
                                'responsável, $name, para regularizar.',
                        key: const Key('aviso_contato_professor'),
                        style: body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Assim que o pagamento for registrado, o app libera '
                    'sozinho. Bora voltar a treinar!',
                    style: body,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '${summary.overdueCount} '
                      '${summary.overdueCount == 1 ? 'mensalidade' : 'mensalidades'} '
                      'em aberto · ${formatBrl(summary.overdueCents)}',
                      key: const Key('resumo_bloqueio'),
                      style: GoogleFonts.barlowCondensed(
                        fontSize: AppFontSize.subtitle,
                        fontWeight: FontWeight.bold,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      key: const Key('botao_sair_bloqueio'),
                      onPressed: _signOut,
                      child: const Text('Sair'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
