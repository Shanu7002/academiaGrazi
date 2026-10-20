import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfessorDashboardView extends StatefulWidget {
  const ProfessorDashboardView({super.key});

  @override
  State<ProfessorDashboardView> createState() => _ProfessorDashboardViewState();
}

class _ProfessorDashboardViewState extends State<ProfessorDashboardView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Grazi Braz'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá, Marcos',
                    style: GoogleFonts.barlowCondensed(
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 0, 30, 45),
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Bloco atual: Bloco A (Manhã)',
                    style: GoogleFonts.inter(
                      color: const Color.fromARGB(255, 63, 73, 70),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Cards de alunos e presenças.
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(
                              255,
                              2,
                              89,
                              79,
                            ).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 50,
                                  maxHeight: 50,
                                ),
                                child: SvgPicture.asset(
                                  'assets/tresAlunos.svg',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Alunos',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color.fromARGB(255, 0, 90, 79),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '42',
                                style: GoogleFonts.anton(
                                  fontSize: 48,
                                  color: const Color.fromARGB(255, 0, 30, 45),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Permite adaptar o texto
                              // a larguras menores.
                              Flexible(
                                child: Text(
                                  'Ativos',
                                  softWrap: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(
                                      255,
                                      63,
                                      73,
                                      70,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(
                              255,
                              2,
                              89,
                              79,
                            ).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 50,
                                  maxHeight: 50,
                                ),
                                child: SvgPicture.asset(
                                  'assets/presencas.svg',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Evita overflow do título.
                              Flexible(
                                child: Text(
                                  'Presenças',
                                  softWrap: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(255, 0, 90, 79),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '15',
                                style: GoogleFonts.anton(
                                  fontSize: 48,
                                  color: const Color.fromARGB(255, 0, 30, 45),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Evita overflow da legenda.
                              Flexible(
                                child: Text(
                                  'Hoje',
                                  softWrap: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(
                                      255,
                                      63,
                                      73,
                                      70,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Card de risco de evasão.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(
                        255,
                        186,
                        26,
                        26,
                      ).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 50,
                            maxHeight: 50,
                          ),
                          child: SvgPicture.asset(
                            'assets/inativo.svg',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Alunos',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 186, 26, 26),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '3',
                          style: GoogleFonts.anton(
                            fontSize: 48,
                            color: const Color.fromARGB(255, 186, 26, 26),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Risco de evasão',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 63, 73, 70),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // Segundo card existente no código
              // original. Mantido para não modificar
              // a regra visual do outro desenvolvedor.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(
                        255,
                        186,
                        26,
                        26,
                      ).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 50,
                            maxHeight: 50,
                          ),
                          child: SvgPicture.asset(
                            'assets/inativo.svg',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Alunos',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 186, 26, 26),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '3',
                          style: GoogleFonts.anton(
                            fontSize: 48,
                            color: const Color.fromARGB(255, 186, 26, 26),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Risco de evasão',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 63, 73, 70),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
