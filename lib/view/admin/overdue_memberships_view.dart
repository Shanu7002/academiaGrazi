import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/memberships/membership_model.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/admin/admin_student_service.dart';
import 'package:academiagrazi/service/memberships/membership_schedule.dart';
import 'package:academiagrazi/service/memberships/membership_service.dart';
import 'package:academiagrazi/service/memberships/money.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/theme/app_font_size.dart';
import 'package:academiagrazi/view/admin/admin_student_details_view.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:academiagrazi/view/components/brand_heading.dart';
import 'package:academiagrazi/view/components/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Alunos com mensalidade vencida em aberto. Tocar no aluno abre os
/// detalhes, onde o admin registra o pagamento.
class OverdueMembershipsView extends StatefulWidget {
  /// Relógio injetável para os testes.
  final DateTime Function() clock;

  const OverdueMembershipsView({super.key, this.clock = DateTime.now});

  @override
  State<OverdueMembershipsView> createState() => _OverdueMembershipsViewState();
}

class _OverdueMembershipsViewState extends State<OverdueMembershipsView> {
  late Stream<List<MembershipModel>> _memberships;
  late Stream<List<UserModel>> _students;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    _memberships = locator<MembershipService>().streamActiveMemberships();
    _students = locator<AdminStudentService>().streamStudents();
  }

  void _reload() => setState(_subscribe);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Mensalidades'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: StreamBuilder<List<MembershipModel>>(
            stream: _memberships,
            builder: (context, membershipsSnapshot) {
              return StreamBuilder<List<UserModel>>(
                stream: _students,
                builder: (context, studentsSnapshot) {
                  final error =
                      membershipsSnapshot.error ?? studentsSnapshot.error;
                  if (error != null) {
                    debugPrint('Erro ao carregar mensalidades: $error');
                    return _Message(
                      text: 'Não conseguimos carregar as mensalidades agora.',
                      action: TextButton(
                        key: const Key('botao_tentar_mensalidades'),
                        onPressed: _reload,
                        child: const Text('Tentar novamente'),
                      ),
                    );
                  }
                  final memberships = membershipsSnapshot.data;
                  final students = studentsSnapshot.data;
                  if (memberships == null || students == null) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }
                  return _list(
                    overdueMemberships(memberships, widget.clock()),
                    {for (final student in students) student.id: student},
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _list(
    List<(MembershipModel, MembershipSummary)> overdue,
    Map<String, UserModel> students,
  ) {
    final total = overdue.fold(0, (sum, entry) => sum + entry.$2.overdueCents);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        BrandHeading('Em atraso', complement: 'Mensalidades'),
        const SizedBox(height: 4),
        Text(
          overdue.isEmpty
              ? 'Nenhuma mensalidade vencida em aberto. Tudo em dia!'
              : '${overdue.length} '
                  '${overdue.length == 1 ? 'aluno' : 'alunos'} · '
                  '${formatBrl(total)} em aberto',
          key: const Key('resumo_mensalidades_atraso'),
          style: GoogleFonts.barlowCondensed(
            fontSize: AppFontSize.small,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        for (final (membership, summary) in overdue) ...[
          _OverdueCard(
            membership: membership,
            summary: summary,
            student: students[membership.studentId],
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (_) => AdminStudentDetailsView(
                          studentId: membership.studentId,
                        ),
                  ),
                ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _OverdueCard extends StatelessWidget {
  final MembershipModel membership;
  final MembershipSummary summary;
  final UserModel? student;
  final VoidCallback onTap;

  const _OverdueCard({
    required this.membership,
    required this.summary,
    required this.student,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = student?.name.trim();
    return Material(
      key: Key('card_atraso_${membership.studentId}'),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              UserAvatar(
                photoUrl: student?.photoUrl,
                size: 44,
                backgroundColor: AppColors.avatarBackground,
                iconColor: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name == null || name.isEmpty ? 'Aluno sem nome' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.barlowCondensed(
                        fontSize: AppFontSize.body,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${membership.planName} · ${summary.overdueCount} '
                      '${summary.overdueCount == 1 ? 'mensalidade' : 'mensalidades'}',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: AppFontSize.caption,
                        color: AppColors.textBody,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatBrl(summary.overdueCents),
                style: GoogleFonts.barlowCondensed(
                  fontSize: AppFontSize.body,
                  fontWeight: FontWeight.bold,
                  color: AppColors.danger,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.slateText),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final Widget? action;

  const _Message({required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.barlowCondensed(
                fontSize: AppFontSize.small,
                color: AppColors.textSecondary,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 8), action!],
          ],
        ),
      ),
    );
  }
}
