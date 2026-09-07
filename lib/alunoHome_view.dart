import 'package:flutter/material.dart';

class AlunoHomeView extends StatelessWidget {
  const AlunoHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

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
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: 20.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/retanguloVerde.png',
                      height: screenHeight * 0.50,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                  Positioned(
                    top: screenHeight * 0.02,
                    child: SizedBox(
                      height: screenHeight * 0.20,
                      child: Image.asset('assets/logoGraziBranca.png'),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.40),

                  Positioned(
                    bottom: screenHeight * 0.10,
                    // IMPORTANTE: Adicionado width para o container não encolher no Positioned
                    width: screenWidth * 0.60,
                    child: Container(
                      height: screenHeight * 0.15,
                      // Removi o padding interno para as linhas divisórias encostarem perfeitamente na borda
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(
                              255,
                              2,
                              89,
                              79,
                            ).withOpacity(
                              0.3,
                            ), // Opacidade opcional para suavizar a sombra
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'Sequência 🔥',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'Progressão 📈',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'Dias',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'KG',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: screenHeight * 0.03,
                    left: screenWidth * 0.05,
                    child: const Text(
                      'Bem vindo aluno!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
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
