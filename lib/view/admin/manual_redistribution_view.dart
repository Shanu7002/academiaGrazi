import 'package:academiagrazi/theme/app_font_size.dart';
import 'package:academiagrazi/config/business_rules.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/admin/admin_student_service.dart';
import 'package:academiagrazi/service/admin/redistribution.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:academiagrazi/view/components/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Origem "Sem professor" no seletor (o id real nunca é vazio).
const String _unassigned = '';

/// Redistribuição manual: escolhe o professor de origem, marca os alunos e
/// escolhe o professor de destino.
class ManualRedistributionView extends StatefulWidget {
  /// Professor de origem já selecionado (ex.: aberto pelos detalhes dele).
  final String? initialFromInstructorId;

  const ManualRedistributionView({super.key, this.initialFromInstructorId});

  @override
  State<ManualRedistributionView> createState() =>
      _ManualRedistributionViewState();
}

class _ManualRedistributionViewState extends State<ManualRedistributionView> {
  final AdminStudentService _service = locator<AdminStudentService>();
  late Stream<List<UserModel>> _students;
  late Stream<List<UserModel>> _instructors;

  String? _from;
  String? _to;
  final Set<String> _selected = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _from = widget.initialFromInstructorId;
    _subscribe();
  }

  void _subscribe() {
    _students = _service.streamStudents();
    _instructors = _service.streamInstructors();
  }

  void _reload() => setState(_subscribe);

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Alunos da origem escolhida; quem aponta para um professor que não
  /// existe mais conta como sem professor.
  List<UserModel> _studentsOf(
    String from,
    List<UserModel> students,
    Set<String> instructorIds,
  ) {
    return students.where((student) {
      final current = student.responsable;
      final assigned = current != null && instructorIds.contains(current);
      return from == _unassigned ? !assigned : current == from;
    }).toList();
  }

  Future<void> _move(
    List<UserModel> origin,
    UserModel destination,
    String fromName,
  ) async {
    final chosen = origin.where((s) => _selected.contains(s.id)).toList();
    final count = chosen.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('Mover $count aluno(s)?'),
            content: Text(
              'De $fromName para ${destination.name}. A ficha atual de cada '
              'aluno continua valendo até ${destination.name} publicar uma '
              'nova.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                key: const Key('botao_confirmar_mover_alunos'),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Mover'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await _service.moveStudents([
        for (final student in chosen)
          StudentMove(
            studentId: student.id,
            studentName: student.name,
            fromInstructorId: _from == _unassigned ? null : _from,
            toInstructorId: destination.id,
          ),
      ]);
      if (!mounted) return;
      setState(_selected.clear);
      _showMessage('$count aluno(s) movido(s) para ${destination.name}.');
    } catch (error) {
      debugPrint('Erro ao mover alunos: $error');
      if (!mounted) return;
      _showMessage('Não foi possível mover os alunos. Tente novamente.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Redistribuição manual'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: StreamBuilder<List<UserModel>>(
            stream: _instructors,
            builder: (context, instructorsSnapshot) {
              return StreamBuilder<List<UserModel>>(
                stream: _students,
                builder: (context, studentsSnapshot) {
                  final error =
                      instructorsSnapshot.error ?? studentsSnapshot.error;
                  if (error != null) {
                    debugPrint('Erro ao carregar redistribuição: $error');
                    return _Message(
                      text: 'Não foi possível carregar alunos e professores.',
                      action: TextButton(
                        key: const Key('botao_tentar_redistribuicao_manual'),
                        onPressed: _reload,
                        child: const Text('Tentar novamente'),
                      ),
                    );
                  }
                  final instructors = instructorsSnapshot.data;
                  final students = studentsSnapshot.data;
                  if (instructors == null || students == null) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }
                  if (instructors.length < 2 &&
                      students.every(
                        (s) => instructors.any((i) => i.id == s.responsable),
                      )) {
                    return const _Message(
                      text:
                          'É preciso ter pelo menos dois professores para '
                          'redistribuir alunos.',
                    );
                  }
                  return _form(instructors, students);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _form(List<UserModel> instructors, List<UserModel> students) {
    final ids = {for (final i in instructors) i.id};
    final counts = <String, int>{for (final id in ids) id: 0, _unassigned: 0};
    for (final student in students) {
      final current = student.responsable;
      final key =
          current != null && ids.contains(current) ? current : _unassigned;
      counts[key] = counts[key]! + 1;
    }
    final from = _from != null && (counts.containsKey(_from)) ? _from : null;
    final origin =
        from == null ? const <UserModel>[] : _studentsOf(from, students, ids);
    _selected.retainWhere((id) => origin.any((s) => s.id == id));
    final destinations =
        instructors.where((instructor) => instructor.id != from).toList();
    final destination =
        destinations.where((instructor) => instructor.id == _to).firstOrNull;
    final fromName =
        from == _unassigned
            ? 'Sem professor'
            : instructors.where((i) => i.id == from).firstOrNull?.name ?? '';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            children: [
              DropdownButtonFormField<String>(
                key: const Key('campo_origem_redistribuicao'),
                initialValue: from,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'De (professor de origem)',
                ),
                items: [
                  for (final instructor in instructors)
                    DropdownMenuItem(
                      value: instructor.id,
                      child: Text(
                        '${instructor.name} (${counts[instructor.id]} alunos)',
                      ),
                    ),
                  if (counts[_unassigned]! > 0)
                    DropdownMenuItem(
                      value: _unassigned,
                      child: Text(
                        'Sem professor (${counts[_unassigned]} alunos)',
                      ),
                    ),
                ],
                onChanged:
                    (value) => setState(() {
                      _from = value;
                      _selected.clear();
                      if (_to == value) _to = null;
                    }),
              ),
              const SizedBox(height: 16),
              if (from == null)
                const _Message(text: 'Escolha o professor de origem.')
              else if (origin.isEmpty)
                const _Message(text: 'Este professor não tem alunos.')
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_selected.length} de ${origin.length} selecionado(s)',
                        style: GoogleFonts.barlowCondensed(
                          fontSize: AppFontSize.caption,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slateText,
                        ),
                      ),
                    ),
                    TextButton(
                      key: const Key('botao_selecionar_todos'),
                      onPressed:
                          () => setState(() {
                            if (_selected.length == origin.length) {
                              _selected.clear();
                            } else {
                              _selected.addAll(origin.map((s) => s.id));
                            }
                          }),
                      child: Text(
                        _selected.length == origin.length
                            ? 'Limpar seleção'
                            : 'Selecionar todos',
                      ),
                    ),
                  ],
                ),
                for (final student in origin)
                  CheckboxListTile(
                    key: Key('selecionar_aluno_${student.id}'),
                    contentPadding: EdgeInsets.zero,
                    value: _selected.contains(student.id),
                    onChanged:
                        (checked) => setState(() {
                          if (checked == true) {
                            _selected.add(student.id);
                          } else {
                            _selected.remove(student.id);
                          }
                        }),
                    secondary: UserAvatar(
                      photoUrl: student.photoUrl,
                      size: 36,
                      backgroundColor: AppColors.avatarBackground,
                      iconColor: AppColors.primary,
                    ),
                    title: Text(
                      student.name.trim().isEmpty ? 'Sem nome' : student.name,
                    ),
                  ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey('campo_destino_redistribuicao_$from'),
                  initialValue: destination?.id,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Para (professor de destino)',
                  ),
                  items: [
                    for (final instructor in destinations)
                      DropdownMenuItem(
                        value: instructor.id,
                        child: Text(
                          '${instructor.name} · ${counts[instructor.id]}/'
                          '${instructor.studentCapacity ?? BusinessRules.defaultStudentCapacity} alunos',
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _to = value),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    key: const Key('botao_mover_alunos'),
                    onPressed:
                        _saving || _selected.isEmpty || destination == null
                            ? null
                            : () => _move(origin, destination, fromName),
                    child: Text(
                      _selected.isEmpty
                          ? 'Selecione os alunos'
                          : 'Mover ${_selected.length} aluno(s)',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final Widget? action;

  const _Message({required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
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
    );
  }
}
