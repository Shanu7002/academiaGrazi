import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Evolução',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 0, 30, 45),
                      ),
                    ),

                    SizedBox(height: 8),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                221,
                                245,
                                242,
                              ),
                              minimumSize: const Size(100, 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                            ),
                            child: const Text('3 Meses'),
                          ),

                          const SizedBox(width: 10),

                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                221,
                                245,
                                242,
                              ),
                              minimumSize: const Size(100, 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                            ),
                            child: const Text('6 Meses'),
                          ),

                          const SizedBox(width: 15),

                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                221,
                                245,
                                242,
                              ),
                              minimumSize: const Size(100, 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                            ),
                            child: const Text('1 Ano'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              Container(
                width: screenWidth,
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Peso Corporal',
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 0, 30, 45),
                          ),
                        ),

                        SizedBox(width: 30),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 136, 207, 193),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '- 1.2 Kg desde a última',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 0, 90, 79),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '71,2',
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 0, 30, 45),
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'kg',
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 0, 30, 45),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),

                          titlesData: const FlTitlesData(
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),

                          borderData: FlBorderData(show: false),

                          lineBarsData: [
                            LineChartBarData(
                              color: const Color.fromARGB(255, 2, 89, 79),
                              isCurved: true,
                              curveSmoothness: 0.5,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 6,
                                    color: Colors.white,
                                    strokeWidth: 3,
                                    strokeColor: const Color.fromARGB(
                                      255,
                                      2,
                                      89,
                                      79,
                                    ),
                                  );
                                },
                              ),
                              barWidth: 4,
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color.fromARGB(80, 2, 89, 79),
                              ),
                              spots: [
                                FlSpot(0, 72.4),
                                FlSpot(1, 75.8),
                                FlSpot(2, 71.2),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              SizedBox(
                width: screenWidth,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 231, 234, 238),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                    maxWidth: 40,
                                    maxHeight: 40,
                                  ),
                                  child: Image.asset(
                                    'assets/gordura.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Text(
                                  'Gordura',
                                  style: GoogleFonts.barlowCondensed(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(255, 0, 30, 45),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 4),

                            Text(
                              '28,4 %',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 0, 65, 100),
                              ),
                            ),

                            const SizedBox(height: 4),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 136, 207, 193),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '- 0.8 %',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color.fromARGB(255, 0, 90, 79),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 209, 236, 255),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                    maxWidth: 40,
                                    maxHeight: 40,
                                  ),
                                  child: Image.asset(
                                    'assets/massaMagra.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Text(
                                  'Massa Magra',
                                  style: GoogleFonts.barlowCondensed(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(255, 0, 30, 45),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 4),

                            Text(
                              '51,1 kg',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 0, 65, 100),
                              ),
                            ),

                            const SizedBox(height: 4),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 136, 207, 193),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '+ 0.5 kg',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color.fromARGB(255, 0, 90, 79),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 15),

              SizedBox(
                width: screenWidth,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 209, 236, 255),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                          maxWidth: 50,
                          maxHeight: 50,
                        ),
                        child: Image.asset(
                          'assets/info.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(width: 20),

                      Expanded(
                        child: Text(
                          'Avaliação presencial marcada com o Prof. Marcos.',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 0, 30, 45),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 15),

              Text(
                'Histórico de Avaliações',
                style: GoogleFonts.barlowCondensed(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 0, 30, 45),
                ),
              ),

              SizedBox(height: 15),

              Container(
                width: screenWidth,
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 221, 245, 242),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                          maxWidth: 50,
                          maxHeight: 50,
                        ),
                        child: Image.asset(
                          'assets/agenda.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '15 de Junho, 2026',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 0, 30, 45),
                          ),
                        ),
                        Text(
                          'Avaliação Presencial',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 111, 121, 118),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                          maxWidth: 50,
                          maxHeight: 50,
                        ),
                        child: Image.asset(
                          'assets/pdf.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                  ],
                ),
              ),

              SizedBox(height: 15),

              Container(
                width: screenWidth,
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 221, 245, 242),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                          maxWidth: 50,
                          maxHeight: 50,
                        ),
                        child: Image.asset(
                          'assets/agenda.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '10 de Março, 2026',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 0, 30, 45),
                          ),
                        ),
                        Text(
                          'Avaliação Online',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 111, 121, 118),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                          maxWidth: 50,
                          maxHeight: 50,
                        ),
                        child: Image.asset(
                          'assets/pdf.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
