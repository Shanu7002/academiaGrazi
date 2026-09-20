import 'package:flutter/material.dart';

class AlunoProfileView extends StatelessWidget {
  const AlunoProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFF),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.maybePop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Color(0xFF005A4F)),
        ),
        title: const Text(
          'GRAZI BRAZ',
          style: TextStyle(color: Color(0xFF005A4F), fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Color(0xFF354640)),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // PERFIL
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE9EEEC)),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD6D6D6),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF2CA99F), width: 2),
                          ),
                          child: const Icon(Icons.person, size: 34, color: Color(0xFF8A8A8A)),
                        ),

                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFF16794E),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 16),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ana Lima',
                            style: TextStyle(
                              color: Color(0xFF092837),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 4),

                          Text(
                            'ana.lima@exemplo.com',
                            style: TextStyle(color: Color(0xFF65716D), fontSize: 12),
                          ),

                          SizedBox(height: 8),

                          Row(
                            children: [
                              Icon(Icons.fitness_center, color: Color(0xFF005A4F), size: 16),
                              SizedBox(width: 5),
                              Text(
                                'Plano Presencial + App',
                                style: TextStyle(color: Color(0xFF005A4F), fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ACOMPANHAMENTO PROFISSIONAL
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE9EEEC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.badge_outlined, color: Color(0xFF005A4F)),
                        SizedBox(width: 8),
                        Text(
                          'ACOMPANHAMENTO PROFISSIONAL',
                          style: TextStyle(
                            color: Color(0xFF005A4F),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5FAFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFFD4D4D4),
                            child: Icon(Icons.person, color: Color(0xFF8A8A8A)),
                          ),

                          SizedBox(width: 10),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PROFESSOR RESPONSÁVEL',
                                style: TextStyle(color: Color(0xFF65716D), fontSize: 10),
                              ),

                              SizedBox(height: 4),

                              Text(
                                'Prof. Marcos',
                                style: TextStyle(
                                  color: Color(0xFF092837),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                'Especialista',
                                style: TextStyle(color: Color(0xFF277B60), fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5FAFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFF005A4F),
                            child: Text(
                              'A',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),

                          SizedBox(width: 10),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BLOCO / TURNO',
                                style: TextStyle(color: Color(0xFF65716D), fontSize: 10),
                              ),

                              SizedBox(height: 4),

                              Text(
                                'Bloco A',
                                style: TextStyle(
                                  color: Color(0xFF092837),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                '06:00 - 09:00',
                                style: TextStyle(color: Color(0xFF65716D), fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // SAÚDE
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE9EEEC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.health_and_safety_outlined, color: Color(0xFF005A4F)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'SAÚDE E FICHA CLÍNICA',
                            style: TextStyle(
                              color: Color(0xFF005A4F),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F5FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lock_outline, color: Color(0xFF005A4F), size: 18),

                          SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              'Proteção de dados: informações visíveis apenas a você e ao seu professor tutor.',
                              style: TextStyle(color: Color(0xFF092837), fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Condições Crônicas',
                            style: TextStyle(color: Color(0xFF65716D), fontSize: 11),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Hipertensão controlada',
                            style: TextStyle(color: Color(0xFF092837), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Restrições no Treino',
                            style: TextStyle(color: Color(0xFF65716D), fontSize: 11),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Evitar impacto excessivo em membros inferiores',
                            style: TextStyle(color: Color(0xFF092837), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contato de Emergência',
                            style: TextStyle(color: Color(0xFF65716D), fontSize: 11),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Carlos Lima (Esposo) • (11) 98765-4321',
                            style: TextStyle(color: Color(0xFF092837), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Revisado em 15/06/2023 por Prof. Marcos',
                      style: TextStyle(color: Color(0xFF65716D), fontSize: 10),
                    ),

                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF005A4F),
                          side: const BorderSide(color: Color(0xFF005A4F)),
                        ),
                        child: const Text('ATUALIZAR FICHA DE SAÚDE'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // PLANO
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE9EEEC)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.credit_card, color: Color(0xFF005A4F)),
                        SizedBox(width: 8),
                        Text(
                          'PLANO E MENSALIDADE',
                          style: TextStyle(
                            color: Color(0xFF005A4F),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    Text(
                      'Plano Conexão Semestral',
                      style: TextStyle(
                        color: Color(0xFF092837),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      'Renovação em 10/11/2023',
                      style: TextStyle(color: Color(0xFF65716D), fontSize: 11),
                    ),

                    SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Modalidades\nMusculação + Pilates',
                            style: TextStyle(color: Color(0xFF092837), fontSize: 12),
                          ),
                        ),

                        Expanded(
                          child: Text(
                            'Matrícula\n#GB-2023-0482',
                            style: TextStyle(color: Color(0xFF092837), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // PREFERÊNCIAS
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE9EEEC)),
                ),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.tune, color: Color(0xFF005A4F)),
                          SizedBox(width: 8),
                          Text(
                            'PREFERÊNCIAS & AJUSTES',
                            style: TextStyle(
                              color: Color(0xFF005A4F),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    SwitchListTile(
                      value: true,
                      onChanged: (value) {},
                      activeColor: const Color(0xFF005A4F),
                      secondary: const Icon(Icons.alarm),
                      title: const Text('Lembrete diário de treino'),
                    ),

                    const Divider(height: 1),

                    SwitchListTile(
                      value: true,
                      onChanged: (value) {},
                      activeColor: const Color(0xFF005A4F),
                      secondary: const Icon(Icons.notifications_active_outlined),
                      title: const Text('Avisos do Prof. Marcos'),
                    ),

                    const Divider(height: 1),

                    const ListTile(
                      leading: Icon(Icons.shield_outlined),
                      title: Text('Privacidade & Termos'),
                      trailing: Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // bottomNavigationBar removido
    );
  }
}
