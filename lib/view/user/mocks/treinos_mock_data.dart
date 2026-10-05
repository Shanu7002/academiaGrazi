import 'package:academiagrazi/view/user/ui_data/aluno_exercicio_detalhe_ui_data.dart';
import 'package:academiagrazi/view/user/ui_data/aluno_treino_dia_ui_data.dart';
import 'package:academiagrazi/view/user/ui_data/aluno_treinos_ui_data.dart';
import 'package:academiagrazi/view/user/ui_models/treino_ui_models.dart';

abstract final class TreinosMockData {
  static const String _orientacaoGenerica =
      'As orientações específicas deste exercício serão exibidas aqui '
      'quando estiverem cadastradas na prescrição.';

  // ============================================================
  // EXERCÍCIOS — TREINO A
  // ============================================================

  static const ExercicioTreinoUi agachamento = ExercicioTreinoUi(
    id: 'agachamento',
    nome: 'Agachamento livre',
    aquecimento: '1x15',
    series: '4x10',
    carga: '40Kg',
  );

  static const ExercicioTreinoUi elevacaoPelvica = ExercicioTreinoUi(
    id: 'elevacao-pelvica',
    nome: 'Elevação pélvica',
    series: '3x12',
    carga: '50Kg',
  );

  static const ExercicioTreinoUi afundo = ExercicioTreinoUi(
    id: 'afundo',
    nome: 'Afundo halteres',
    series: '3x10',
    carga: '12Kg',
  );

  static const ExercicioTreinoUi extensora = ExercicioTreinoUi(
    id: 'extensora',
    nome: 'Cadeira extensora',
    series: '3x12',
    carga: '35Kg',
  );

  static const ExercicioTreinoUi stiff = ExercicioTreinoUi(
    id: 'stiff',
    nome: 'Stiff unilateral',
    series: '3x10',
    carga: '20Kg',
  );

  static const ExercicioTreinoUi flexora = ExercicioTreinoUi(
    id: 'flexora',
    nome: 'Mesa flexora',
    series: '3x12',
    carga: '30Kg',
  );

  static const ExercicioTreinoUi panturrilha = ExercicioTreinoUi(
    id: 'panturrilha',
    nome: 'Panturrilha',
    series: '4x15',
    carga: '30Kg',
  );

  static const ExercicioTreinoUi abdutora = ExercicioTreinoUi(
    id: 'abdutora',
    nome: 'Cadeira abdutora',
    series: '3x15',
    carga: '35Kg',
  );

  // ============================================================
  // EXERCÍCIOS — TREINO B
  // ============================================================

  static const ExercicioTreinoUi puxada = ExercicioTreinoUi(
    id: 'puxada',
    nome: 'Puxada frontal neutra',
    series: '3x10',
    carga: '40Kg',
  );

  static const ExercicioTreinoUi remada = ExercicioTreinoUi(
    id: 'remada',
    nome: 'Remada articulada',
    series: '3x10',
    carga: '35Kg',
  );

  static const ExercicioTreinoUi roscaDireta = ExercicioTreinoUi(
    id: 'rosca-direta',
    nome: 'Rosca direta halter',
    series: '3x12',
    carga: '10Kg',
  );

  static const ExercicioTreinoUi prancha = ExercicioTreinoUi(
    id: 'prancha',
    nome: 'Prancha ativa isométrica',
    series: '3x30s',
    carga: '-',
  );

  // ============================================================
  // EXERCÍCIOS — TREINO C
  // ============================================================

  static const ExercicioTreinoUi supino = ExercicioTreinoUi(
    id: 'supino',
    nome: 'Supino halteres plano',
    series: '3x10',
    carga: '20Kg',
  );

  static const ExercicioTreinoUi elevacaoLateral = ExercicioTreinoUi(
    id: 'elevacao-lateral',
    nome: 'Elevação lateral c/ rotação',
    series: '3x12',
    carga: '8Kg',
  );

  static const ExercicioTreinoUi tricepsCorda = ExercicioTreinoUi(
    id: 'triceps-corda',
    nome: 'Tríceps corda polia',
    series: '3x12',
    carga: '25Kg',
  );

  static const ExercicioTreinoUi rotacaoToracica = ExercicioTreinoUi(
    id: 'rotacao-toracica',
    nome: 'Rotação torácica',
    series: '3x10',
    carga: '-',
  );

  // ============================================================
  // TREINOS
  // ============================================================

  static const TreinoUi treinoA = TreinoUi(
    id: 'treino-a',
    letra: 'A',
    nome: 'TREINO A — PERNAS + GLÚTEOS',
    descricao:
        'Foco em força de cadeia posterior e estabilidade pélvica',
    duracaoMinutos: 42,
    quantidadeExercicios: 8,
    nivel: 'Intermediário',
    estrategia: 'Carga Progressiva',
    seriesResumo: '3 a 4 séries',
    principaisExercicios:
        'Agachamento livre guiado, Elevação pélvica c/ pausa isométrica, '
        'Afundo halteres, Cadeira extensora, Stiff unilateral.',
    status: TreinoStatusUi.recomendado,
    statusTexto: 'RECOMENDADO PARA HOJE',
    exercicios: [
      agachamento,
      elevacaoPelvica,
      afundo,
      extensora,
      stiff,
      flexora,
      panturrilha,
      abdutora,
    ],
  );

  static const TreinoUi treinoB = TreinoUi(
    id: 'treino-b',
    letra: 'B',
    nome: 'TREINO B — COSTAS, BÍCEPS + ABDÔMEN',
    descricao:
        'Tração, retração escapular e resistência profunda do tronco',
    duracaoMinutos: 40,
    quantidadeExercicios: 4,
    nivel: 'Intermediário',
    estrategia: 'Postura & Core',
    seriesResumo: '3 séries',
    principaisExercicios:
        'Puxada frontal neutra, Remada articulada, Rosca direta halter, '
        'Prancha ativa isométrica.',
    status: TreinoStatusUi.concluido,
    statusTexto: 'Concluído ontem • 40 min',
    exercicios: [
      puxada,
      remada,
      roscaDireta,
      prancha,
    ],
  );

  static const TreinoUi treinoC = TreinoUi(
    id: 'treino-c',
    letra: 'C',
    nome: 'TREINO C — PEITO, OMBROS, TRÍCEPS + MOBILIDADE',
    descricao:
        'Empurrar, estabilidade glenoumeral e flexibilidade articular',
    duracaoMinutos: 38,
    quantidadeExercicios: 4,
    nivel: 'Intermediário',
    estrategia: 'Mobilidade',
    seriesResumo: '3 séries',
    principaisExercicios:
        'Supino halteres plano, Elevação lateral c/ rotação, '
        'Tríceps corda polia, Rotação torácica.',
    status: TreinoStatusUi.programado,
    statusTexto: 'Programado para Quinta-feira',
    exercicios: [
      supino,
      elevacaoLateral,
      tricepsCorda,
      rotacaoToracica,
    ],
  );

  // ============================================================
  // DETALHE DOS EXERCÍCIOS
  // ============================================================

  static const AlunoExercicioDetalheUiData agachamentoDetalhe =
      AlunoExercicioDetalheUiData(
    exercicio: agachamento,
    descanso: '75s',
    tempoVideo: '01:45',
    orientacoes:
        'Mantenha as costas retas e o core contraído. Posicione os pés '
        'na largura dos ombros, apontando ligeiramente para fora. Desça '
        'flexionando joelhos e quadril, como se fosse sentar em uma cadeira, '
        'até que as coxas fiquem paralelas ao chão.',
  );

  static const AlunoExercicioDetalheUiData elevacaoPelvicaDetalhe =
      AlunoExercicioDetalheUiData(
    exercicio: elevacaoPelvica,
    descanso: '—',
    tempoVideo: '00:00',
    orientacoes: _orientacaoGenerica,
  );

  static const AlunoExercicioDetalheUiData afundoDetalhe =
      AlunoExercicioDetalheUiData(
    exercicio: afundo,
    descanso: '—',
    tempoVideo: '00:00',
    orientacoes: _orientacaoGenerica,
  );

  static const AlunoExercicioDetalheUiData extensoraDetalhe =
      AlunoExercicioDetalheUiData(
    exercicio: extensora,
    descanso: '—',
    tempoVideo: '00:00',
    orientacoes: _orientacaoGenerica,
  );

  static const AlunoExercicioDetalheUiData stiffDetalhe =
      AlunoExercicioDetalheUiData(
    exercicio: stiff,
    descanso: '—',
    tempoVideo: '00:00',
    orientacoes: _orientacaoGenerica,
  );

  static const AlunoExercicioDetalheUiData flexoraDetalhe =
      AlunoExercicioDetalheUiData(
    exercicio: flexora,
    descanso: '—',
    tempoVideo: '00:00',
    orientacoes: _orientacaoGenerica,
  );

  static const AlunoExercicioDetalheUiData panturrilhaDetalhe =
      AlunoExercicioDetalheUiData(
    exercicio: panturrilha,
    descanso: '—',
    tempoVideo: '00:00',
    orientacoes: _orientacaoGenerica,
  );

  static const AlunoExercicioDetalheUiData abdutoraDetalhe =
      AlunoExercicioDetalheUiData(
    exercicio: abdutora,
    descanso: '—',
    tempoVideo: '00:00',
    orientacoes: _orientacaoGenerica,
  );

  static const AlunoExercicioDetalheUiData puxadaDetalhe =
      AlunoExercicioDetalheUiData(
    exercicio: puxada,
    descanso: '—',
    tempoVideo: '00:00',
    orientacoes: _orientacaoGenerica,
  );

  static const AlunoExercicioDetalheUiData remadaDetalhe =
      AlunoExercicioDetalheUiData(
    exercicio: remada,
    descanso: '—',
    tempoVideo: '00:00',
    orientacoes: _orientacaoGenerica,
  );

  static const AlunoExercicioDetalheUiData roscaDiretaDetalhe =
      AlunoExercicioDetalheUiData(
    exercicio: roscaDireta,
    descanso: '—',
    tempoVideo: '00:00',
    orientacoes: _orientacaoGenerica,
  );

  static const AlunoExercicioDetalheUiData pranchaDetalhe =
      AlunoExercicioDetalheUiData(
    exercicio: prancha,
    descanso: '—',
    tempoVideo: '00:00',
    orientacoes: _orientacaoGenerica,
  );

  static const AlunoExercicioDetalheUiData supinoDetalhe =
      AlunoExercicioDetalheUiData(
    exercicio: supino,
    descanso: '—',
    tempoVideo: '00:00',
    orientacoes: _orientacaoGenerica,
  );

  static const AlunoExercicioDetalheUiData elevacaoLateralDetalhe =
      AlunoExercicioDetalheUiData(
    exercicio: elevacaoLateral,
    descanso: '—',
    tempoVideo: '00:00',
    orientacoes: _orientacaoGenerica,
  );

  static const AlunoExercicioDetalheUiData tricepsCordaDetalhe =
      AlunoExercicioDetalheUiData(
    exercicio: tricepsCorda,
    descanso: '—',
    tempoVideo: '00:00',
    orientacoes: _orientacaoGenerica,
  );

  static const AlunoExercicioDetalheUiData rotacaoToracicaDetalhe =
      AlunoExercicioDetalheUiData(
    exercicio: rotacaoToracica,
    descanso: '—',
    tempoVideo: '00:00',
    orientacoes: _orientacaoGenerica,
  );

  // ============================================================
  // DADOS DA VIEW "TREINO DO DIA"
  // ============================================================

  static const AlunoTreinoDiaUiData treinoADia = AlunoTreinoDiaUiData(
    treino: treinoA,
    professorNome: 'Prof. Marcos',
    aquecimentoNome: 'Mobilidade de quadril',
    aquecimentoResumo: '1 série • 60 seg',
    exerciciosConcluidosIniciais: {
      'agachamento',
      'elevacao-pelvica',
    },
    exercicioDetalhePorId: {
      'agachamento': agachamentoDetalhe,
      'elevacao-pelvica': elevacaoPelvicaDetalhe,
      'afundo': afundoDetalhe,
      'extensora': extensoraDetalhe,
      'stiff': stiffDetalhe,
      'flexora': flexoraDetalhe,
      'panturrilha': panturrilhaDetalhe,
      'abdutora': abdutoraDetalhe,
    },
  );

  static const AlunoTreinoDiaUiData treinoBDia = AlunoTreinoDiaUiData(
    treino: treinoB,
    professorNome: 'Prof. Marcos',
    aquecimentoNome: 'Mobilidade de quadril',
    aquecimentoResumo: '1 série • 60 seg',
    exerciciosConcluidosIniciais: <String>{},
    exercicioDetalhePorId: {
      'puxada': puxadaDetalhe,
      'remada': remadaDetalhe,
      'rosca-direta': roscaDiretaDetalhe,
      'prancha': pranchaDetalhe,
    },
  );

  static const AlunoTreinoDiaUiData treinoCDia = AlunoTreinoDiaUiData(
    treino: treinoC,
    professorNome: 'Prof. Marcos',
    aquecimentoNome: 'Mobilidade de quadril',
    aquecimentoResumo: '1 série • 60 seg',
    exerciciosConcluidosIniciais: <String>{},
    exercicioDetalhePorId: {
      'supino': supinoDetalhe,
      'elevacao-lateral': elevacaoLateralDetalhe,
      'triceps-corda': tricepsCordaDetalhe,
      'rotacao-toracica': rotacaoToracicaDetalhe,
    },
  );

  // ============================================================
  // DADOS DA VIEW "MEUS TREINOS"
  // ============================================================

  static const AlunoTreinosUiData alunoTreinos = AlunoTreinosUiData(
    alunoNome: 'Ana Lima',
    semana: 'Semana 03/08',
    professorNome: 'Prof. Marcos',
    ultimaAtualizacao: 'Atualizado há 2 semanas',
    cicloNome: 'Divisão ABC • Hipertrofia & Postura',
    frequencia: '3–5x',
    frequenciaLegenda: 'por semana',
    duracaoMedia: '45 min',
    duracaoLegenda: 'tempo médio',
    validade: '25/08',
    validadeLegenda: 'revisão geral',
    treinos: [
      treinoA,
      treinoB,
      treinoC,
    ],
    complementares: [
      TreinoComplementarUi(
        id: 'mobilidade',
        nome: 'Mobilidade & Soltura',
        descricao: 'Ideal para dias de descanso ou recuperação',
        duracaoMinutos: 15,
      ),
      TreinoComplementarUi(
        id: 'core',
        nome: 'Core Sem Carga',
        descricao:
            'Para manter o ritmo ativo em viagens ou finais de semana',
        duracaoMinutos: 20,
      ),
    ],
    treinoDiaPorId: {
      'treino-a': treinoADia,
      'treino-b': treinoBDia,
      'treino-c': treinoCDia,
    },
  );
}
