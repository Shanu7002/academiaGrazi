import 'package:flutter/material.dart';
import 'login_view.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD8D6D6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 60.0),
          child: Column(
            children: [
              Image.asset('assets/logoLogin.png', height: 250),
              TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Digite seu nome completo',
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
                  hintText: 'Email',
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

              TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Confirme sua senha',
                  hintStyle: const TextStyle(color: Color(0xFF757575)),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 238, 238, 238),
                ),
              ),
              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  child: ElevatedButton(
                    onPressed: () {
                      debugPrint('Já tenho cadastro');
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: Color(0xFFD8D6D6),
                    ),
                    child: Text(
                      'Já tenho cadastro',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 21, 73, 116),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),

              SizedBox(
                width: 350,
                child: ElevatedButton(
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
                    'CADASTRAR',
                    style: TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 3,
                    ),
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
