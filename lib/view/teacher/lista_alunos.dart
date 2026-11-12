import 'package:academiagrazi/view/components/user_greeting.dart';
import 'package:academiagrazi/theme/app_font_size.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:academiagrazi/view/components/instructor_schedule_builder.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class ListaAlunosView extends StatefulWidget {
  const ListaAlunosView({super.key});

  @override
  State<ListaAlunosView> createState() => _ListaAlunosViewState();
}

class _ListaAlunosViewState extends State<ListaAlunosView> {
  /// Professor logado; sem o FirebaseAuth no locator (testes), sem escala.
  final String? _instructorId =
      locator.isRegistered<FirebaseAuth>()
          ? locator<FirebaseAuth>().currentUser?.uid
          : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'GRAZI BRAZ'),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const UserGreeting(),
              const SizedBox(height: 10),
              InstructorScheduleBuilder(
                instructorId: _instructorId,
                builder:
                    (context, schedule) => Text(
                      schedule.currentLabel,
                      style: GoogleFonts.barlowCondensed(
                        color: AppColors.textBody,
                        fontSize: AppFontSize.body,
                      ),
                    ),
              ),
              const SizedBox(height: 20),

              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar aluno...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: AppColors.white90,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.grey,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.white90,
                        minimumSize: const Size(100, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      child: Text(
                        'Todos',
                        style: GoogleFonts.barlowCondensed(
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    const SizedBox(width: 5),

                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.white90,
                        minimumSize: const Size(100, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      child: Text(
                        'Inativos',
                        style: GoogleFonts.barlowCondensed(
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.white90,
                        minimumSize: const Size(100, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      child: Text(
                        'Avaliação Pendente',
                        style: GoogleFonts.barlowCondensed(
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              CardAluno(
                nome: 'Pablo',
                proximoTreino: 'Próximo treino amanhã',
                foto: 'assets/profMarcos.png',
                ativo: true,
                onVerPerfil: () {},
                onEditarPerfil: () {},
                onMensagem: () {},
              ),

              SizedBox(height: 20),

              CardAluno(
                nome: 'Marcos',
                proximoTreino: 'Inativo (12 dias)',
                foto: 'assets/profMarcos.png',
                ativo: false,
                onVerPerfil: () {},
                onEditarPerfil: () {},
                onMensagem: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CardAluno extends StatelessWidget {
  final String nome;
  final String proximoTreino;
  final String foto;
  final bool ativo;
  final VoidCallback onVerPerfil;
  final VoidCallback onEditarPerfil;
  final VoidCallback onMensagem;

  const CardAluno({
    super.key,
    required this.nome,
    required this.proximoTreino,
    required this.foto,
    required this.ativo,
    required this.onVerPerfil,
    required this.onEditarPerfil,
    required this.onMensagem,
  });

  static const Color green = AppColors.primary;
  static const Color red = AppColors.danger;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = ativo ? green : red;
    final String statusTexto = ativo ? 'Ativo' : 'Inativo';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white90,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: green.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  foto,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: GoogleFonts.barlowCondensed(
                        color: AppColors.navy,
                        fontSize: AppFontSize.title,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      proximoTreino,
                      style: GoogleFonts.barlowCondensed(
                        color: AppColors.textBody,
                        fontSize: AppFontSize.caption,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 9, color: statusColor),
                  const SizedBox(width: 5),
                  Text(
                    statusTexto,
                    style: GoogleFonts.barlowCondensed(
                      color: statusColor,
                      fontSize: AppFontSize.caption,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onVerPerfil,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: green,
                    side: const BorderSide(color: green, width: 1.5),
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/iconePerfil.svg',
                        width: 18,
                        height: 18,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Ver perfil',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.barlowCondensed(
                            fontSize: AppFontSize.caption,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              if (ativo)
                Expanded(
                  child: ElevatedButton(
                    onPressed: onEditarPerfil,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: AppColors.white90,
                      elevation: 0,
                      minimumSize: const Size(0, 46),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/editarPerfil.svg',
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(
                            AppColors.white90,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Editar treino',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.barlowCondensed(
                              fontSize: AppFontSize.caption,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton(
                    onPressed: onMensagem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.white90,
                      elevation: 0,
                      minimumSize: const Size(0, 46),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/mensagem.svg',
                          width: 18,
                          height: 18,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Mensagem',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.barlowCondensed(
                              color: AppColors.accentText,
                              fontSize: AppFontSize.caption,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
