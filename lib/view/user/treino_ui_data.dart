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
  final String nome;
  final String descricao;
  final List<ExercicioTreinoUi> exercicios;

  const TreinoUi({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.exercicios,
  });
}

/// Dados temporários SOMENTE para construção do front.
///
/// Quando o backend for implementado, esta classe poderá ser substituída
/// pelos dados vindos do Firebase sem precisar refazer as telas.
class TreinosFrontData {
  static const treinoA = TreinoUi(
    id: 'treino-a',
    nome: 'TREINO A - SUPERIORES',
    descricao: 'Peito e Tríceps',
    exercicios: [
      ExercicioTreinoUi(
        id: 'supino-inclinado',
        nome: 'Supino Inclinado',
        aquecimento: '1x15',
        series: '3x10',
        carga: '40Kg',
      ),
      ExercicioTreinoUi(
        id: 'peitoral-fly',
        nome: 'Peitoral no Fly',
        series: '3x10-12',
        carga: '45Kg',
      ),
      ExercicioTreinoUi(
        id: 'supino-reto-maquina',
        nome: 'Supino Reto Máquina',
        series: '3x8-10',
        carga: '20Kg',
      ),
      ExercicioTreinoUi(
        id: 'crucifixo-maquina',
        nome: 'Crucifixo Máquina',
        series: '3x10',
        carga: '25Kg',
      ),
      ExercicioTreinoUi(
        id: 'triceps-pulley',
        nome: 'Tríceps Pulley',
        series: '3x12',
        carga: '30Kg',
      ),
      ExercicioTreinoUi(
        id: 'triceps-frances',
        nome: 'Tríceps Francês',
        series: '3x10',
        carga: '12Kg',
      ),
    ],
  );

  static const treinoB = TreinoUi(
    id: 'treino-b',
    nome: 'TREINO B - INFERIORES',
    descricao: 'Quadríceps e Panturrilha',
    exercicios: [
      ExercicioTreinoUi(
        id: 'agachamento',
        nome: 'Agachamento Livre',
        aquecimento: '1x15',
        series: '4x10',
        carga: '40Kg',
      ),
      ExercicioTreinoUi(
        id: 'leg-press',
        nome: 'Leg Press 45°',
        series: '4x12',
        carga: '80Kg',
      ),
      ExercicioTreinoUi(
        id: 'extensora',
        nome: 'Cadeira Extensora',
        series: '3x12',
        carga: '35Kg',
      ),
      ExercicioTreinoUi(
        id: 'flexora',
        nome: 'Mesa Flexora',
        series: '3x12',
        carga: '30Kg',
      ),
      ExercicioTreinoUi(
        id: 'elevacao-pelvica',
        nome: 'Elevação Pélvica',
        series: '4x12',
        carga: '50Kg',
      ),
      ExercicioTreinoUi(
        id: 'panturrilha',
        nome: 'Panturrilha em Pé',
        series: '4x15',
        carga: '30Kg',
      ),
    ],
  );

  static const treinoC = TreinoUi(
    id: 'treino-c',
    nome: 'TREINO C - SUPERIORES',
    descricao: 'Ombro',
    exercicios: [
      ExercicioTreinoUi(
        id: 'desenvolvimento',
        nome: 'Desenvolvimento Máquina',
        aquecimento: '1x15',
        series: '3x10',
        carga: '25Kg',
      ),
      ExercicioTreinoUi(
        id: 'elevacao-lateral',
        nome: 'Elevação Lateral',
        series: '3x12',
        carga: '8Kg',
      ),
      ExercicioTreinoUi(
        id: 'elevacao-frontal',
        nome: 'Elevação Frontal',
        series: '3x12',
        carga: '8Kg',
      ),
      ExercicioTreinoUi(
        id: 'crucifixo-inverso',
        nome: 'Crucifixo Inverso',
        series: '3x12',
        carga: '20Kg',
      ),
    ],
  );

  static const treinoD = TreinoUi(
    id: 'treino-d',
    nome: 'TREINO D - INFERIORES',
    descricao: 'Posterior, Glúteos e Panturrilha',
    exercicios: [
      ExercicioTreinoUi(
        id: 'stiff',
        nome: 'Stiff',
        aquecimento: '1x15',
        series: '4x10',
        carga: '35Kg',
      ),
      ExercicioTreinoUi(
        id: 'mesa-flexora-d',
        nome: 'Mesa Flexora',
        series: '4x12',
        carga: '30Kg',
      ),
      ExercicioTreinoUi(
        id: 'elevacao-pelvica-d',
        nome: 'Elevação Pélvica',
        series: '4x12',
        carga: '55Kg',
      ),
      ExercicioTreinoUi(
        id: 'panturrilha-d',
        nome: 'Panturrilha',
        series: '4x15',
        carga: '30Kg',
      ),
    ],
  );

  static const treinoE = TreinoUi(
    id: 'treino-e',
    nome: 'TREINO E - SUPERIORES',
    descricao: 'Costas e Bíceps',
    exercicios: [
      ExercicioTreinoUi(
        id: 'puxada',
        nome: 'Puxada Frontal',
        aquecimento: '1x15',
        series: '3x10',
        carga: '40Kg',
      ),
      ExercicioTreinoUi(
        id: 'remada',
        nome: 'Remada Baixa',
        series: '3x10',
        carga: '40Kg',
      ),
      ExercicioTreinoUi(
        id: 'rosca-direta',
        nome: 'Rosca Direta',
        series: '3x10',
        carga: '15Kg',
      ),
      ExercicioTreinoUi(
        id: 'rosca-martelo',
        nome: 'Rosca Martelo',
        series: '3x12',
        carga: '10Kg',
      ),
    ],
  );

  static const List<TreinoUi> treinos = [
    treinoA,
    treinoB,
    treinoC,
    treinoD,
    treinoE,
  ];

  /// Só para representar visualmente a recomendação no front.
  ///
  /// Hoje usamos o Treino B. Depois quem definirá isso será o professor
  /// através da agenda do aluno.
  static const TreinoUi recomendacao = treinoB;
}