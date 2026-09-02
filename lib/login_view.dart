import 'package:flutter/material.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD8D6D6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset('assets/logoLogin.png', height: 250),
              TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Usuário',
                  hintStyle: const TextStyle(color: Color(0xFF757575)),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 238, 238, 238),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Senha',
                  hintStyle: const TextStyle(color: Color(0xFF757575)),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 238, 238, 238),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  debugPrint('Esqueci minha senha');
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Esqueci minha senha',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 2, 89, 79),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 2,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 50),

              ElevatedButton(
                onPressed: () {
                  debugPrint('Botão clicado');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 2, 89, 79),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'ENTRAR',
                  style: TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
