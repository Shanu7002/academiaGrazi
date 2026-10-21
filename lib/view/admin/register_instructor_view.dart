import 'package:academiagrazi/controller/users/register_instructor.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/users/register_user.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tela usada pelo admin para criar o acesso de um novo professor.
class RegisterInstructorView extends StatefulWidget {
  const RegisterInstructorView({super.key});

  @override
  State<RegisterInstructorView> createState() => _RegisterInstructorViewState();
}

class _RegisterInstructorViewState extends State<RegisterInstructorView> {
  static const int _minPasswordLength = 6;
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final FirebaseAuth _authInstance = locator<FirebaseAuth>();
  final RegisterUserService _userService = locator<RegisterUserService>();
  final RegisterInstructorController _controller =
      locator<RegisterInstructorController>();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final firebaseUser = _authInstance.currentUser;
    if (firebaseUser == null) {
      _showMessage('Sua sessão expirou. Entre novamente.');
      return;
    }

    setState(() => _isLoading = true);

    final admin = await _userService.getUserById(firebaseUser.uid);

    if (!mounted) return;

    if (admin == null) {
      setState(() => _isLoading = false);
      _showMessage('Não foi possível carregar os dados do administrador.');
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    final result = await _controller.registerInstructor(
      currentUser: admin,
      name: name,
      email: email,
      password: _passwordController.text,
      passwordCheck: _confirmController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != InstructorRegistrationResult.success) {
      _showMessage(_errorMessage(result));
      return;
    }

    await _showSuccessDialog(name: name, email: email);
  }

  static String _errorMessage(InstructorRegistrationResult result) {
    switch (result) {
      case InstructorRegistrationResult.emailInUse:
        return 'Já existe uma conta com esse e-mail.';
      case InstructorRegistrationResult.invalidEmail:
        return 'O e-mail informado é inválido.';
      case InstructorRegistrationResult.weakPassword:
        return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
      case InstructorRegistrationResult.passwordMismatch:
        return 'As senhas não são iguais.';
      case InstructorRegistrationResult.networkError:
        return 'Sem conexão com a internet. Tente novamente.';
      case InstructorRegistrationResult.notAllowed:
        return 'Somente administradores podem cadastrar professores.';
      case InstructorRegistrationResult.permissionDenied:
        return 'O banco recusou a gravação do professor (permissão negada). '
            'Verifique se as regras do Firestore foram publicadas.';
      case InstructorRegistrationResult.success:
      case InstructorRegistrationResult.unknown:
        return 'Não foi possível cadastrar o professor. Tente novamente.';
    }
  }

  Future<void> _showSuccessDialog({
    required String name,
    required String email,
  }) async {
    final registerAnother = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: AppColors.surface,
            icon: const CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.avatarBackground,
              child: Icon(Icons.check_rounded, color: AppColors.primary),
            ),
            title: Text(
              'Professor cadastrado',
              style: GoogleFonts.barlowCondensed(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            content: Text(
              '$name já pode entrar no app com o e-mail $email e a senha '
              'definida por você.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.4,
                color: AppColors.slateText,
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                key: const Key('botao_concluir_cadastro'),
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Concluir'),
              ),
              FilledButton(
                key: const Key('botao_cadastrar_outro'),
                onPressed: () => Navigator.pop(dialogContext, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Cadastrar outro'),
              ),
            ],
          ),
    );

    if (!mounted) return;

    if (registerAnother == true || !Navigator.canPop(context)) {
      _clearForm();
    } else {
      Navigator.pop(context);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmController.clear();
  }

  String? _validateName(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Informe o nome do professor.';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Informe o e-mail do professor.';
    if (!_emailPattern.hasMatch(email)) return 'Informe um e-mail válido.';
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < _minPasswordLength) {
      return 'A senha precisa ter pelo menos $_minPasswordLength caracteres.';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _passwordController.text) return 'As senhas não são iguais.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading:
            canGoBack
                ? IconButton(
                  tooltip: 'Voltar',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                )
                : null,
        title: Text(
          'Equipe',
          style: GoogleFonts.barlowCondensed(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'CADASTRAR PROFESSOR',
                      style: GoogleFonts.anton(
                        fontSize: 30,
                        color: AppColors.primary,
                        letterSpacing: .4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Crie o acesso de um novo professor da academia. Ele vai '
                      'entrar no app com o e-mail e a senha definidos aqui.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.slateText,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionCard(
                      title: 'Dados do professor',
                      icon: Icons.badge_outlined,
                      children: [
                        _FormField(
                          key: const Key('campo_nome_professor'),
                          controller: _nameController,
                          label: 'NOME COMPLETO',
                          hint: 'Ex.: Marina Souza',
                          icon: Icons.person_outline,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          validator: _validateName,
                        ),
                        _FormField(
                          key: const Key('campo_email_professor'),
                          controller: _emailController,
                          label: 'E-MAIL',
                          hint: 'professor@email.com',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _validateEmail,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Acesso ao app',
                      icon: Icons.lock_outline,
                      children: [
                        _FormField(
                          key: const Key('campo_senha_professor'),
                          controller: _passwordController,
                          label: 'SENHA INICIAL',
                          hint: 'Mínimo de $_minPasswordLength caracteres',
                          icon: Icons.key_outlined,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          validator: _validatePassword,
                          suffix: _VisibilityToggle(
                            obscure: _obscurePassword,
                            onPressed:
                                () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                          ),
                        ),
                        _FormField(
                          key: const Key('campo_confirmar_senha_professor'),
                          controller: _confirmController,
                          label: 'CONFIRMAR SENHA',
                          hint: 'Repita a senha inicial',
                          icon: Icons.key_outlined,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _isLoading ? null : _submit(),
                          validator: _validateConfirm,
                          suffix: _VisibilityToggle(
                            obscure: _obscureConfirmPassword,
                            onPressed:
                                () => setState(
                                  () =>
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accentSurface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 18,
                                color: AppColors.accentDark,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Passe a senha inicial para o professor '
                                  'pessoalmente e oriente-o a não '
                                  'compartilhá-la.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: AppColors.textBody,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        key: const Key('botao_cadastrar_professor'),
                        onPressed: _isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primaryBorderAlpha,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon:
                            _isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.person_add_alt_1),
                        label: Text(
                          _isLoading ? 'CADASTRANDO...' : 'CADASTRAR PROFESSOR',
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: .6,
                            color: Colors.white,
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
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderTranslucent),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final String? Function(String?) validator;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  const _FormField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: .7,
              color: AppColors.slateText,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            textCapitalization: textCapitalization,
            autocorrect: false,
            validator: validator,
            onFieldSubmitted: onSubmitted,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
              prefixIcon: Icon(icon, color: AppColors.primary),
              suffixIcon: suffix,
              filled: true,
              fillColor: AppColors.surfaceSoft,
              border: OutlineInputBorder(
                borderRadius: radius,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  final bool obscure;
  final VoidCallback onPressed;

  const _VisibilityToggle({required this.obscure, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: obscure ? 'Mostrar senha' : 'Ocultar senha',
      onPressed: onPressed,
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppColors.textSecondary,
      ),
    );
  }
}
