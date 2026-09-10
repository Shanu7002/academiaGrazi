import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: 20.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: screenHeight * 0.50,
              width: double.infinity,
              child: Stack(
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
                      height: screenHeight * 0.18,
                      child: Image.asset('assets/logoGraziBranca.png'),
                    ),
                  ),
                  Positioned(
                    bottom: screenHeight * 0.08,
                    width: screenWidth * 0.60,
                    child: Container(
                      height: screenHeight * 0.14,
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
                            ).withOpacity(0.3),
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
                                        fontSize: 14,
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
                                        fontSize: 14,
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
                                        fontSize: 14,
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
                                        fontSize: 14,
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
                    bottom: screenHeight * 0.02,
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
            ),

            const SizedBox(height: 30),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Treino de hoje',
                  style: GoogleFonts.antonio(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Image.asset(
                    'assets/linhaGradiente.png',
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Container(
              width: screenWidth * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(
                      255,
                      2,
                      89,
                      79,
                    ).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      print("Botão laranja clicado!");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 244, 121, 67),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      '4 exercícios',
                      style: TextStyle(
                        fontFamily: GoogleFonts.inter().fontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    'TREINO B - INFERIORES',
                    style: GoogleFonts.antonio(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 2, 89, 79),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Quadríceps, posterior e panturrilha',
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  ElevatedButton(
                    onPressed: () {
                      print("Botão iniciar treino clicado!");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 244, 121, 67),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(300, 50),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_arrow, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Iniciar treino',
                          style: TextStyle(
                            fontFamily: GoogleFonts.inter().fontFamily,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ), // Fim da Column principal
          ],
        ),
      ),
    );
  }
}
