import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

class AlunoEvolutionView extends StatefulWidget {
  const AlunoEvolutionView({super.key});

  @override
  State<AlunoEvolutionView> createState() => _AlunoEvolutionViewState();
}

class _AlunoEvolutionViewState extends State<AlunoEvolutionView> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFD6D6D6),
              child: Icon(Icons.person, color: Color(0xFF8A8A8A)),
            ),
            const SizedBox(width: 12),
            Text(
              'Grazi Braz',
              style: GoogleFonts.barlowCondensed(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 0, 65, 100),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.black87,
                size: 24,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
              
            ]
          ),
        ),
      ),
    );
  }
}
