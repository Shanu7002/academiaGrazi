import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfessorDashboardView extends StatefulWidget {
  const ProfessorDashboardView({super.key});

  @override
  State<ProfessorDashboardView> createState() => _ProfessorDashboardViewState();
}

class _ProfessorDashboardViewState extends State<ProfessorDashboardView> {
  static const Color navy = Color(0xFF001E2D);
  static const Color green = Color(0xFF005A4F);
  static const Color textColor = Color(0xFF3F4946);
  static const Color red = Color(0xFFBA1A1A);
  static const Color orange = Color(0xFFA73A03);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Grazi Braz'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Saudação
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                ],
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _DashboardMetricCard(
                      asset: 'assets/tresAlunos.svg',
                      title: 'Alunos',
                      value: '42',
                      description: 'Ativos',
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _DashboardMetricCard(
                      asset: 'assets/presencas.svg',
                      title: 'Presenças',
                      value: '15',
                      description: 'Hoje',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const _DashboardMetricCard(
                asset: 'assets/inativo.svg',
                title: 'Alunos',
                value: '3',
                description: 'Risco de evasão',
                fullWidth: true,
                accentColor: red,
                shadowColor: red,
              ),

              const SizedBox(height: 15),

              const _DashboardMetricCard(
                asset: 'assets/relogio.svg',
                title: 'Próximo Turno',
                value: 'Bloco B',
                description: '11:00',
                isNextShift: true,
                accentColor: Color(0xFF00564B),
                shadowColor: navy,
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Prioridades',
                    style: GoogleFonts.anton(fontSize: 32, color: navy),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: green,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '3 Alertas',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFA8F0E1),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              const _PriorityCard(
                name: 'Ana Lima',
                description: 'Avaliação vence em dois dias.',
                asset: 'assets/quadradoAviso.svg',
                action: 'Revisar',
                accentColor: orange,
                iconBackgroundColor: Color(0xFFE6A07D),
              ),

              const SizedBox(height: 15),

              const _PriorityCard(
                name: 'Bruno Alves',
                description: '12 dias sem treinar (inativo).',
                asset: 'assets/alertaVermelho.svg',
                action: 'Contatar',
                accentColor: red,
                iconBackgroundColor: Color(0xFFE6A07D),
              ),

              const SizedBox(height: 15),

              const _PriorityCard(
                name: 'Carla Souza',
                description: 'Novo treino solicitado.',
                asset: 'assets/halter.svg',
                action: 'Montar',
                accentColor: green,
                iconBackgroundColor: Color(0xFF84D3CA),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// COMPONENTE REUTILIZÁVEL: CARDS DE MÉTRICAS E PRÓXIMO TURNO
// ============================================================

class _DashboardMetricCard extends StatelessWidget {
  final String asset;
  final String title;
  final String value;
  final String description;
  final bool fullWidth;
  final bool isNextShift;
  final Color accentColor;
  final Color shadowColor;

  const _DashboardMetricCard({
    required this.asset,
    required this.title,
    required this.value,
    required this.description,
    this.fullWidth = false,
    this.isNextShift = false,
    this.accentColor = const Color(0xFF005A4F),
    this.shadowColor = const Color(0xFF02594F),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone e título
          Row(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 50, maxHeight: 50),
                child: SvgPicture.asset(asset, fit: BoxFit.contain),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Conteúdo específico de cada tipo de card
          if (isNextShift) ...[
            Text(
              value,
              style: GoogleFonts.anton(
                fontSize: 32,
                color: const Color(0xFF001E2D),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: GoogleFonts.anton(
                    fontSize: 48,
                    color:
                        fullWidth
                            ? const Color(0xFFBA1A1A)
                            : const Color(0xFF001E2D),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3F4946),
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

// ============================================================
// COMPONENTE REUTILIZÁVEL: CARD DE PRIORIDADE
// ============================================================

class _PriorityCard extends StatelessWidget {
  final String name;
  final String description;
  final String asset;
  final String action;
  final Color accentColor;
  final Color iconBackgroundColor;

  const _PriorityCard({
    required this.name,
    required this.description,
    required this.asset,
    required this.action,
    required this.accentColor,
    required this.iconBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF001E2D).withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Faixa lateral colorida
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),

            // Conteúdo do card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ícone
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: iconBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        asset,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Nome e descrição
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF001E2D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: const Color(0xFF3F4946),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Ação
                    Text(
                      action,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
