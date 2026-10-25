import 'dart:ui';

import 'package:academiagrazi/firebase_options.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/theme/app_theme.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:academiagrazi/view/welcome_view.dart';
import 'package:academiagrazi/view/teacher/professor_dashboard_view.dart';
import 'package:academiagrazi/view/auth_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class ListaAlunosView extends StatefulWidget {
  const ListaAlunosView({super.key});

  @override
  State<ListaAlunosView> createState() => _ListaAlunosViewState();
}

class _ListaAlunosViewState extends State<ListaAlunosView> {
  static const Color navy = Color(0xFF001E2D);
  static const Color green = Color(0xFF005A4F);
  static const Color textColor = Color(0xFF3F4946);
  static const Color red = Color(0xFFBA1A1A);
  static const Color orange = Color(0xFFA73A03);
  static const Color white = Colors.white;

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
              Text(
                'Olá, Marcos',
                style: GoogleFonts.barlowCondensed(
                  fontWeight: FontWeight.bold,
                  color: navy,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Bloco atual: Bloco A (Manhã)',
                style: GoogleFonts.inter(color: textColor, fontSize: 16),
              ),
              const SizedBox(height: 20),

              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar aluno...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
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
                        backgroundColor: white,
                        minimumSize: const Size(100, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      child: Text(
                        'Todos',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: white,
                        minimumSize: const Size(100, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      child: Text(
                        'Bloco A',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),

                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: white,
                        minimumSize: const Size(100, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      child: Text(
                        'Inativos',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: white,
                        minimumSize: const Size(100, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      child: Text(
                        'Avaliação Pendente',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: navy,
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

  static const Color navy = Color(0xFF001E2D);
  static const Color green = Color(0xFF005A4F);
  static const Color textColor = Color(0xFF3F4946);
  static const Color red = Color(0xFFBA1A1A);

  @override
  Widget build(BuildContext context) {
    final Color statusColor = ativo ? green : red;
    final String statusTexto = ativo ? 'Ativo' : 'Inativo';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: green.withOpacity(0.15),
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
                        color: navy,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      proximoTreino,
                      style: GoogleFonts.inter(color: textColor, fontSize: 13),
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
                    style: GoogleFonts.inter(
                      color: statusColor,
                      fontSize: 12,
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
                          style: GoogleFonts.inter(
                            fontSize: 13,
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
                      foregroundColor: Colors.white,
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
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Editar treino',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
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
                      backgroundColor: const Color.fromARGB(255, 255, 121, 67),
                      foregroundColor: Colors.white,
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
                            style: GoogleFonts.inter(
                              color: const Color.fromARGB(255, 56, 13, 0),
                              fontSize: 13,
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
