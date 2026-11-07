import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/training/student_training_view_data_service.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:academiagrazi/view/user/aluno_treinos_view.dart';
import 'package:academiagrazi/view/user/ui_data/aluno_treinos_ui_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// Ponto de entrada da aba Treinos do aluno usando a prescricao real.
/// Sem ficha publicada, mostra um estado vazio em vez dos mocks.
class AlunoTreinosFirestoreView extends StatefulWidget {
  final String? studentId;
  final StudentTrainingViewDataService? service;

  const AlunoTreinosFirestoreView({super.key, this.studentId, this.service});

  @override
  State<AlunoTreinosFirestoreView> createState() =>
      _AlunoTreinosFirestoreViewState();
}

class _AlunoTreinosFirestoreViewState extends State<AlunoTreinosFirestoreView> {
  late final String? _studentId;
  Stream<AlunoTreinosUiData?>? _trainingStream;

  @override
  void initState() {
    super.initState();
    _studentId = widget.studentId ?? locator<FirebaseAuth>().currentUser?.uid;
    if (_studentId != null &&
        _studentId.isNotEmpty &&
        (widget.service != null || Firebase.apps.isNotEmpty)) {
      _trainingStream = (widget.service ?? StudentTrainingViewDataService())
          .watchActiveUiData(_studentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_trainingStream == null) {
      final withoutSession = _studentId == null || _studentId.isEmpty;
      return _estado(
        icon: withoutSession ? Icons.lock_outline : Icons.cloud_off_outlined,
        title: withoutSession ? 'Entre na sua conta' : 'Servico indisponivel',
        message:
            withoutSession
                ? 'Faca login para consultar sua ficha de treinos.'
                : 'O Firebase ainda nao foi inicializado.',
      );
    }

    return StreamBuilder<AlunoTreinosUiData?>(
      stream: _trainingStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _estado(
            icon: Icons.cloud_off_outlined,
            title: 'Nao foi possivel carregar os treinos',
            message:
                'Verifique a conexao e as permissoes da sua ficha no Firebase.',
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _estado(
            icon: Icons.fitness_center,
            title: 'Carregando sua ficha',
            message: 'Consultando os treinos publicados pelo seu professor.',
            loading: true,
          );
        }
        final training = snapshot.data;
        if (training == null) {
          return _estado(
            icon: Icons.assignment_outlined,
            title: 'Nenhuma ficha publicada',
            message: 'Seu professor ainda nao atribuiu uma ficha para voce.',
          );
        }
        // Reutiliza integralmente a tela existente de Treinos A/B/C.
        return AlunoTreinosView(data: training);
      },
    );
  }

  Widget _estado({
    required IconData icon,
    required String title,
    required String message,
    bool loading = false,
  }) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'GRAZI BRAZ'),
      backgroundColor: AppColors.trainingListBackground,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  const CircularProgressIndicator()
                else
                  Icon(icon, size: 50, color: AppColors.primary),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
