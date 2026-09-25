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
        automaticallyImplyLeading: false,
        title: const Text(
          'GRAZI BRAZ',
          style: TextStyle(color: Color(0xFF005A4F), fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {}, // Notificações ainda não estão ligadas ao banco
            icon: const Icon(Icons.notifications_none, color: Color(0xFF354640)),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const _ProfileSummary(),

              const SizedBox(height: 16),

              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      icon: Icons.badge_outlined,
                      title: 'ACOMPANHAMENTO PROFISSIONAL',
                      fontSize: 15,
                    ),
                    SizedBox(height: 16),
                    _ProfessionalInfoCard(
                      avatar: CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFD4D4D4),
                        child: Icon(Icons.person, color: Color(0xFF8A8A8A)),
                      ),
                      label: 'PROFESSOR RESPONSÁVEL',
                      title:
                          'Prof. Marcos', //Dado mockado, precisa ser alterado em produção para buscar o dado do banco
                      subtitle:
                          'Especialista', //Dado mockado, precisa ser alterado em produção para buscar o dado do banco
                      subtitleColor: Color(0xFF277B60),
                    ),
                    SizedBox(height: 12),
                    _ProfessionalInfoCard(
                      avatar: CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFF005A4F),
                        child: Text(
                          'A', // Valor derivado do bloco mockado, deve vir do banco
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      label: 'BLOCO / TURNO',
                      title:
                          'Bloco A', //Dado mockado, precisa ser alterado em produção para buscar o dado do banco
                      subtitle:
                          '06:00 - 09:00', //Dado mockado, precisa ser alterado em produção para buscar o dado do banco
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeader(
                      icon: Icons.health_and_safety_outlined,
                      title: 'SAÚDE E FICHA CLÍNICA',
                    ),
                    SizedBox(height: 12),
                    _PrivacyBanner(),
                    SizedBox(height: 12),
                    _InfoCard(
                      label: 'Condições Crônicas',
                      value:
                          'Hipertensão controlada', //Dado mockado, precisa ser alterado em produção para buscar o dado do banco
                    ),
                    SizedBox(height: 10),
                    _InfoCard(
                      label: 'Restrições no Treino',
                      value:
                          'Evitar impacto excessivo em membros inferiores', //Dado mockado, precisa ser alterado em produção para buscar o dado do banco
                    ),
                    SizedBox(height: 10),
                    _InfoCard(
                      label: 'Contato de Emergência',
                      value:
                          'Carlos Lima (Esposo) • (11) 98765-4321', //Dado mockado, precisa ser alterado em produção para buscar o dado do banco
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Revisado em 15/06/2023 por Prof. Marcos', //Dado mockado, precisa ser alterado em produção para buscar o dado do banco
                      style: TextStyle(color: Color(0xFF65716D), fontSize: 10),
                    ),
                    SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {}, // Atualização da ficha no banco ainda não implementada
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

              const _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(icon: Icons.credit_card, title: 'PLANO E MENSALIDADE'),
                    SizedBox(height: 16),
                    Text(
                      'Plano Conexão Semestral', //Dado mockado, precisa ser alterado em produção para buscar o dado do banco
                      style: TextStyle(
                        color: Color(0xFF092837),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Renovação em 10/11/2023', //Dado mockado, precisa ser alterado em produção para buscar o dado do banco
                      style: TextStyle(color: Color(0xFF65716D), fontSize: 11),
                    ),
                    SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Modalidades\nMusculação + Pilates', //Dado mockado, precisa ser alterado em produção para buscar o dado do banco
                            style: TextStyle(color: Color(0xFF092837), fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Matrícula\n#GB-2023-0482', //Dado mockado, precisa ser alterado em produção para buscar o dado do banco
                            style: TextStyle(color: Color(0xFF092837), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _SectionCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: _SectionHeader(icon: Icons.tune, title: 'PREFERÊNCIAS & AJUSTES'),
                    ),
                    const Divider(height: 1),
                    const _PreferenceSwitch(icon: Icons.alarm, title: 'Lembrete diário de treino'),
                    const Divider(height: 1),
                    const _PreferenceSwitch(
                      icon: Icons.notifications_active_outlined,
                      title:
                          'Avisos do Prof. Marcos', // Dado mockado, deve vir do professor vinculado no banco
                    ),
                    const Divider(height: 1),
                    const Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: Icon(Icons.shield_outlined),
                        title: Text('Privacidade & Termos'),
                        trailing: Icon(Icons.chevron_right),
                      ),
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

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      child: Row(
        children: [
          Stack(
            children: [
              _ProfileAvatar(), // Imagem de perfil mockada, deve vir do banco/storage
              Positioned(
                right: 0,
                bottom: 0,
                child: _VerifiedBadge(), // Status do perfil mockado, deve vir do banco
              ),
            ],
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ana Lima', //Dado mockado, precisa ser alterado em produção para buscar o dado do banco
                  style: TextStyle(
                    color: Color(0xFF092837),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'ana.lima@exemplo.com', //Dado mockado, precisa ser alterado em produção para buscar o dado do banco
                  style: TextStyle(color: Color(0xFF65716D), fontSize: 12),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.fitness_center, color: Color(0xFF005A4F), size: 16),
                    SizedBox(width: 5),
                    Text(
                      'Plano Presencial + App', //Dado mockado, precisa ser alterado em produção para buscar o dado do banco
                      style: TextStyle(color: Color(0xFF005A4F), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFD6D6D6),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2CA99F), width: 2),
      ),
      child: const Icon(Icons.person, size: 34, color: Color(0xFF8A8A8A)),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: const Color(0xFF16794E),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.check, color: Colors.white, size: 14),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EEEC)),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title, this.fontSize = 16});

  final IconData icon;
  final String title;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF005A4F)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: const Color(0xFF005A4F),
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfessionalInfoCard extends StatelessWidget {
  const _ProfessionalInfoCard({
    required this.avatar,
    required this.label,
    required this.title,
    required this.subtitle,
    this.subtitleColor = const Color(0xFF65716D),
  });

  final Widget avatar;
  final String label;
  final String title;
  final String subtitle;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FAFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF65716D), fontSize: 10)),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(color: Color(0xFF092837), fontWeight: FontWeight.bold),
              ),
              Text(subtitle, style: TextStyle(color: subtitleColor, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrivacyBanner extends StatelessWidget {
  const _PrivacyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF65716D), fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Color(0xFF092837), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        value: true, // Preferência mockada, deve ser lida do banco
        onChanged: (value) {}, // Persistência da preferência no banco ainda não implementada
        activeThumbColor: const Color(0xFF005A4F),
        secondary: Icon(icon),
        title: Text(title),
      ),
    );
  }
}
