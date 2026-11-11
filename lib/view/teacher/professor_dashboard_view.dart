import 'package:academiagrazi/theme/app_font_size.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/controller/teachers/teacher_user_searcher.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:academiagrazi/view/components/instructor_schedule_builder.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfessorDashboardView extends StatefulWidget {
  const ProfessorDashboardView({super.key});

  @override
  State<ProfessorDashboardView> createState() => _ProfessorDashboardViewState();
}

class _ProfessorDashboardViewState extends State<ProfessorDashboardView> {
  final FirebaseAuth _authInstance = locator<FirebaseAuth>();
  bool _isLoading = true;
  String _userQuantity = '0'; // Variável de estado para a quantidade

  static const Color navy = AppColors.primaryDark;
  static const Color green = AppColors.primary;
  static const Color textColor = AppColors.textSecondary;
  static const Color red = AppColors.danger;
  static const Color orange = AppColors.accentDark;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final teacherUID = _authInstance.currentUser!.uid;
      final searcher = locator<TeacherUserSearcher>();

      // AWAIT aguarda a resposta do Firebase
      final count = await searcher.userQuantity(teacherUID);

      if (mounted) {
        setState(() {
          _userQuantity = count.toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao buscar dados do Firebase: $e');
      if (mounted) {
        setState(() {
          _userQuantity = '-';
          _isLoading = false;
        });
        _mostrarAviso('Erro de conexão ao carregar os dados.');
      }
    }
  }

  void _mostrarAviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Grazi Braz'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: InstructorScheduleBuilder(
            instructorId: _authInstance.currentUser?.uid,
            builder:
                (context, schedule) => Column(
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
                            fontSize: AppFontSize.headline,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          schedule.currentLabel,
                          key: const Key('texto_turno_atual'),
                          style: GoogleFonts.barlowCondensed(
                            color: textColor,
                            fontSize: AppFontSize.body,
                          ),
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
                            value: _isLoading ? '…' : _userQuantity,
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

                    _DashboardMetricCard(
                      key: const Key('card_proximo_turno'),
                      asset: 'assets/relogio.svg',
                      title: 'Próximo Turno',
                      value: schedule.nextUnitLabel,
                      description: schedule.nextWhenLabel,
                      isNextShift: true,
                      accentColor: AppColors.primary,
                      shadowColor: navy,
                    ),

                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Prioridades',
                          style: GoogleFonts.barlowCondensed(
                            fontWeight: FontWeight.w700,
                            fontSize: AppFontSize.headline,
                            color: navy,
                          ),
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
                            style: GoogleFonts.barlowCondensed(
                              fontSize: AppFontSize.caption,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryChipSurface,
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
                      iconBackgroundColor: AppColors.accentAlertBorder,
                    ),

                    const SizedBox(height: 15),

                    const _PriorityCard(
                      name: 'Bruno Alves',
                      description: '12 dias sem treinar (inativo).',
                      asset: 'assets/alertaVermelho.svg',
                      action: 'Contatar',
                      accentColor: red,
                      iconBackgroundColor: AppColors.accentAlertBorder,
                    ),

                    const SizedBox(height: 15),

                    const _PriorityCard(
                      name: 'Carla Souza',
                      description: 'Novo treino solicitado.',
                      asset: 'assets/halter.svg',
                      action: 'Montar',
                      accentColor: green,
                      iconBackgroundColor: AppColors.mintBorderBright,
                    ),
                  ],
                ),
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
    super.key,
    required this.asset,
    required this.title,
    required this.value,
    required this.description,
    this.fullWidth = false,
    this.isNextShift = false,
    this.accentColor = AppColors.primary,
    this.shadowColor = AppColors.primary,
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
            color: shadowColor.withValues(alpha: 0.3),
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
                  style: GoogleFonts.barlowCondensed(
                    fontSize: AppFontSize.body,
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
              style: GoogleFonts.barlowCondensed(
                fontWeight: FontWeight.w700,
                fontSize: AppFontSize.headline,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: GoogleFonts.barlowCondensed(
                fontSize: AppFontSize.body,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                // Proteção de layout: Reduz o tamanho da fonte caso o texto seja muito longo
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: GoogleFonts.barlowCondensed(
                        fontWeight: FontWeight.w700,
                        fontSize: AppFontSize.display,
                        color:
                            fullWidth
                                ? AppColors.danger
                                : AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    description,
                    style: GoogleFonts.barlowCondensed(
                      fontSize: AppFontSize.body,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
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
            color: AppColors.primaryDark.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 5, color: accentColor),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 24,
                top: 20,
                right: 20,
                bottom: 20,
              ),
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

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.barlowCondensed(
                            fontSize: AppFontSize.title,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: GoogleFonts.barlowCondensed(
                            fontSize: AppFontSize.body,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    action,
                    style: GoogleFonts.barlowCondensed(
                      fontSize: AppFontSize.small,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
