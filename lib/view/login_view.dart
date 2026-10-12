import 'package:academiagrazi/controller/users/login.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/view/admin/register_instructor_view.dart';
import 'package:academiagrazi/view/tab_router.dart';
import 'package:academiagrazi/view/user/self_register_view.dart';
import 'package:flutter/material.dart';
import 'package:academiagrazi/locator.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _obscureText = true;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final LoginController _controller = locator<LoginController>();

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

    final UserModel? user = await _controller.loginUser(
      email: email,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (user != null) {
      if (user.type == UserType.user) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainShell()),
        );
      } else if (user.type == UserType.instructor) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MainShell()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RegisterInstructorView()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao entrar. Tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFC107),
              Color(0xFFFFE082),
              Colors.white,
              Color(0xFFFFE082),
              Color(0xFFFFC107),
            ],
            stops: [0.0, 0.08, 0.5, 0.92, 1.0],
          ),
        ),
        padding: const EdgeInsets.all(2),
        child: Container(
          color: Colors.white,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 60.0),
              child: Column(
                children: [
                  Image.asset('assets/logoLogin.png', height: 250),

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

                  const SizedBox(height: 20),

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
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
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

                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        debugPrint('Esqueci minha senha');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: const Color(0xFFD8D6D6),
                      ),
                      child: const Text(
                        'Esqueci minha senha',
                        style: TextStyle(
                          color: Color(0xFF154974),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          height: 1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  SizedBox(
                    width: 350,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _executeLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF02594F),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'ENTRAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: 350,
                    child: OutlinedButton(
                      key: const Key('createAccountButton'),
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SelfRegisterView(),
                                  ),
                                );
                              },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF02594F),
                        side: const BorderSide(color: Color(0xFF02594F)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'CRIAR CONTA',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
