import 'package:academiagrazi/controller/users/register_user.dart';
import 'package:academiagrazi/models/users/registration_profile.dart';
import 'package:academiagrazi/service/users/register.dart';
import 'package:academiagrazi/view/tab_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SelfRegisterView extends StatefulWidget {
  final RegisterUserController controller;
  final RegisterService userService;
  final FirebaseAuth authInstance;

  const SelfRegisterView({
    super.key,
    required this.controller,
    required this.userService,
    required this.authInstance,
  });

  @override
  State<SelfRegisterView> createState() => _SelfRegisterViewState();
}

class _SelfRegisterViewState extends State<SelfRegisterView> {
  static const _primary = Color(0xFF005A4F);
  static const _secondary = Color(0xFFFF7943);
  static const _background = Color(0xFFF5FAFF);
  static const _surface = Color(0xFFFFFFFF);
  static const _surfaceLow = Color(0xFFE9F5FF);
  static const _text = Color(0xFF001E2D);
  static const _muted = Color(0xFF3F4946);

  final RegistrationDraft _draft = RegistrationDraft();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _codeController = TextEditingController();
  final _notesController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _phoneController = TextEditingController();

  int _step = 0;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    _codeController.dispose();
    _notesController.dispose();
    _emergencyNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    switch (_step) {
      case 0:
        if (!_validateAccount()) return;
        _nextStep();
      case 1:
        await _validateCodeAndContinue();
      case 2:
        _nextStep();
      case 3:
        if (_draft.primaryGoal == null) {
          _showMessage('Escolha seu objetivo principal.');
          return;
        }
        _nextStep();
      case 4:
        _draft.healthNotes = _notesController.text.trim();
        _nextStep();
      case 5:
        await _finishRegistration();
    }
  }

  bool _validateAccount() {
    _draft.name = _nameController.text.trim();
    _draft.email = _emailController.text.trim();
    _draft.password = _passwordController.text;
    _draft.passwordConfirmation = _confirmationController.text;

    final validEmail = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    ).hasMatch(_draft.email);
    if (_draft.name.isEmpty || !validEmail) {
      _showMessage('Informe seu nome e um e-mail válido.');
      return false;
    }
    if (_draft.password.length < 8) {
      _showMessage('A senha deve ter pelo menos 8 caracteres.');
      return false;
    }
    if (_draft.password != _draft.passwordConfirmation) {
      _showMessage('As senhas não são iguais.');
      return false;
    }
    if (_draft.termsAcceptedAt == null) {
      _showMessage('Aceite os Termos de Uso e a Política de Privacidade.');
      return false;
    }
    return true;
  }

  Future<void> _validateCodeAndContinue() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 8) {
      _showMessage('Informe o código de 8 caracteres do seu instrutor.');
      return;
    }

    setState(() => _loading = true);
    try {
      final info = await widget.controller.validateInstructorCode(code);
      if (!mounted) return;
      if (info == null) {
        _showMessage('Código inválido ou inativo.');
        return;
      }
      _draft.instructorCode = info.code;
      _draft.instructorId = info.instructorId;
      _draft.instructorName = info.instructorName;
      _nextStep();
    } on Exception {
      if (mounted) {
        _showMessage('Não foi possível validar o código. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _finishRegistration() async {
    _draft.emergencyName = _emergencyNameController.text.trim();
    _draft.emergencyPhone = _phoneController.text;
    final digits = _draft.emergencyPhone.replaceAll(RegExp(r'\D'), '');
    if (_draft.emergencyName.isEmpty ||
        _draft.emergencyRelationship.isEmpty ||
        (digits.length != 10 && digits.length != 11)) {
      _showMessage('Preencha corretamente o contato de emergência.');
      return;
    }

    setState(() => _loading = true);
    final result = await widget.controller.registerSelf(draft: _draft);
    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.isSuccess) {
      _showMessage(_resultMessage(result.status));
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            icon: const Icon(Icons.celebration, color: _secondary, size: 44),
            title: Text(
              'CADASTRO CONCLUÍDO!',
              textAlign: TextAlign.center,
              style: GoogleFonts.anton(color: _primary),
            ),
            content: const Text(
              'Seu perfil foi configurado com sucesso. Sua jornada de treinamento consciente está prestes a começar.',
              textAlign: TextAlign.center,
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(backgroundColor: _primary),
                  child: const Text('ENTRAR NO PAINEL'),
                ),
              ),
            ],
          ),
    );
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder:
            (_) => MainShell(
              userService: widget.userService,
              authInstance: widget.authInstance,
            ),
      ),
      (_) => false,
    );
  }

  String _resultMessage(SelfRegistrationStatus status) {
    switch (status) {
      case SelfRegistrationStatus.invalidInstructorCode:
        return 'O código do instrutor não é mais válido.';
      case SelfRegistrationStatus.emailAlreadyInUse:
        return 'Este e-mail já está cadastrado.';
      case SelfRegistrationStatus.weakPassword:
        return 'Escolha uma senha mais forte.';
      case SelfRegistrationStatus.networkError:
        return 'Sem conexão com o Firebase. Tente novamente.';
      case SelfRegistrationStatus.invalidData:
        return 'Revise os dados informados.';
      case SelfRegistrationStatus.persistenceError:
        return 'Não foi possível concluir o cadastro.';
      case SelfRegistrationStatus.success:
        return '';
    }
  }

  void _nextStep() => setState(() => _step++);

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _step--);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) setState(() => _step--);
      },
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _background,
          elevation: 0,
          leading: IconButton(
            tooltip: 'Voltar',
            onPressed: _loading ? null : _back,
            icon: const Icon(Icons.arrow_back, color: _primary),
          ),
          title: Text(
            'GRAZI BRAZ',
            style: GoogleFonts.anton(color: _primary, letterSpacing: 1.2),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  _ProgressHeader(step: _step),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: KeyedSubtree(
                          key: ValueKey(_step),
                          child: _buildStep(),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        key: const Key('registrationContinueButton'),
                        onPressed: _loading ? null : _continue,
                        style: FilledButton.styleFrom(
                          backgroundColor: _secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon:
                            _loading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Icon(
                                  _step == 5
                                      ? Icons.check_circle_outline
                                      : Icons.arrow_forward,
                                ),
                        label: Text(
                          _step == 5 ? 'FINALIZAR CADASTRO' : 'CONTINUAR',
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _accountStep();
      case 1:
        return _codeStep();
      case 2:
        return _measurementsStep();
      case 3:
        return _goalStep();
      case 4:
        return _healthStep();
      case 5:
        return _emergencyStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _accountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('CONTA & ACESSO', 'Vamos criar seu acesso pessoal e seguro.'),
        _field(
          key: const Key('registrationName'),
          controller: _nameController,
          label: 'NOME COMPLETO',
          hint: 'Como prefere ser chamada?',
          icon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
        ),
        _field(
          key: const Key('registrationEmail'),
          controller: _emailController,
          label: 'E-MAIL',
          hint: 'seuemail@exemplo.com',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        _field(
          key: const Key('registrationPassword'),
          controller: _passwordController,
          label: 'SENHA DE ACESSO',
          hint: 'Mínimo de 8 caracteres',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffix: IconButton(
            onPressed:
                () => setState(() => _obscurePassword = !_obscurePassword),
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
            ),
          ),
        ),
        _field(
          key: const Key('registrationPasswordConfirmation'),
          controller: _confirmationController,
          label: 'CONFIRMAR SENHA',
          hint: 'Repita sua senha',
          icon: Icons.lock_reset,
          obscureText: _obscureConfirmation,
          suffix: IconButton(
            onPressed:
                () => setState(
                  () => _obscureConfirmation = !_obscureConfirmation,
                ),
            icon: Icon(
              _obscureConfirmation ? Icons.visibility_off : Icons.visibility,
            ),
          ),
        ),
        CheckboxListTile(
          key: const Key('registrationTerms'),
          contentPadding: EdgeInsets.zero,
          activeColor: _primary,
          value: _draft.termsAcceptedAt != null,
          onChanged:
              (selected) => setState(
                () =>
                    _draft.termsAcceptedAt =
                        selected == true ? DateTime.now() : null,
              ),
          title: const Text(
            'Li e concordo com os Termos de Uso e a Política de Privacidade (LGPD).',
            style: TextStyle(fontSize: 13, color: _muted),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _codeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(
          'SEU INSTRUTOR',
          'Use o código compartilhado pelo profissional responsável pelo seu acompanhamento.',
        ),
        _InfoBanner(
          icon: Icons.link,
          title: 'Conexão segura',
          message:
              'O código vincula seu perfil ao instrutor certo e pode ser usado por todos os alunos dele.',
        ),
        const SizedBox(height: 24),
        _field(
          key: const Key('registrationInstructorCode'),
          controller: _codeController,
          label: 'CÓDIGO DO INSTRUTOR',
          hint: 'Ex: GR4Z1ABC',
          icon: Icons.key,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            LengthLimitingTextInputFormatter(8),
            FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
            TextInputFormatter.withFunction(
              (oldValue, newValue) => newValue.copyWith(
                text: newValue.text.toUpperCase(),
                selection: newValue.selection,
              ),
            ),
          ],
        ),
        if (_draft.instructorName != null)
          _InfoBanner(
            icon: Icons.verified,
            title: 'Instrutor encontrado',
            message: _draft.instructorName!,
          ),
      ],
    );
  }

  Widget _measurementsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(
          'SUAS MEDIDAS',
          'Para adaptarmos as cargas e treinos ao seu perfil.',
        ),
        _CounterCard(
          title: 'IDADE',
          value: '${_draft.age}',
          unit: 'anos',
          onDecrease:
              _draft.age > 14 ? () => setState(() => _draft.age--) : null,
          onIncrease:
              _draft.age < 99 ? () => setState(() => _draft.age++) : null,
        ),
        const SizedBox(height: 16),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ALTURA', style: _labelStyle),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: '${_draft.heightCm}',
                    style: GoogleFonts.anton(fontSize: 46, color: _primary),
                    children: const [
                      TextSpan(
                        text: ' cm',
                        style: TextStyle(fontSize: 15, color: _muted),
                      ),
                    ],
                  ),
                ),
              ),
              Slider(
                key: const Key('registrationHeight'),
                value: _draft.heightCm.toDouble(),
                min: 130,
                max: 210,
                divisions: 80,
                activeColor: _primary,
                onChanged:
                    (value) => setState(() => _draft.heightCm = value.round()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _CounterCard(
          title: 'PESO ATUAL',
          value: _draft.weightKg.toStringAsFixed(1),
          unit: 'kg',
          onDecrease:
              _draft.weightKg > 30
                  ? () => setState(() => _draft.weightKg -= 0.5)
                  : null,
          onIncrease:
              _draft.weightKg < 250
                  ? () => setState(() => _draft.weightKg += 0.5)
                  : null,
        ),
        const SizedBox(height: 16),
        const _InfoBanner(
          icon: Icons.lock_outline,
          title: 'Dados confidenciais',
          message: 'Utilizados apenas para personalizar seu acompanhamento.',
        ),
      ],
    );
  }

  Widget _goalStep() {
    const goals = [
      (
        PrimaryGoal.weightLoss,
        'Emagrecimento & Definição',
        'Redução de gordura com tônus muscular',
        Icons.local_fire_department,
      ),
      (
        PrimaryGoal.muscleGain,
        'Ganho de Massa Muscular',
        'Hipertrofia e densidade com constância',
        Icons.fitness_center,
      ),
      (
        PrimaryGoal.conditioning,
        'Condicionamento & Saúde',
        'Energia, disposição diária e vigor físico',
        Icons.monitor_heart_outlined,
      ),
      (
        PrimaryGoal.strengthening,
        'Fortalecimento & Postura',
        'Alívio de dores articulares e sustentação',
        Icons.accessibility_new,
      ),
      (
        PrimaryGoal.mobility,
        'Mobilidade & Flexibilidade',
        'Liberdade de movimento e fluidez do corpo',
        Icons.self_improvement,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(
          'QUAL O SEU OBJETIVO?',
          'Escolha sua principal meta para direcionarmos o plano ideal.',
        ),
        for (final goal in goals) ...[
          _GoalCard(
            key: Key('goal-${goal.$1.name}'),
            selected: _draft.primaryGoal == goal.$1,
            title: goal.$2,
            subtitle: goal.$3,
            icon: goal.$4,
            onTap: () => setState(() => _draft.primaryGoal = goal.$1),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _healthStep() {
    const conditionOptions = {
      'none': 'Nenhuma dor',
      'lowerBack': 'Coluna/Lombar',
      'knee': 'Joelho',
      'shoulder': 'Ombro',
      'hypertension': 'Hipertensão',
      'other': 'Outra',
    };
    const restrictionOptions = {
      'none': 'Não possuo',
      'asthmaBronchitis': 'Asma/Bronquite',
      'latexElastic': 'Látex/Elásticos',
      'other': 'Outras',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(
          'SAÚDE & CUIDADOS',
          'Para prescrevermos exercícios seguros e adaptados para você.',
        ),
        const _InfoBanner(
          icon: Icons.health_and_safety_outlined,
          title: 'Treino responsável',
          message:
              'Cada corpo tem sua história. Suas respostas ajustam cargas e movimentos.',
        ),
        const SizedBox(height: 24),
        const Text('DORES OU CONDIÇÕES', style: _labelStyle),
        const SizedBox(height: 10),
        _chipGroup(conditionOptions, _draft.conditions),
        const SizedBox(height: 16),
        _field(
          controller: _notesController,
          label: 'OBSERVAÇÕES',
          hint: 'Dores ou cirurgias (opcional)',
          icon: Icons.notes,
        ),
        const Text('ALERGIAS & RESTRIÇÕES RESPIRATÓRIAS', style: _labelStyle),
        const SizedBox(height: 10),
        _chipGroup(restrictionOptions, _draft.restrictions),
        const SizedBox(height: 18),
        const _InfoBanner(
          icon: Icons.verified_user_outlined,
          title: 'Privacidade',
          message:
              'Informações privadas, utilizadas exclusivamente pela equipe Grazi Braz.',
        ),
      ],
    );
  }

  Widget _emergencyStep() {
    const relationships = {
      'partner': 'Cônjuge / Parceiro(a)',
      'parent': 'Pai / Mãe',
      'sibling': 'Irmão / Irmã',
      'child': 'Filho(a)',
      'friend': 'Amigo(a) Próximo(a)',
      'other': 'Outro',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(
          'CONTATO DE SEGURANÇA',
          'Uma pessoa de confiança para qualquer eventualidade durante suas práticas.',
        ),
        const _InfoBanner(
          icon: Icons.lock_outline,
          title: 'Privado & protegido',
          message: 'Dados resguardados sob sigilo e conformidade com a LGPD.',
        ),
        const SizedBox(height: 24),
        _field(
          key: const Key('registrationEmergencyName'),
          controller: _emergencyNameController,
          label: 'NOME DA PESSOA',
          hint: 'Ex: Carlos Oliveira',
          icon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
        ),
        const Text('PARENTESCO OU VÍNCULO', style: _labelStyle),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: const Key('registrationRelationship'),
          initialValue:
              _draft.emergencyRelationship.isEmpty
                  ? null
                  : _draft.emergencyRelationship,
          decoration: _inputDecoration(
            hint: 'Selecione uma opção',
            icon: Icons.diversity_1,
          ),
          items:
              relationships.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
          onChanged:
              (value) =>
                  setState(() => _draft.emergencyRelationship = value ?? ''),
        ),
        const SizedBox(height: 18),
        _field(
          key: const Key('registrationEmergencyPhone'),
          controller: _phoneController,
          label: 'TELEFONE OU WHATSAPP',
          hint: '(00) 00000-0000',
          icon: Icons.call_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [_BrazilianPhoneFormatter()],
        ),
      ],
    );
  }

  Widget _chipGroup(Map<String, String> options, Set<String> selected) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          options.entries.map((entry) {
            final isSelected = selected.contains(entry.key);
            return FilterChip(
              key: Key('health-${entry.key}-${entry.value}'),
              selected: isSelected,
              label: Text(entry.value),
              selectedColor: _primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : _muted,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) {
                setState(() {
                  if (entry.key == 'none') {
                    selected
                      ..clear()
                      ..add('none');
                    return;
                  }
                  selected.remove('none');
                  if (!selected.add(entry.key)) selected.remove(entry.key);
                  if (selected.isEmpty) selected.add('none');
                });
              },
            );
          }).toList(),
    );
  }

  Widget _title(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.anton(
              fontSize: 32,
              color: _primary,
              letterSpacing: .4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 15, color: _muted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _field({
    Key? key,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    Widget? suffix,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _labelStyle),
          const SizedBox(height: 8),
          TextField(
            key: key,
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            obscureText: obscureText,
            inputFormatters: inputFormatters,
            decoration: _inputDecoration(
              hint: hint,
              icon: icon,
              suffix: suffix,
            ),
          ),
        ],
      ),
    );
  }

  static InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF6F7976)),
      prefixIcon: Icon(icon, color: _primary),
      suffixIcon: suffix,
      filled: true,
      fillColor: _surfaceLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
    );
  }

  static const _labelStyle = TextStyle(
    fontSize: 12,
    color: _muted,
    fontWeight: FontWeight.w700,
    letterSpacing: .7,
  );
}

class _ProgressHeader extends StatelessWidget {
  final int step;

  const _ProgressHeader({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ETAPA ${step + 1} DE 6',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _SelfRegisterViewState._muted,
                  letterSpacing: .8,
                ),
              ),
              Text(
                '${(((step + 1) / 6) * 100).round()}% CONCLUÍDO',
                style: const TextStyle(
                  fontSize: 11,
                  color: _SelfRegisterViewState._muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (step + 1) / 6,
            minHeight: 7,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: const Color(0xFFDDF1FF),
            color: const Color(0xFF2CA99F),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _SelfRegisterViewState._surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D092837),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CounterCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  const _CounterCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(title, style: _SelfRegisterViewState._labelStyle),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton.filledTonal(
                onPressed: onDecrease,
                icon: const Icon(Icons.remove),
              ),
              Text.rich(
                TextSpan(
                  text: value,
                  style: GoogleFonts.anton(
                    fontSize: 46,
                    color: _SelfRegisterViewState._primary,
                  ),
                  children: [
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(
                        fontSize: 15,
                        color: _SelfRegisterViewState._muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: onIncrease,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _GoalCard({
    super.key,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : _SelfRegisterViewState._text;
    return Material(
      color:
          selected
              ? _SelfRegisterViewState._primary
              : _SelfRegisterViewState._surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    selected
                        ? const Color(0xFF2CA99F)
                        : _SelfRegisterViewState._surfaceLow,
                child: Icon(icon, color: foreground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.barlowCondensed(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color:
                            selected
                                ? const Color(0xFFA8F0E1)
                                : _SelfRegisterViewState._muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color:
                    selected ? Colors.white : _SelfRegisterViewState._primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InfoBanner({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFDDF5F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _SelfRegisterViewState._primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _SelfRegisterViewState._primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  message,
                  style: const TextStyle(
                    color: _SelfRegisterViewState._muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrazilianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) digits = digits.substring(0, 11);
    var formatted = digits;
    if (digits.length > 2) {
      formatted = '(${digits.substring(0, 2)}) ${digits.substring(2)}';
    } else if (digits.isNotEmpty) {
      formatted = '($digits';
    }
    if (digits.length > 7) {
      final separator = digits.length == 11 ? 7 : 6;
      formatted =
          '(${digits.substring(0, 2)}) ${digits.substring(2, separator)}-${digits.substring(separator)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
