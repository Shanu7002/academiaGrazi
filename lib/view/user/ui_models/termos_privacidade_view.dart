import 'package:academiagrazi/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyTermsView extends StatelessWidget {
  const PrivacyTermsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'PRIVACIDADE & TERMOS',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: AppColors.primary,
                    size: 30,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sua privacidade importa!',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Conheça como seus dados pessoais e informações de saúde são utilizados e protegidos pela academia.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'POLÍTICA DE PRIVACIDADE',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 10),

            _PrivacySection(
              icon: Icons.person_outline,
              title: '1. Coleta de dados pessoais',
              content: '''
A academia coleta informações necessárias para o cadastro, identificação e atendimento dos alunos.

Esses dados podem incluir:

• Nome completo e data de nascimento;
• CPF e informações de contato;
• Endereço e dados cadastrais;
• Informações sobre matrícula e plano contratado;
• Registros relacionados à utilização dos serviços.

As informações são utilizadas para administrar sua matrícula, oferecer atendimento e organizar as atividades da academia.
''',
            ),

            _PrivacySection(
              icon: Icons.favorite_border,
              title: '2. Informações de saúde',
              content: '''
Algumas informações de saúde podem ser solicitadas para auxiliar a equipe da academia a identificar possíveis cuidados e limitações durante as atividades físicas.

Entre elas:

• Doenças e condições de saúde informadas;
• Alergias;
• Lesões e limitações físicas;
• Restrições para a prática de exercícios;
• Informações relevantes para situações de emergência.

Essas informações possuem caráter sensível e devem ser tratadas com cuidado especial.

Seu acesso deve ser restrito às pessoas que realmente necessitam dessas informações para as finalidades informadas, como profissionais responsáveis pelo acompanhamento do aluno.

A academia não deve utilizar essas informações para finalidades incompatíveis com aquelas apresentadas ao aluno.
''',
            ),

            _PrivacySection(
              icon: Icons.visibility_outlined,
              title: '3. Utilização das informações',
              content: '''
Os dados coletados podem ser utilizados para:

• Gerenciar cadastros e matrículas;
• Administrar planos e mensalidades;
• Personalizar o atendimento;
• Auxiliar na identificação de cuidados durante os treinos;
• Facilitar o contato em situações de emergência;
• Enviar comunicados relacionados aos serviços contratados.

Os dados não devem ser utilizados para finalidades incompatíveis com as informadas ao titular.
''',
            ),

            _PrivacySection(
              icon: Icons.lock_outline,
              title: '4. Segurança e armazenamento',
              content: '''
A academia deve adotar medidas técnicas e administrativas para proteger as informações dos alunos contra acessos não autorizados, perda, alteração ou divulgação indevida.

O acesso aos dados deve ser limitado conforme a necessidade de cada função.

As informações serão mantidas pelo período necessário para atender às finalidades do tratamento e às obrigações legais aplicáveis.
''',
            ),

            _PrivacySection(
              icon: Icons.share_outlined,
              title: '5. Compartilhamento de dados',
              content: '''
As informações poderão ser compartilhadas quando necessário para a prestação dos serviços, utilização de sistemas de gestão ou cumprimento de obrigações legais.

Qualquer compartilhamento deverá observar as finalidades informadas, a legislação aplicável e as medidas necessárias para proteger os dados dos alunos.
''',
            ),

            const SizedBox(height: 24),

            Text(
              'TERMOS DE USO',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 10),

            _PrivacySection(
              icon: Icons.fitness_center,
              title: '6. Responsabilidades do aluno',
              content: '''
O aluno é responsável por fornecer informações verdadeiras e manter seus dados cadastrais atualizados.

Também é importante informar à academia sobre alterações em seu estado de saúde, novas lesões, alergias ou restrições que possam interferir na prática de atividades físicas.

O aluno deve respeitar as orientações dos profissionais e utilizar os equipamentos de forma adequada.
''',
            ),

            _PrivacySection(
              icon: Icons.medical_information_outlined,
              title: '7. Cuidados durante os exercícios',
              content: '''
O aluno deve comunicar aos profissionais responsáveis qualquer condição que possa exigir cuidados específicos durante os exercícios.

O preenchimento da ficha de saúde auxilia na identificação de possíveis riscos, mas não substitui avaliação, diagnóstico ou acompanhamento médico.

Em caso de dúvidas sobre sua aptidão para atividades físicas, recomenda-se procurar um profissional de saúde habilitado.
''',
            ),

            const SizedBox(height: 24),

            Text(
              'SEUS DIREITOS',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 10),

            _PrivacySection(
              icon: Icons.manage_accounts_outlined,
              title: '8. Direitos sobre seus dados',
              content: '''
De acordo com a Lei Geral de Proteção de Dados (LGPD), você pode solicitar:

• Confirmação de que seus dados são tratados;
• Acesso às suas informações;
• Correção de dados incompletos ou desatualizados;
• Informações sobre compartilhamento;
• Bloqueio ou eliminação de dados, quando aplicável;
• Revogação do consentimento, quando essa for a base legal utilizada.

Alguns dados poderão precisar ser mantidos mesmo após uma solicitação de exclusão, quando houver fundamento legal para isso.
''',
            ),

            _PrivacySection(
              icon: Icons.support_agent_outlined,
              title: '9. Dúvidas e solicitações',
              content: '''
Caso deseje consultar, corrigir ou solicitar informações sobre seus dados pessoais, entre em contato com a administração da academia.

A equipe responsável deverá orientar você sobre os procedimentos para exercer seus direitos relacionados à privacidade e proteção de dados.
''',
            ),

            const SizedBox(height: 24),

            Center(
              child: Text(
                'Última atualização: Novembro de 2026\n'
                'Proteção de dados conforme a Lei nº 13.709/2018 (LGPD).',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _PrivacySection({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          leading: Icon(icon, color: AppColors.primary, size: 22),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textSecondary,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                content.trim(),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.7,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
