import 'dart:async';
import 'dart:math' as math;

import 'package:academiagrazi/controller/users/login.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/theme/app_font_size.dart';
import 'package:academiagrazi/view/auth_wrapper.dart';
import 'package:academiagrazi/view/login/login_scene.dart';
import 'package:academiagrazi/view/login/login_visuals.dart';
import 'package:academiagrazi/view/user/self_register_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

export 'package:academiagrazi/view/login/login_scene.dart' show TrainingMode;

/// AGB-205: apresentação interativa. Autenticação continua no LoginController
/// e no AuthWrapper, incluindo o controle de acesso por mensalidades.
class LoginView extends StatefulWidget {
  /// Permite desligar a rotação em testes de autenticação/previews estáticos.
  /// Na aplicação continua ligada, sem alterar quem pode acessar o sistema.
  final bool autoRotate;

  const LoginView({super.key, this.autoRotate = true});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with WidgetsBindingObserver {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  Timer? _rotationTimer;
  TrainingMode _selectedMode = TrainingMode.presencial;
  bool _obscureText = true;
  bool _isLoading = false;
  bool _reduceMotion = false;
  bool _appActive = true;
  bool _routeActive = true;
  bool _openingRoute = false;
  bool _dependenciesReady = false;

  bool get _formHasFocus => _emailFocus.hasFocus || _passwordFocus.hasFocus;

  bool get _canRotate =>
      mounted &&
      widget.autoRotate &&
      !_reduceMotion &&
      !_isLoading &&
      !_openingRoute &&
      _routeActive &&
      _appActive &&
      !_formHasFocus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _appActive = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _emailFocus.addListener(_handleFocusChange);
    _passwordFocus.addListener(_handleFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.of(context);
    final reduced = media.disableAnimations || media.accessibleNavigation;
    final routeActive = ModalRoute.of(context)?.isCurrent ?? true;
    final changed =
        !_dependenciesReady ||
        reduced != _reduceMotion ||
        routeActive != _routeActive;
    final firstBuild = !_dependenciesReady;
    _dependenciesReady = true;
    _reduceMotion = reduced;
    _routeActive = routeActive;
    if (changed) {
      _scheduleRotation(
        firstBuild
            ? LoginPresentation.rotationInterval
            : LoginPresentation.idleInterval,
      );
    }
  }

  @override
  void didUpdateWidget(covariant LoginView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoRotate != widget.autoRotate) {
      _scheduleRotation();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    _scheduleRotation(LoginPresentation.idleInterval);
  }

  void _scheduleRotation([
    Duration delay = LoginPresentation.rotationInterval,
  ]) {
    _rotationTimer?.cancel();
    _rotationTimer = null;
    if (!_canRotate) return;
    _rotationTimer = Timer(delay, () {
      _rotationTimer = null;
      if (!_canRotate) return;
      setState(() {
        _selectedMode =
            _selectedMode == TrainingMode.presencial
                ? TrainingMode.home
                : TrainingMode.presencial;
      });
      _scheduleRotation();
    });
  }

  void _handleFocusChange() =>
      _scheduleRotation(LoginPresentation.idleInterval);

  void _noteInteraction() => _scheduleRotation(LoginPresentation.idleInterval);

  void _selectMode(TrainingMode mode) {
    if (_isLoading) return;
    if (_selectedMode != mode) setState(() => _selectedMode = mode);
    _noteInteraction();
  }

  void _setLoading(bool loading) {
    if (!mounted) return;
    setState(() => _isLoading = loading);
    _scheduleRotation(LoginPresentation.idleInterval);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _executeLogin() async {
    if (_isLoading || _openingRoute) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    _noteInteraction();
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Preencha todos os campos.');
      return;
    }

    FocusScope.of(context).unfocus();
    _setLoading(true);
    try {
      final controller = locator.get<LoginController>();
      final UserModel? user = await controller.loginUser(
        email: email,
        password: password,
      );
      if (!mounted) return;
      if (user == null) {
        _showMessage('Não conseguimos entrar agora. Tente novamente.');
        return;
      }
      _openingRoute = true;
      _rotationTimer?.cancel();
      TextInput.finishAutofillContext();
      // NÃO navegue direto ao MainShell: o AuthWrapper aplica perfil e
      // StudentAccessGate, preservando Planos e Mensalidades (PR #109).
      Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    } catch (error) {
      // Nunca registrar credenciais, dados de usuário ou mensagem crua.
      debugPrint('Falha no login: ${error.runtimeType}');
      if (mounted) {
        _openingRoute = false;
        _showMessage('Não conseguimos entrar agora. Tente novamente.');
      }
    } finally {
      if (mounted) _setLoading(false);
    }
  }

  Future<void> _handlePasswordReset() async {
    if (_isLoading || _openingRoute) return;
    _noteInteraction();
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Informe seu e-mail no campo acima para recuperar a senha.');
      return;
    }
    FocusScope.of(context).unfocus();
    _setLoading(true);
    try {
      final success = await locator.get<LoginController>().resetPassword(
        email: email,
      );
      if (!mounted) return;
      _showMessage(
        success
            ? 'Um link de recuperação foi enviado para seu e-mail.'
            : 'Não conseguimos processar a solicitação agora. Verifique o e-mail.',
      );
    } catch (error) {
      debugPrint('Falha na recuperação de senha: ${error.runtimeType}');
      _showMessage(
        'Não conseguimos processar a solicitação agora. Verifique o e-mail.',
      );
    } finally {
      if (mounted) _setLoading(false);
    }
  }

  Future<void> _openRegistration() async {
    if (_isLoading || _openingRoute) return;
    _openingRoute = true;
    _rotationTimer?.cancel();
    FocusScope.of(context).unfocus();
    try {
      await Navigator.of(
        context,
      ).push<void>(MaterialPageRoute(builder: (_) => const SelfRegisterView()));
    } finally {
      if (mounted) {
        _openingRoute = false;
        _scheduleRotation(LoginPresentation.idleInterval);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rotationTimer?.cancel();
    _emailFocus.removeListener(_handleFocusChange);
    _passwordFocus.removeListener(_handleFocusChange);
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Center(
        child: ConstrainedBox(
          key: const Key('login_area_responsiva'),
          constraints: const BoxConstraints(
            maxWidth: LoginPresentation.maxWidth,
          ),
          child: Listener(
            onPointerDown: (_) => _noteInteraction(),
            onPointerSignal: (_) => _noteInteraction(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: LoginScenery(
                    mode: _selectedMode,
                    reduceMotion: _reduceMotion,
                  ),
                ),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final heroGap =
                          (constraints.maxHeight * 0.10)
                              .clamp(48.0, 120.0)
                              .toDouble();
                      return SingleChildScrollView(
                        key: const Key('login_rolagem'),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: math.max(
                              0.0,
                              constraints.maxHeight - 36,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _hero(),
                              SizedBox(height: heroGap),
                              _form(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: LoginBrand()),
        const SizedBox(height: 24),
        const Text(
          'Seu corpo.\nSeu ritmo.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: AppFontSize.display,
            fontWeight: FontWeight.w700,
            height: 1.02,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: LoginSceneCopy(
            mode: _selectedMode,
            reduceMotion: _reduceMotion,
          ),
        ),
        const SizedBox(height: 20),
        LoginModeSelector(
          mode: _selectedMode,
          enabled: !_isLoading,
          reduceMotion: _reduceMotion,
          onChanged: _selectMode,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    final radius = BorderRadius.circular(16);
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: AppFontSize.body,
      ),
      prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surfaceSoft,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _form() {
    return LoginFormSurface(
      key: const Key('login_formulario'),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('campo_email_login'),
              controller: _emailController,
              focusNode: _emailFocus,
              enabled: !_isLoading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => _noteInteraction(),
              onSubmitted: (_) => _passwordFocus.requestFocus(),
              style: const TextStyle(
                fontSize: AppFontSize.body,
                color: AppColors.textPrimary,
              ),
              decoration: _inputDecoration(
                hint: 'Email',
                icon: Icons.mail_outline_rounded,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('campo_senha_login'),
              controller: _passwordController,
              focusNode: _passwordFocus,
              enabled: !_isLoading,
              obscureText: _obscureText,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => _noteInteraction(),
              onSubmitted: (_) => _executeLogin(),
              style: const TextStyle(
                fontSize: AppFontSize.body,
                color: AppColors.textPrimary,
              ),
              decoration: _inputDecoration(
                hint: 'Senha',
                icon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  key: const Key('botao_visibilidade_senha'),
                  tooltip: _obscureText ? 'Mostrar senha' : 'Ocultar senha',
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            setState(() => _obscureText = !_obscureText);
                            _noteInteraction();
                          },
                  color: AppColors.textSecondary,
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              key: const Key('botao_entrar_login'),
              onPressed: _isLoading ? null : _executeLogin,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
                backgroundColor: AppColors.primaryDark,
                foregroundColor: AppColors.surface,
                disabledBackgroundColor: AppColors.primaryDark,
                disabledForegroundColor: AppColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: AppFontSize.subtitle,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.surface,
                          semanticsLabel: 'Aguarde',
                        ),
                      )
                      : const Text('Entrar'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('botao_cadastrar_login'),
              onPressed: _isLoading ? null : _openRegistration,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
                foregroundColor: AppColors.primaryDark,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: AppFontSize.subtitle,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Criar minha conta'),
            ),
            const SizedBox(height: 6),
            TextButton(
              key: const Key('botao_recuperar_senha_login'),
              onPressed: _isLoading ? null : _handlePasswordReset,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                minimumSize: const Size(0, 48),
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: AppFontSize.small,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('Esqueci minha senha'),
            ),
          ],
        ),
      ),
    );
  }
}
