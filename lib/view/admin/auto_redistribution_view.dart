import 'package:academiagrazi/view/components/brand_heading.dart';
import 'package:academiagrazi/theme/app_font_size.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/admin/admin_student_service.dart';
import 'package:academiagrazi/service/admin/redistribution.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Prévia e aplicação da redistribuição automática: cada professor fica com
/// uma fatia de alunos proporcional à própria capacidade.
///
/// Ao aplicar, volta para a tela anterior com o número de alunos movidos.
class AutoRedistributionView extends StatefulWidget {
  const AutoRedistributionView({super.key});

  @override
  State<AutoRedistributionView> createState() => _AutoRedistributionViewState();
}

class _AutoRedistributionViewState extends State<AutoRedistributionView> {
  final AdminStudentService _service = locator<AdminStudentService>();
  late Future<RedistributionPlan> _plan;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _plan = _service.planAutomaticRedistribution();
  }

  void _reload() {
    setState(() => _plan = _service.planAutomaticRedistribution());
  }

  Future<void> _apply(RedistributionPlan plan) async {
    setState(() => _applying = true);
    try {
      await _service.moveStudents(plan.moves);
      if (!mounted) return;
      Navigator.of(context).pop(plan.moves.length);
    } catch (error) {
      debugPrint('Erro ao redistribuir alunos: $error');
      if (!mounted) return;
      setState(() => _applying = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Não conseguimos aplicar a redistribuição agora. Revise a prévia e '
              'tente novamente.',
            ),
          ),
        );
      // Parte dos alunos pode ter mudado: recalcula a prévia.
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Redistribuição automática'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: FutureBuilder<RedistributionPlan>(
            future: _plan,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint(
                  'Erro ao calcular redistribuição: ${snapshot.error}',
                );
                return _Message(
                  text: 'Não conseguimos calcular a redistribuição agora.',
                  action: TextButton(
                    key: const Key('botao_tentar_redistribuicao'),
                    onPressed: _reload,
                    child: const Text('Tentar novamente'),
                  ),
                );
              }
              final plan = snapshot.data;
              if (plan == null) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (plan.instructors.isEmpty) {
                return const _Message(
                  text: 'Cadastre professores para redistribuir os alunos.',
                );
              }
              if (plan.isEmpty) {
                return const _Message(
                  text:
                      'A equipe já está equilibrada pela capacidade de cada '
                      'professor. Nenhum aluno precisa mudar.',
                );
              }
              return _preview(plan);
            },
          ),
        ),
      ),
    );
  }

  Widget _preview(RedistributionPlan plan) {
    final names = {for (final i in plan.instructors) i.id: i.name};
    final fromUnassigned =
        plan.moves.where((move) => move.fromInstructorId == null).length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            children: [
              BrandHeading('Prévia', complement: 'Redistribuição'),
              const SizedBox(height: 4),
              Text(
                'Cada professor recebe alunos na proporção da sua '
                'capacidade. Mudam primeiro os alunos cadastrados mais '
                'recentemente. A ficha atual de cada aluno continua valendo '
                'até o novo professor publicar outra.',
                style: GoogleFonts.barlowCondensed(
                  fontSize: AppFontSize.caption,
                  height: 1.4,
                  color: AppColors.slateText,
                ),
              ),
              const SizedBox(height: 16),
              _Card(
                child: Text(
                  '${plan.moves.length} aluno(s) vão mudar de professor'
                  '${fromUnassigned > 0 ? ', incluindo $fromUnassigned sem professor' : ''}.',
                  key: const Key('resumo_redistribuicao'),
                  style: GoogleFonts.barlowCondensed(
                    fontSize: AppFontSize.small,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  children: [
                    for (final instructor in plan.instructors)
                      _InstructorRow(
                        instructor: instructor,
                        before: plan.before[instructor.id] ?? 0,
                        after: plan.after[instructor.id] ?? 0,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Card(
                padding: EdgeInsets.zero,
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: const Key('lista_alunos_redistribuicao'),
                    title: Text(
                      'Ver alunos que mudam',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: AppFontSize.small,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    children: [
                      for (final move in plan.moves)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  move.studentName.trim().isEmpty
                                      ? 'Sem nome'
                                      : move.studentName,
                                  style: GoogleFonts.barlowCondensed(
                                    fontSize: AppFontSize.caption,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  '${move.fromInstructorId == null ? 'Sem professor' : names[move.fromInstructorId] ?? '-'}'
                                  ' → ${names[move.toInstructorId] ?? '-'}',
                                  textAlign: TextAlign.end,
                                  style: GoogleFonts.barlowCondensed(
                                    fontSize: AppFontSize.caption,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                key: const Key('botao_aplicar_redistribuicao'),
                onPressed: _applying ? null : () => _apply(plan),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.accentText,
                ),
                icon:
                    _applying
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.sync),
                label: const Text('Aplicar redistribuição'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InstructorRow extends StatelessWidget {
  final RedistributionInstructor instructor;
  final int before;
  final int after;

  const _InstructorRow({
    required this.instructor,
    required this.before,
    required this.after,
  });

  @override
  Widget build(BuildContext context) {
    final changed = before != after;
    return Padding(
      key: Key('linha_redistribuicao_${instructor.id}'),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instructor.name.isEmpty
                      ? 'Professor sem nome'
                      : instructor.name,
                  style: GoogleFonts.barlowCondensed(
                    fontSize: AppFontSize.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Capacidade ${instructor.capacity}',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: AppFontSize.caption,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$before → $after',
            style: GoogleFonts.barlowCondensed(
              fontSize: AppFontSize.title,
              fontWeight: FontWeight.bold,
              color: changed ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
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
