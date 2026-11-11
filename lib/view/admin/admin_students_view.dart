import 'package:academiagrazi/theme/app_font_size.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/admin/admin_student_service.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/admin/admin_student_details_view.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:academiagrazi/view/components/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Aba Alunos do admin: todos os alunos, com busca por nome e filtro por
/// modalidade. Tocar em um aluno abre os dados e a edição do vínculo.
class AdminStudentsView extends StatefulWidget {
  const AdminStudentsView({super.key});

  @override
  State<AdminStudentsView> createState() => _AdminStudentsViewState();
}

class _AdminStudentsViewState extends State<AdminStudentsView> {
  final AdminStudentService _service = locator<AdminStudentService>();
  final TextEditingController _search = TextEditingController();

  late Stream<List<UserModel>> _students;
  late Stream<List<UserModel>> _instructors;
  StudentModalityFilter _filter = StudentModalityFilter.all;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _subscribe() {
    _students = _service.streamStudents();
    _instructors = _service.streamInstructors();
  }

  void _reload() => setState(_subscribe);

  void _open(UserModel student) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminStudentDetailsView(studentId: student.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Alunos', showBackButton: false),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: StreamBuilder<List<UserModel>>(
            stream: _instructors,
            builder: (context, instructorsSnapshot) {
              // Sem os professores a lista ainda funciona; só sem os nomes.
              final instructorNames = {
                for (final instructor
                    in instructorsSnapshot.data ?? const <UserModel>[])
                  instructor.id: instructor.name,
              };
              return StreamBuilder<List<UserModel>>(
                stream: _students,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    debugPrint('Erro ao carregar alunos: ${snapshot.error}');
                    return _Message(
                      icon: Icons.cloud_off_outlined,
                      text: 'Não foi possível carregar os alunos.',
                      action: TextButton(
                        key: const Key('botao_tentar_alunos'),
                        onPressed: _reload,
                        child: const Text('Tentar novamente'),
                      ),
                    );
                  }
                  final students = snapshot.data;
                  if (students == null) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }
                  return _content(students, instructorNames);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _content(
    List<UserModel> students,
    Map<String, String> instructorNames,
  ) {
    final filtered = filterStudents(
      students,
      query: _search.text,
      modality: _filter,
    );
    final remote =
        students.where((s) => s.modality == StudentModality.remote).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        TextField(
          key: const Key('campo_busca_aluno_admin'),
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Buscar aluno pelo nome',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterChip(
              StudentModalityFilter.all,
              'Todos (${students.length})',
            ),
            _filterChip(StudentModalityFilter.remote, 'Remotos ($remote)'),
            _filterChip(StudentModalityFilter.onSite, 'Presenciais'),
            _filterChip(StudentModalityFilter.undefined, 'Sem modalidade'),
          ],
        ),
        const SizedBox(height: 16),
        if (students.isEmpty)
          const _Message(
            icon: Icons.people_outline,
            text:
                'Nenhum aluno cadastrado ainda.\n'
                'Os alunos entram pelo código de convite do professor.',
          )
        else if (filtered.isEmpty)
          const _Message(
            icon: Icons.search_off,
            text: 'Nenhum aluno encontrado com esse filtro.',
          )
        else
          for (final student in filtered) ...[
            _StudentTile(
              student: student,
              instructorName: instructorNames[student.responsable],
              onTap: () => _open(student),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _filterChip(StudentModalityFilter filter, String label) {
    return ChoiceChip(
      key: Key('filtro_alunos_${filter.name}'),
      label: Text(label),
      selected: _filter == filter,
      selectedColor: AppColors.avatarBackground,
      onSelected: (_) => setState(() => _filter = filter),
    );
  }
}

/// Rótulo da modalidade do aluno em pt-BR.
String modalityLabel(StudentModality? modality) => switch (modality) {
  StudentModality.remote => 'Remoto',
  StudentModality.onSite => 'Presencial',
  null => 'Sem modalidade',
};

class _StudentTile extends StatelessWidget {
  final UserModel student;
  final String? instructorName;
  final VoidCallback onTap;

  const _StudentTile({
    required this.student,
    required this.instructorName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = student.name.trim().isEmpty ? 'Sem nome' : student.name;
    final subtitle = [
      instructorName == null || instructorName!.isEmpty
          ? 'Sem professor'
          : instructorName!,
      modalityLabel(student.modality),
    ].join(' · ');

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('aluno_admin_${student.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              UserAvatar(
                photoUrl: student.photoUrl,
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
                      name,
                      style: GoogleFonts.barlowCondensed(
                        fontSize: AppFontSize.small,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.barlowCondensed(
                        fontSize: AppFontSize.caption,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (student.modality == StudentModality.remote)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.laptop_chromebook,
                    size: 18,
                    color: AppColors.primaryDark,
                  ),
                ),
              const Icon(Icons.chevron_right, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;

  const _Message({required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppColors.textSecondary),
          const SizedBox(height: 12),
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
