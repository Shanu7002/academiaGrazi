import 'package:academiagrazi/theme/app_font_size.dart';
import 'package:academiagrazi/controller/teachers/teacher_user_searcher.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/evaluations/physical_evaluation.dart';
import 'package:academiagrazi/models/users/registration_profile.dart';
import 'package:academiagrazi/service/evaluations/physical_evaluation_service.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/user/aluno_evolucao_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Campo numérico com o intervalo aceito (mesmo validado no firestore.rules).
class _Campo {
  final String rotulo;
  final String unidade;
  final double minimo;
  final double maximo;
  final bool inteiro;
  final TextEditingController controller;

  _Campo(
    this.rotulo,
    this.unidade,
    this.minimo,
    this.maximo, {
    this.inteiro = false,
    String inicial = '',
  }) : controller = TextEditingController(text: inicial);

  double? get valor {
    final numero = double.tryParse(controller.text.replaceAll(',', '.'));
    if (numero == null || numero < minimo || numero > maximo) return null;
    if (inteiro && numero != numero.roundToDouble()) return null;
    return numero;
  }

  String? validar(String? _) {
    if (valor != null) return null;
    final faixa =
        '${formatarNumero(minimo, 0)} a ${formatarNumero(maximo, 0)} $unidade';
    return inteiro ? 'Número inteiro de $faixa' : 'Informe de $faixa';
  }
}

/// Cadastro de avaliação física por dobras cutâneas (Jackson & Pollock 7).
class NovaAvaliacaoView extends StatefulWidget {
  final UserSummary aluno;

  const NovaAvaliacaoView({super.key, required this.aluno});

  @override
  State<NovaAvaliacaoView> createState() => _NovaAvaliacaoViewState();
}

class _NovaAvaliacaoViewState extends State<NovaAvaliacaoView> {
  final _formKey = GlobalKey<FormState>();
  late final _Campo _idade;
  late final _Campo _peso;
  late final _Campo _altura;
  final _peitoral = _Campo('Peitoral', 'mm', 1, 100);
  final _axilar = _Campo('Axilar média', 'mm', 1, 100);
  final _triceps = _Campo('Tríceps', 'mm', 1, 100);
  final _subescapular = _Campo('Subescapular', 'mm', 1, 100);
  final _abdominal = _Campo('Abdominal', 'mm', 1, 100);
  final _suprailiaca = _Campo('Suprailíaca', 'mm', 1, 100);
  final _coxa = _Campo('Coxa', 'mm', 1, 100);

  late final List<_Campo> _medidas;
  late final List<_Campo> _dobras;

  BiologicalSex? _sexo;
  DateTime _data = DateUtils.dateOnly(DateTime.now());
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    // Pré-preenche com os dados informados pelo aluno no cadastro.
    _sexo = switch (widget.aluno.gender) {
      Gender.male => BiologicalSex.male,
      Gender.female => BiologicalSex.female,
      Gender.undisclosed || null => null,
    };
    final cadastro = widget.aluno.measurements;
    String inicial(num? valor) =>
        valor == null || valor == 0 ? '' : valor.toString();
    _idade = _Campo(
      'Idade',
      'anos',
      10,
      100,
      inteiro: true,
      inicial: inicial(cadastro?.age),
    );
    _peso = _Campo('Peso', 'kg', 20, 300, inicial: inicial(cadastro?.weightKg));
    _altura = _Campo(
      'Altura',
      'cm',
      100,
      250,
      inteiro: true,
      inicial: inicial(cadastro?.heightCm),
    );
    _medidas = [_idade, _peso, _altura];
    _dobras = [
      _peitoral,
      _axilar,
      _triceps,
      _subescapular,
      _abdominal,
      _suprailiaca,
      _coxa,
    ];
    for (final campo in [..._medidas, ..._dobras]) {
      campo.controller.addListener(_recalcular);
    }
  }

  @override
  void dispose() {
    for (final campo in [..._medidas, ..._dobras]) {
      campo.controller.dispose();
    }
    super.dispose();
  }

  void _recalcular() => setState(() {});

  /// Avaliação montada com os dados atuais, ou null se algo estiver inválido.
  PhysicalEvaluation? get _avaliacao {
    final sexo = _sexo;
    if (sexo == null || [..._medidas, ..._dobras].any((c) => c.valor == null)) {
      return null;
    }
    return PhysicalEvaluation(
      date: _data,
      instructorId: locator<FirebaseAuth>().currentUser!.uid,
      sex: sexo,
      age: _idade.valor!.toInt(),
      weightKg: _peso.valor!,
      heightCm: _altura.valor!.toInt(),
      skinfolds: Skinfolds(
        chest: _peitoral.valor!,
        midaxillary: _axilar.valor!,
        triceps: _triceps.valor!,
        subscapular: _subescapular.valor!,
        abdominal: _abdominal.valor!,
        suprailiac: _suprailiaca.valor!,
        thigh: _coxa.valor!,
      ),
    );
  }

  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (escolhida != null) setState(() => _data = escolhida);
  }

  Future<void> _salvar() async {
    final formularioValido = _formKey.currentState!.validate();
    final avaliacao = _avaliacao;
    if (!formularioValido || avaliacao == null) {
      if (_sexo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione o sexo do aluno.')),
        );
      }
      return;
    }

    setState(() => _salvando = true);
    try {
      await locator<PhysicalEvaluationService>().addEvaluation(
        widget.aluno.id,
        avaliacao,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Erro ao salvar avaliação: $e');
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar a avaliação.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final avaliacao = _avaliacao;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        title: Text(
          'Nova avaliação',
          style: GoogleFonts.barlowCondensed(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.aluno.name,
                  style: GoogleFonts.barlowCondensed(
                    fontSize: AppFontSize.headline,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  'Protocolo Jackson & Pollock · 7 dobras',
                  style: GoogleFonts.barlowCondensed(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _Secao(
                  titulo: 'Dados do aluno',
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Data da avaliação'),
                      subtitle: Text(formatarData(_data)),
                      onTap: _escolherData,
                    ),
                    SegmentedButton<BiologicalSex>(
                      emptySelectionAllowed: true,
                      segments: const [
                        ButtonSegment(
                          value: BiologicalSex.male,
                          label: Text('Masculino'),
                        ),
                        ButtonSegment(
                          value: BiologicalSex.female,
                          label: Text('Feminino'),
                        ),
                      ],
                      selected: {if (_sexo != null) _sexo!},
                      onSelectionChanged:
                          (selecao) => setState(
                            () =>
                                _sexo = selecao.isEmpty ? null : selecao.first,
                          ),
                    ),
                    const SizedBox(height: 12),
                    for (final campo in _medidas) _CampoNumerico(campo),
                  ],
                ),
                const SizedBox(height: 16),
                _Secao(
                  titulo: 'Dobras cutâneas (mm)',
                  children: [
                    for (final campo in _dobras) _CampoNumerico(campo),
                  ],
                ),
                const SizedBox(height: 16),
                _Secao(
                  titulo: 'Resultado',
                  children: [
                    if (avaliacao == null)
                      Text(
                        'Preencha o sexo e todas as medidas para calcular.',
                        style: GoogleFonts.barlowCondensed(
                          color: AppColors.textSecondary,
                        ),
                      )
                    else
                      ResultadosAvaliacao(avaliacao),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  key: const Key('botao_salvar_avaliacao'),
                  onPressed: _salvando ? null : _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _salvando
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Salvar avaliação'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  final String titulo;
  final List<Widget> children;

  const _Secao({required this.titulo, required this.children});

  @override
  Widget build(BuildContext context) {
    // Material (e não Container) para o ListTile da data exibir o toque.
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              titulo,
              style: GoogleFonts.barlowCondensed(
                fontSize: AppFontSize.subtitle,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _CampoNumerico extends StatelessWidget {
  final _Campo campo;
  const _CampoNumerico(this.campo);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: campo.controller,
        keyboardType: TextInputType.numberWithOptions(decimal: !campo.inteiro),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            campo.inteiro ? RegExp(r'\d') : RegExp(r'[\d.,]'),
          ),
        ],
        decoration: InputDecoration(
          labelText: campo.rotulo,
          suffixText: campo.unidade,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: campo.validar,
      ),
    );
  }
}
