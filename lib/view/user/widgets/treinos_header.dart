import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TreinosHeader extends StatelessWidget {
  const TreinosHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 90,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/treinos/header_treinos.png',
            fit: BoxFit.cover,
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                10,
                14,
                12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'TREINOS',
                      style: GoogleFonts.barlowCondensed(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0x33000000),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0x55FFFFFF),
                      ),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 27,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}