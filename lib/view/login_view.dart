import 'package:academiagrazi/controller/users/login.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/view/auth_wrapper.dart';
import 'package:academiagrazi/view/user/self_register_view.dart';
import 'package:flutter/material.dart';

enum TrainingMode { presencial, home }

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LandingPageState();
}

class _LandingPageState extends State<LoginView> {
  bool _obscureText = true;
  bool _isLoading = false;
  TrainingMode _selectedMode = TrainingMode.presencial;

  static const Color _primaryDarkGreen = Color(0xFF0A4D43);
  static const Color _badgeLightGreen = Color(0xFFDFF4F0);
  static const Color _textGrey = Color(0xFF5A5A5A);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _executeLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final LoginController controller = locator.get<LoginController>();

    final UserModel? user = await controller.loginUser(
      email: email,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (user != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao entrar. Tente novamente.')),
      );
    }
  }

  Future<void> _handlePasswordReset() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Informe seu e-mail no campo acima para recuperar a senha.',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final LoginController controller = locator.get<LoginController>();

    final bool success = await controller.resetPassword(email: email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Um link de recuperação foi enviado para seu e-mail.'
              : 'Não foi possível processar a solicitação. Verifique o e-mail.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Image.asset(
                    _selectedMode == TrainingMode.presencial
                        ? 'assets/login/treinoPresencialBackground.png'
                        : 'assets/login/treinoCasaBackground.webp',
                    key: ValueKey<TrainingMode>(_selectedMode),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0xFFF6F4F0).withOpacity(0.65),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),
                            _buildHeader(),

                            const Spacer(flex: 1),
                            _buildHeroSection(),

                            const SizedBox(height: 24),
                            _buildBadges(),

                            const Spacer(flex: 2),
                            _buildActionCard(),

                            const SizedBox(height: 16),
                            _buildForgotPassword(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'GRAZI BRAZ',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: _primaryDarkGreen,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return const Column(
      children: [
        Text(
          'Seu corpo.\nSeu ritmo.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: _primaryDarkGreen,
            height: 1.1,
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Treine na academia ou em casa com\norientação que acompanha sua\nevolução de verdade.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _textGrey,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildToggleButton(
          title: 'Presencial',
          isActive: _selectedMode == TrainingMode.presencial,
          onTap: () {
            if (_selectedMode != TrainingMode.presencial) {
              setState(() => _selectedMode = TrainingMode.presencial);
            }
          },
        ),
        const SizedBox(width: 12),
        _buildToggleButton(
          title: 'Treino em casa',
          isActive: _selectedMode == TrainingMode.home,
          onTap: () {
            if (_selectedMode != TrainingMode.home) {
              setState(() => _selectedMode = TrainingMode.home);
            }
          },
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _badgeLightGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? _primaryDarkGreen : _textGrey,
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hintText: 'Email',
              hintStyle: const TextStyle(color: Color(0xFF757575)),
              filled: true,
              fillColor: const Color(0xFFEEEEEE),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscureText,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hintText: 'Senha',
              hintStyle: const TextStyle(color: Color(0xFF757575)),
              filled: true,
              fillColor: const Color(0xFFEEEEEE),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF757575),
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _executeLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryDarkGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Entrar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed:
                _isLoading
                    ? null
                    : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SelfRegisterView(),
                        ),
                      );
                    },
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryDarkGreen,
              side: const BorderSide(color: _primaryDarkGreen, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Criar minha conta',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPassword() {
    return GestureDetector(
      onTap: _isLoading ? null : _handlePasswordReset,
      child: const Text(
        'Esqueci minha senha',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _textGrey,
        ),
      ),
    );
  }
}
