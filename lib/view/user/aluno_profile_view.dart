import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/users/registration_profile.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/users/register_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AlunoProfileView extends StatefulWidget {
  const AlunoProfileView({super.key});

  @override
  State<AlunoProfileView> createState() => _AlunoProfileViewState();
}

class _AlunoProfileViewState extends State<AlunoProfileView> {
  final FirebaseAuth _authInstance = locator<FirebaseAuth>();
  final RegisterUserService _userService = locator<RegisterUserService>();
  UserModel? _currentUser;
  UserModel? _currentResponsable;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final firebaseUser = _authInstance.currentUser;

      if (firebaseUser == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      final user = await _userService.getUserById(firebaseUser.uid);
      UserModel? responsable;

      if (user?.responsable != null && user!.responsable!.isNotEmpty) {
        responsable = await _userService.getResponsableData(user.responsable!);
      }

      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _currentResponsable = responsable;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não encontrado.')),
      );
    }

    final user = _currentUser!;
    final responsable = _currentResponsable;

    String formatPhone(String phone) {
      final digits = phone.replaceAll(RegExp(r'\D'), '');

      if (digits.length == 11) {
        return '(${digits.substring(0, 2)}) '
            '${digits.substring(2, 7)}-${digits.substring(7)}';
      }

      if (digits.length == 10) {
        return '(${digits.substring(0, 2)}) '
            '${digits.substring(2, 6)}-${digits.substring(6)}';
      }

      return phone;
    }

    final profile = user.registrationProfile;

    final List<String> emergencyContact =
        profile == null
            ? []
            : [
              profile.emergencyContact.name,
              formatPhone(profile.emergencyContact.phone),
              profile.emergencyContact.relationship,
            ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFF),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'GRAZI BRAZ',
          style: TextStyle(
            color: Color(0xFF005A4F),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none,
              color: Color(0xFF354640),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _ProfileSummary(user: user),

              const SizedBox(height: 16),

              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeader(
                      icon: Icons.badge_outlined,
                      title: 'ACOMPANHAMENTO PROFISSIONAL',
                      fontSize: 15,
                    ),
                    const SizedBox(height: 16),
                    _ProfessionalInfoCard(
                      avatar: const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFD4D4D4),
                        child: Icon(Icons.person, color: Color(0xFF8A8A8A)),
                      ),
                      label: 'PROFESSOR RESPONSÁVEL',
                      title: responsable?.name ?? 'Professor não encontrado',
                      subtitle: 'Especialista',
                      subtitleColor: const Color(0xFF277B60),
                    ),
                    const SizedBox(height: 12),
                    _ProfessionalInfoCard(
                      avatar: const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFF005A4F),
                        child: Text(
                          'A',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      label: 'BLOCO / TURNO',
                      title: 'Bloco A',
                      subtitle: '06:00 - 09:00',
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
                    const SizedBox(height: 12),
                    const _PrivacyBanner(),
                    const SizedBox(height: 12),
                    _InfoCardList(
                      label: 'Condições Crônicas',
                      value: user.registrationProfile?.health.conditions,
                    ),
                    const SizedBox(height: 10),
                    _InfoCardList(
                      label: 'Restrições no Treino',
                      value: user.registrationProfile?.health.restrictions,
                    ),
                    const SizedBox(height: 10),
                    _InfoCardString(
                      label: 'Restrições no Treino',
                      value: user.registrationProfile?.health.notes,
                    ),
                    const SizedBox(height: 10),
                    _InfoCardList(
                      label: 'Contato de Emergência',
                      value: emergencyContact,
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

              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeader(
                      icon: Icons.credit_card,
                      title: 'PLANO E MENSALIDADE',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Plano Conexão Semestral',
                      style: TextStyle(
                        color: Color(0xFF092837),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Renovação em 10/11/2023',
                      style: TextStyle(color: Color(0xFF65716D), fontSize: 11),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: const [
                        Expanded(
                          child: Text(
                            'Modalidades\nMusculação + Pilates',
                            style: TextStyle(
                              color: Color(0xFF092837),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Matrícula\n#GB-2023-0482',
                            style: TextStyle(
                              color: Color(0xFF092837),
                              fontSize: 12,
                            ),
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
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: _SectionHeader(
                        icon: Icons.tune,
                        title: 'PREFERÊNCIAS & AJUSTES',
                      ),
                    ),
                    Divider(height: 1),
                    _PreferenceSwitch(
                      icon: Icons.alarm,
                      title: 'Lembrete diário de treino',
                    ),
                    Divider(height: 1),
                    _PreferenceSwitch(
                      icon: Icons.notifications_active_outlined,
                      title: 'Avisos do Prof. Marcos',
                    ),
                    Divider(height: 1),
                    Material(
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
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Row(
        children: [
          Stack(
            children: const [
              _ProfileAvatar(),
              Positioned(right: 0, bottom: 0, child: _VerifiedBadge()),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF092837),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF65716D),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(
                      Icons.fitness_center,
                      color: Color(0xFF005A4F),
                      size: 16,
                    ),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Plano Presencial + App',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF005A4F),
                          fontSize: 12,
                        ),
                      ),
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
  const _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

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
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.fontSize = 16,
  });

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF65716D),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF092837),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: subtitleColor, fontSize: 10),
                ),
              ],
            ),
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

class _InfoCardList extends StatelessWidget {
  const _InfoCardList({required this.label, required this.value});

  final String label;
  final List<String>? value;

  @override
  Widget build(BuildContext context) {
    final String displayValue =
        value == null || value!.isEmpty ? 'Não informado' : value!.join('\n');

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
          Text(
            label,
            style: const TextStyle(color: Color(0xFF65716D), fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            displayValue,
            style: const TextStyle(
              color: Color(0xFF092837),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCardString extends StatelessWidget {
  const _InfoCardString({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final String displayValue =
        value == null || value!.isEmpty ? 'Não informado' : value!;

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
          Text(
            label,
            style: const TextStyle(color: Color(0xFF65716D), fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            displayValue,
            style: const TextStyle(
              color: Color(0xFF092837),
              fontWeight: FontWeight.bold,
            ),
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
        value: true,
        onChanged: (value) {},
        activeThumbColor: const Color(0xFF005A4F),
        secondary: Icon(icon),
        title: Text(title),
      ),
    );
  }
}
