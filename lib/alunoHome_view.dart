import 'package:flutter/material.dart';

class AlunoHomeView extends StatelessWidget {
  const AlunoHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD8D6D6),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 2, 89, 79),
        title: const Text(
          'Painel do Aluno',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/retanguloVerde.png', // Substitua pela sua imagem
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                  // 2. Elementos por cima da imagem
                  Positioned(
                    top: 10,
                    child: Image.asset('assets/logoGraziBranca.png'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
