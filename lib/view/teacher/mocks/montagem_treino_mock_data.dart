import 'package:academiagrazi/view/teacher/ui_data/montagem_treino_ui_data.dart';
import 'package:academiagrazi/view/teacher/ui_models/montagem_treino_ui_models.dart';

/// Dados TEMPORARIOS para demonstrar o frontend ate a integracao com Firestore.
abstract final class MontagemTreinoProfessorMockData {
  static const inicial = MontagemTreinoProfessorUiData(
    nomeTreino: 'Treino A',
    alunoSelecionadoId: 'aluna-ana',
    alunos: [
      AlunoResumoProfessorUi(id: 'aluna-ana', nome: 'Ana Lima'),
      AlunoResumoProfessorUi(id: 'aluna-beatriz', nome: 'Beatriz Souza'),
      AlunoResumoProfessorUi(id: 'aluno-carlos', nome: 'Carlos Oliveira'),
    ],
    catalogo: [
      ExercicioCatalogoProfessorUi(
        id: 'agachamento-livre',
        nome: 'Agachamento Livre',
        grupoMuscular: 'Pernas · Gluteos',
      ),
      ExercicioCatalogoProfessorUi(
        id: 'leg-press-45',
        nome: 'Leg Press 45°',
        grupoMuscular: 'Pernas',
      ),
      ExercicioCatalogoProfessorUi(
        id: 'cadeira-extensora',
        nome: 'Cadeira Extensora',
        grupoMuscular: 'Quadriceps',
      ),
      ExercicioCatalogoProfessorUi(
        id: 'supino-reto',
        nome: 'Supino Reto',
        grupoMuscular: 'Peitoral',
      ),
      ExercicioCatalogoProfessorUi(
        id: 'puxada-frontal',
        nome: 'Puxada Frontal',
        grupoMuscular: 'Costas',
      ),
      ExercicioCatalogoProfessorUi(
        id: 'remada-baixa',
        nome: 'Remada Baixa',
        grupoMuscular: 'Costas',
      ),
    ],
    exerciciosIniciais: [
      ExercicioMontadoProfessorUi(
        itemId: 'item-agachamento',
        exercicioId: 'agachamento-livre',
        series: 4,
        repeticoes: 10,
        descansoSegundos: 75,
        tecnica: 'Rest-pause',
      ),
      ExercicioMontadoProfessorUi(
        itemId: 'item-leg-press',
        exercicioId: 'leg-press-45',
        series: 3,
        repeticoes: 12,
        descansoSegundos: 60,
        tecnica: 'Tradicional',
      ),
    ],
    duracaoEstimadaMinutos: 45,
    volume: 'Intenso',
    dicaExecucao:
        'Mantenha a curvatura natural da lombar e o peito aberto durante toda a descida.',
  );
}
