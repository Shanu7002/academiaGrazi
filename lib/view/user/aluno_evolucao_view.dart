import 'dart:math' as math;

import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/evaluations/physical_evaluation.dart';
import 'package:academiagrazi/service/evaluations/physical_evaluation_service.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

const _navy = Color.fromARGB(255, 0, 30, 45);
const _green = Color.fromARGB(255, 2, 89, 79);
const _badgeSurface = Color.fromARGB(255, 136, 207, 193);
const _badgeText = Color.fromARGB(255, 0, 90, 79);
const _chipSurface = Color.fromARGB(255, 221, 245, 242);
const _subtitle = Color.fromARGB(255, 111, 121, 118);

const _meses = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

String formatarNumero(double valor, [int casas = 1]) =>
    valor.toStringAsFixed(casas).replaceAll('.', ',');

String formatarData(DateTime data) =>
    '${data.day} de ${_meses[data.month - 1]}, ${data.year}';

String _formatarVariacao(double valor, String unidade) {
  final sinal = valor < 0 ? '-' : '+';
  return '$sinal ${formatarNumero(valor.abs())} $unidade';
}

class AlunoEvolutionView extends StatelessWidget {
  const AlunoEvolutionView({super.key});

  @override
  Widget build(BuildContext context) {
    final alunoId = locator<FirebaseAuth>().currentUser!.uid;
    return Scaffold(
      appBar: const CustomAppBar(title: 'GRAZI BRAZ'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evolução',
              style: GoogleFonts.barlowCondensed(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
            const SizedBox(height: 8),
            EvolucaoAlunoConteudo(alunoId: alunoId),
          ],
        ),
      ),
    );
  }
}

enum _Periodo {
  tresMeses('3 Meses', 3),
  seisMeses('6 Meses', 6),
  umAno('1 Ano', 12);

  final String rotulo;
  final int meses;
  const _Periodo(this.rotulo, this.meses);
}

/// Evolução física de um aluno a partir das avaliações registradas.
///
/// Usada pelo aluno e pelo professor; quando [onExcluir] é informado,
/// cada item do histórico exibe a ação de exclusão.
class EvolucaoAlunoConteudo extends StatefulWidget {
  final String alunoId;
  final ValueChanged<PhysicalEvaluation>? onExcluir;

  const EvolucaoAlunoConteudo({
    super.key,
    required this.alunoId,
    this.onExcluir,
  });

  @override
  State<EvolucaoAlunoConteudo> createState() => _EvolucaoAlunoConteudoState();
}

class _EvolucaoAlunoConteudoState extends State<EvolucaoAlunoConteudo> {
  late Stream<List<PhysicalEvaluation>> _avaliacoes;
  _Periodo _periodo = _Periodo.umAno;

  @override
  void initState() {
    super.initState();
    _avaliacoes = _carregar();
  }

  @override
  void didUpdateWidget(covariant EvolucaoAlunoConteudo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alunoId != widget.alunoId) _avaliacoes = _carregar();
  }

  Stream<List<PhysicalEvaluation>> _carregar() =>
      locator<PhysicalEvaluationService>().streamEvaluations(widget.alunoId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PhysicalEvaluation>>(
      stream: _avaliacoes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(
            'Erro ao carregar avaliações de ${widget.alunoId}: ${snapshot.error}',
          );
          return const _Aviso('Não foi possível carregar as avaliações.');
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final avaliacoes = snapshot.data!;
        if (avaliacoes.isEmpty) {
          return const _Aviso('Nenhuma avaliação física registrada ainda.');
        }

        final atual = avaliacoes.last;
        final anterior =
            avaliacoes.length > 1 ? avaliacoes[avaliacoes.length - 2] : null;
        final inicioPeriodo = DateTime.now().subtract(
          Duration(days: _periodo.meses * 30),
        );
        final noPeriodo =
            avaliacoes.where((a) => !a.date.isBefore(inicioPeriodo)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _seletorPeriodo(),
            const SizedBox(height: 15),
            _CardGrafico(
              atual: atual,
              anterior: anterior,
              noPeriodo: noPeriodo,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _CardComposicao(
                    titulo: 'Gordura',
                    icone: 'assets/gordura.svg',
                    fundo: const Color.fromARGB(255, 231, 234, 238),
                    valor: '${formatarNumero(atual.bodyFatPercent)} %',
                    variacao:
                        anterior == null
                            ? null
                            : _formatarVariacao(
                              atual.bodyFatPercent - anterior.bodyFatPercent,
                              '%',
                            ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CardComposicao(
                    titulo: 'Massa Magra',
                    icone: 'assets/massaMagra.svg',
                    fundo: const Color.fromARGB(255, 209, 236, 255),
                    valor: '${formatarNumero(atual.leanMassKg)} kg',
                    variacao:
                        anterior == null
                            ? null
                            : _formatarVariacao(
                              atual.leanMassKg - anterior.leanMassKg,
                              'kg',
                            ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              'Histórico de Avaliações',
              style: GoogleFonts.barlowCondensed(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
            const SizedBox(height: 15),
            for (final avaliacao in avaliacoes.reversed) ...[
              _ItemHistorico(
                avaliacao: avaliacao,
                onExcluir:
                    widget.onExcluir == null
                        ? null
                        : () => widget.onExcluir!(avaliacao),
              ),
              const SizedBox(height: 15),
            ],
          ],
        );
      },
    );
  }

  Widget _seletorPeriodo() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final periodo in _Periodo.values) ...[
            ElevatedButton(
              onPressed: () => setState(() => _periodo = periodo),
              style: ElevatedButton.styleFrom(
                backgroundColor: periodo == _periodo ? _green : _chipSurface,
                foregroundColor: periodo == _periodo ? Colors.white : _green,
                minimumSize: const Size(100, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
              child: Text(periodo.rotulo),
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  final String texto;
  const _Aviso(this.texto);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 209, 236, 255),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/info.svg', width: 24, height: 24),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              texto,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _decoracaoCard() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16.0),
  boxShadow: [
    BoxShadow(
      color: _green.withValues(alpha: 0.3),
      blurRadius: 6,
      offset: const Offset(0, 3),
    ),
  ],
);

class _Selo extends StatelessWidget {
  final String texto;
  const _Selo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _badgeSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        texto,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _badgeText,
        ),
      ),
    );
  }
}

enum _Metrica {
  peso('Peso Corporal', 'kg'),
  gordura('Gordura', '%'),
  massaMagra('Massa Magra', 'kg');

  final String rotulo;
  final String unidade;
  const _Metrica(this.rotulo, this.unidade);

  double valor(PhysicalEvaluation avaliacao) => switch (this) {
    _Metrica.peso => avaliacao.weightKg,
    _Metrica.gordura => avaliacao.bodyFatPercent,
    _Metrica.massaMagra => avaliacao.leanMassKg,
  };
}

/// Card com o gráfico da métrica escolhida pelo aluno.
class _CardGrafico extends StatefulWidget {
  final PhysicalEvaluation atual;
  final PhysicalEvaluation? anterior;
  final List<PhysicalEvaluation> noPeriodo;

  const _CardGrafico({
    required this.atual,
    required this.anterior,
    required this.noPeriodo,
  });

  @override
  State<_CardGrafico> createState() => _CardGraficoState();
}

class _CardGraficoState extends State<_CardGrafico> {
  _Metrica _metrica = _Metrica.peso;

  @override
  Widget build(BuildContext context) {
    final anterior = widget.anterior;
    final estiloTitulo = GoogleFonts.barlowCondensed(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: _navy,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _decoracaoCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<_Metrica>(
                    key: const Key('seletor_metrica_grafico'),
                    value: _metrica,
                    isExpanded: true,
                    isDense: true,
                    style: estiloTitulo,
                    iconEnabledColor: _green,
                    borderRadius: BorderRadius.circular(12),
                    items: [
                      for (final metrica in _Metrica.values)
                        DropdownMenuItem(
                          value: metrica,
                          child: Text(
                            metrica.rotulo,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (metrica) => setState(() => _metrica = metrica!),
                  ),
                ),
              ),
              if (anterior != null) ...[
                const SizedBox(width: 10),
                _Selo(
                  '${_formatarVariacao(_metrica.valor(widget.atual) - _metrica.valor(anterior), _metrica.unidade)} desde a última',
                ),
              ],
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatarNumero(_metrica.valor(widget.atual)),
                style: estiloTitulo,
              ),
              const SizedBox(width: 4),
              Text(
                _metrica.unidade,
                style: estiloTitulo.copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child:
                widget.noPeriodo.isEmpty
                    ? Center(
                      child: Text(
                        'Nenhuma avaliação no período.',
                        style: GoogleFonts.inter(color: _subtitle),
                      ),
                    )
                    : _Grafico(widget.noPeriodo, _metrica),
          ),
        ],
      ),
    );
  }
}

class _Grafico extends StatelessWidget {
  final List<PhysicalEvaluation> avaliacoes;
  final _Metrica metrica;
  const _Grafico(this.avaliacoes, this.metrica);

  @override
  Widget build(BuildContext context) {
    final valores = avaliacoes.map(metrica.valor);
    final minimo = valores.reduce((a, b) => a < b ? a : b);
    final maximo = valores.reduce((a, b) => a > b ? a : b);
    // Limites alinhados ao passo: o fl_chart sempre rotula o mínimo e o
    // máximo do eixo, que se sobrepõem aos demais se não forem múltiplos.
    final passo = _passoEixo(maximo - minimo);
    final minY = ((minimo - passo / 4) / passo).floorToDouble() * passo;
    final maxY = ((maximo + passo / 4) / passo).ceilToDouble() * passo;
    // Evita rótulos sobrepostos quando há muitas avaliações.
    final intervaloRotulos = (avaliacoes.length / 5).ceil();

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        minX: 0,
        maxX: (avaliacoes.length - 1).toDouble().clamp(1, double.infinity),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: passo,
              getTitlesWidget:
                  (valor, meta) => SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      formatarNumero(valor, 0),
                      style: GoogleFonts.inter(fontSize: 10, color: _subtitle),
                    ),
                  ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (valor, meta) {
                final indice = valor.toInt();
                if (valor != indice ||
                    indice >= avaliacoes.length ||
                    indice % intervaloRotulos != 0) {
                  return const SizedBox.shrink();
                }
                final data = avaliacoes[indice].date;
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}',
                    style: GoogleFonts.inter(fontSize: 10, color: _subtitle),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            color: _green,
            isCurved: true,
            curveSmoothness: 0.5,
            preventCurveOverShooting: true,
            dotData: FlDotData(
              show: true,
              getDotPainter:
                  (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 6,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: _green,
                  ),
            ),
            barWidth: 4,
            belowBarData: BarAreaData(
              show: true,
              color: const Color.fromARGB(80, 2, 89, 79),
            ),
            spots: [
              for (var i = 0; i < avaliacoes.length; i++)
                FlSpot(i.toDouble(), metrica.valor(avaliacoes[i])),
            ],
          ),
        ],
      ),
    );
  }
}

/// Passo "redondo" (1, 2, 5, 10, 20...) para dividir a amplitude em
/// cerca de quatro faixas; nunca menor que 1.
double _passoEixo(double amplitude) {
  final bruto = math.max(amplitude, 1) / 4;
  final magnitude = math.pow(10, (math.log(bruto) / math.ln10).floor());
  final normalizado = bruto / magnitude;
  final fator =
      normalizado <= 1
          ? 1
          : normalizado <= 2
          ? 2
          : normalizado <= 5
          ? 5
          : 10;
  return math.max(fator * magnitude, 1).toDouble();
}

class _CardComposicao extends StatelessWidget {
  final String titulo;
  final String icone;
  final Color fundo;
  final String valor;
  final String? variacao;

  const _CardComposicao({
    required this.titulo,
    required this.icone,
    required this.fundo,
    required this.valor,
    required this.variacao,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(icone, width: 24, height: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 0, 65, 100),
            ),
          ),
          if (variacao != null) ...[
            const SizedBox(height: 4),
            _Selo(variacao!),
          ],
        ],
      ),
    );
  }
}

class _ItemHistorico extends StatelessWidget {
  final PhysicalEvaluation avaliacao;
  final VoidCallback? onExcluir;

  const _ItemHistorico({required this.avaliacao, this.onExcluir});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap:
            () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => _DetalhesAvaliacao(avaliacao),
            ),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: _decoracaoCard(),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _chipSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SvgPicture.asset(
                  'assets/calendar.svg',
                  width: 24,
                  height: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatarData(avaliacao.date),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _navy,
                      ),
                    ),
                    Text(
                      '${formatarNumero(avaliacao.weightKg)} kg · '
                      '${formatarNumero(avaliacao.bodyFatPercent)} % gordura',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _subtitle,
                      ),
                    ),
                  ],
                ),
              ),
              if (onExcluir != null)
                IconButton(
                  tooltip: 'Excluir avaliação',
                  onPressed: onExcluir,
                  icon: const Icon(Icons.delete_outline, color: _subtitle),
                )
              else
                const Icon(Icons.chevron_right, color: _subtitle),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetalhesAvaliacao extends StatelessWidget {
  final PhysicalEvaluation avaliacao;
  const _DetalhesAvaliacao(this.avaliacao);

  @override
  Widget build(BuildContext context) {
    final dobras = avaliacao.skinfolds;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatarData(avaliacao.date),
              style: GoogleFonts.barlowCondensed(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
            Text(
              'Jackson & Pollock · 7 dobras',
              style: GoogleFonts.inter(color: _subtitle),
            ),
            const SizedBox(height: 16),
            ResultadosAvaliacao(avaliacao),
            const Divider(height: 32),
            _Linha(
              'Sexo',
              avaliacao.sex == BiologicalSex.male ? 'Masculino' : 'Feminino',
            ),
            _Linha('Idade', '${avaliacao.age} anos'),
            _Linha('Altura', '${avaliacao.heightCm} cm'),
            _Linha('Peso', '${formatarNumero(avaliacao.weightKg)} kg'),
            const Divider(height: 32),
            _Linha('Peitoral', '${formatarNumero(dobras.chest)} mm'),
            _Linha('Axilar média', '${formatarNumero(dobras.midaxillary)} mm'),
            _Linha('Tríceps', '${formatarNumero(dobras.triceps)} mm'),
            _Linha('Subescapular', '${formatarNumero(dobras.subscapular)} mm'),
            _Linha('Abdominal', '${formatarNumero(dobras.abdominal)} mm'),
            _Linha('Suprailíaca', '${formatarNumero(dobras.suprailiac)} mm'),
            _Linha('Coxa', '${formatarNumero(dobras.thigh)} mm'),
            _Linha('Soma das dobras', '${formatarNumero(dobras.sum)} mm'),
          ],
        ),
      ),
    );
  }
}

/// Resultados calculados de uma avaliação.
class ResultadosAvaliacao extends StatelessWidget {
  final PhysicalEvaluation avaliacao;
  const ResultadosAvaliacao(this.avaliacao, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Linha(
          '% de gordura',
          '${formatarNumero(avaliacao.bodyFatPercent)} %',
          destaque: true,
        ),
        _Linha('Massa gorda', '${formatarNumero(avaliacao.fatMassKg)} kg'),
        _Linha('Massa magra', '${formatarNumero(avaliacao.leanMassKg)} kg'),
        _Linha('IMC', formatarNumero(avaliacao.bmi)),
        _Linha(
          'Densidade corporal',
          '${formatarNumero(avaliacao.bodyDensity, 4)} g/cm³',
        ),
      ],
    );
  }
}

class _Linha extends StatelessWidget {
  final String rotulo;
  final String valor;
  final bool destaque;

  const _Linha(this.rotulo, this.valor, {this.destaque = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              rotulo,
              style: GoogleFonts.inter(fontSize: 14, color: _subtitle),
            ),
          ),
          Text(
            valor,
            style: GoogleFonts.inter(
              fontSize: destaque ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: destaque ? _green : _navy,
            ),
          ),
        ],
      ),
    );
  }
}
