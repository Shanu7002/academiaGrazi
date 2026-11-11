import 'package:academiagrazi/models/users/registration_profile.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Ficha de cadastro do aluno vista pelo admin: usada nos detalhes do
// professor e na aba Alunos. Contém dados de saúde (LGPD): só para o admin.

/// Data no formato dd/mm/aaaa.
String formatDateBr(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year}';
}

/// Telefone com DDD formatado; outros formatos voltam como vieram.
String formatPhoneBr(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-'
        '${digits.substring(7)}';
  }
  if (digits.length == 10) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-'
        '${digits.substring(6)}';
  }
  return phone;
}

/// Objetivo principal do aluno em pt-BR.
String goalLabel(PrimaryGoal goal) {
  switch (goal) {
    case PrimaryGoal.weightLoss:
      return 'Emagrecimento & Definição';
    case PrimaryGoal.muscleGain:
      return 'Ganho de Massa Muscular';
    case PrimaryGoal.conditioning:
      return 'Condicionamento & Saúde';
    case PrimaryGoal.strengthening:
      return 'Fortalecimento & Postura';
    case PrimaryGoal.mobility:
      return 'Mobilidade & Flexibilidade';
  }
}

const _noneOptions = {'Nenhuma dor', 'Não possuo'};

/// Condições e restrições relevantes, sem as opções de "nenhuma".
List<String> healthAlerts(RegistrationProfile? profile) {
  if (profile == null) return const [];
  return [
    ...profile.health.conditions,
    ...profile.health.restrictions,
  ].where((item) => !_noneOptions.contains(item)).toList();
}

/// Rótulo em caixa alta das fichas do admin.
TextStyle get adminLabelStyle => GoogleFonts.inter(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  letterSpacing: .5,
  color: AppColors.slateText,
);

class AdminInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const AdminInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: adminLabelStyle),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Objetivo, medidas, data de entrada, saúde e contato de emergência.
class StudentRegistrationDetails extends StatelessWidget {
  final UserModel user;
  final DateTime? joinedAt;

  const StudentRegistrationDetails({
    super.key,
    required this.user,
    this.joinedAt,
  });

  @override
  Widget build(BuildContext context) {
    final profile = user.registrationProfile;
    final alerts = healthAlerts(profile);
    final notes = profile?.health.notes.trim() ?? '';
    final emergency = profile?.emergencyContact;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (profile == null)
          Text(
            'Este aluno ainda não completou a ficha de cadastro.',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.slateText),
          )
        else ...[
          AdminInfoRow(
            icon: Icons.flag_outlined,
            label: 'Objetivo',
            value: goalLabel(profile.primaryGoal),
          ),
          const SizedBox(height: 14),
          AdminInfoRow(
            icon: Icons.straighten,
            label: 'Medidas',
            value:
                '${profile.measurements.age} anos • '
                '${profile.measurements.heightCm} cm • '
                '${profile.measurements.weightKg.toStringAsFixed(1)} kg',
          ),
          if (joinedAt != null) ...[
            const SizedBox(height: 14),
            AdminInfoRow(
              icon: Icons.event_outlined,
              label: 'Aluno desde',
              value: formatDateBr(joinedAt!),
            ),
          ],
          const SizedBox(height: 20),
          Text('SAÚDE', style: adminLabelStyle),
          const SizedBox(height: 8),
          if (alerts.isEmpty)
            Text(
              'Sem condições ou restrições informadas.',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textBody),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final alert in alerts)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentAlertSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accentAlertBorder),
                    ),
                    child: Text(
                      alert,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentText,
                      ),
                    ),
                  ),
              ],
            ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              notes,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.4,
                color: AppColors.textBody,
              ),
            ),
          ],
          if (emergency != null && emergency.name.trim().isNotEmpty) ...[
            const SizedBox(height: 20),
            AdminInfoRow(
              icon: Icons.contact_phone_outlined,
              label: 'Contato de emergência',
              value: [
                emergency.name,
                if (emergency.relationship.isNotEmpty) emergency.relationship,
                if (emergency.phone.isNotEmpty) formatPhoneBr(emergency.phone),
              ].join(' • '),
            ),
          ],
        ],
      ],
    );
  }
}
