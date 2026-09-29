enum TreinoStatusUi {
  recomendado,
  concluido,
  programado,
}

class ExercicioTreinoUi {
  final String id;
  final String nome;
  final String? aquecimento;
  final String series;
  final String carga;

  const ExercicioTreinoUi({
    required this.id,
    required this.nome,
    this.aquecimento,
    required this.series,
    required this.carga,
  });
}

class TreinoUi {
  final String id;
  final String letra;
  final String nome;
  final String descricao;

  final int duracaoMinutos;
  final int quantidadeExercicios;

  final String nivel;
  final String estrategia;

  final String principaisExercicios;
  final String seriesResumo;

  final TreinoStatusUi status;
  final String statusTexto;

  final List<ExercicioTreinoUi> exercicios;

  const TreinoUi({
    required this.id,
    required this.letra,
    required this.nome,
    required this.descricao,
    required this.duracaoMinutos,
    required this.quantidadeExercicios,
    required this.nivel,
    required this.estrategia,
    required this.principaisExercicios,
    required this.seriesResumo,
    required this.status,
    required this.statusTexto,
    required this.exercicios,
  });
}

class TreinoComplementarUi {
  final String id;
  final String nome;
  final String descricao;
  final int duracaoMinutos;

  const TreinoComplementarUi({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.duracaoMinutos,
  });
}

/// Dados temporários para construção do front.
///
/// Mais adiante estes dados serão substituídos pelos valores
/// retornados pelo backend/Firebase.
class TreinosFrontData {
  // ============================================================
  // ALUNO / PRESCRIÇÃO
  // ============================================================

  static const String alunoNome = 'Ana Lima';

  static const String semana = 'Semana 03/08';

  static const String professorNome = 'Prof. Marcos';

  static const String ultimaAtualizacao =
      'Atualizado há 2 semanas';

  // ============================================================
  // CICLO ATUAL
  // ============================================================

  static const String cicloNome =
      'Divisão ABC • Hipertrofia & Postura';

  static const String frequencia = '3–5x';
  static const String frequenciaLegenda = 'por semana';

  static const String duracaoMedia = '45 min';
  static const String duracaoLegenda = 'tempo médio';

  static const String validade = '25/08';
  static const String validadeLegenda = 'revisão geral';

  // ============================================================
  // TREINO A
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
        'Agachamento livre guiado, Elevação pélvica c/ '
        'pausa isométrica, Afundo halteres, Cadeira '
        'extensora, Stiff unilateral.',
    status: TreinoStatusUi.recomendado,
    statusTexto: 'RECOMENDADO PARA HOJE',
    exercicios: [
      ExercicioTreinoUi(
        id: 'agachamento',
        nome: 'Agachamento livre',
        aquecimento: '1x15',
        series: '4x10',
        carga: '40Kg',
      ),
      ExercicioTreinoUi(
        id: 'elevacao-pelvica',
        nome: 'Elevação pélvica',
        series: '3x12',
        carga: '50Kg',
      ),
      ExercicioTreinoUi(
        id: 'afundo',
        nome: 'Afundo halteres',
        series: '3x10',
        carga: '12Kg',
      ),
      ExercicioTreinoUi(
        id: 'extensora',
        nome: 'Cadeira extensora',
        series: '3x12',
        carga: '35Kg',
      ),
      ExercicioTreinoUi(
        id: 'stiff',
        nome: 'Stiff unilateral',
        series: '3x10',
        carga: '20Kg',
      ),
      ExercicioTreinoUi(
        id: 'flexora',
        nome: 'Mesa flexora',
        series: '3x12',
        carga: '30Kg',
      ),
      ExercicioTreinoUi(
        id: 'panturrilha',
        nome: 'Panturrilha',
        series: '4x15',
        carga: '30Kg',
      ),
      ExercicioTreinoUi(
        id: 'abdutora',
        nome: 'Cadeira abdutora',
        series: '3x15',
        carga: '35Kg',
      ),
    ],
  );

  // ============================================================
  // TREINO B
  // ============================================================

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
        'Puxada frontal neutra, Remada articulada, '
        'Rosca direta halter, Prancha ativa isométrica.',
    status: TreinoStatusUi.concluido,
    statusTexto: 'Concluído ontem • 40 min',
    exercicios: [
      ExercicioTreinoUi(
        id: 'puxada',
        nome: 'Puxada frontal neutra',
        series: '3x10',
        carga: '40Kg',
      ),
      ExercicioTreinoUi(
        id: 'remada',
        nome: 'Remada articulada',
        series: '3x10',
        carga: '35Kg',
      ),
      ExercicioTreinoUi(
        id: 'rosca-direta',
        nome: 'Rosca direta halter',
        series: '3x12',
        carga: '10Kg',
      ),
      ExercicioTreinoUi(
        id: 'prancha',
        nome: 'Prancha ativa isométrica',
        series: '3x30s',
        carga: '-',
      ),
    ],
  );

  // ============================================================
  // TREINO C
  // ============================================================

  static const TreinoUi treinoC = TreinoUi(
    id: 'treino-c',
    letra: 'C',
    nome:
        'TREINO C — PEITO, OMBROS, TRÍCEPS + MOBILIDADE',
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
      ExercicioTreinoUi(
        id: 'supino',
        nome: 'Supino halteres plano',
        series: '3x10',
        carga: '20Kg',
      ),
      ExercicioTreinoUi(
        id: 'elevacao-lateral',
        nome: 'Elevação lateral c/ rotação',
        series: '3x12',
        carga: '8Kg',
      ),
      ExercicioTreinoUi(
        id: 'triceps-corda',
        nome: 'Tríceps corda polia',
        series: '3x12',
        carga: '25Kg',
      ),
      ExercicioTreinoUi(
        id: 'rotacao-toracica',
        nome: 'Rotação torácica',
        series: '3x10',
        carga: '-',
      ),
    ],
  );

  static const List<TreinoUi> treinos = [
    treinoA,
    treinoB,
    treinoC,
  ];

  /// Temporário.
  /// Futuramente o backend informará qual treino está
  /// recomendado para o dia atual.
  static const TreinoUi recomendacao = treinoA;

  // ============================================================
  // COMPLEMENTARES
  // ============================================================

  static const List<TreinoComplementarUi> complementares = [
    TreinoComplementarUi(
      id: 'mobilidade',
      nome: 'Mobilidade & Soltura',
      descricao:
          'Ideal para dias de descanso ou recuperação',
      duracaoMinutos: 15,
    ),
    TreinoComplementarUi(
      id: 'core',
      nome: 'Core Sem Carga',
      descricao:
          'Para manter o ritmo ativo em viagens ou finais de semana',
      duracaoMinutos: 20,
    ),
  ];
}