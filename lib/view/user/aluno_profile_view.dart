import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:academiagrazi/controller/users/update_data.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/users/register_user.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
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
  final UpdateDataController _updateDataController =
      locator<UpdateDataController>();
  UserModel? _currentUser;
  UserModel? _currentResponsable;
  bool _isLoading = true;

  bool _editingHealth = false;
  bool _savingHealth = false;
  List<String> _selectedConditions = [];
  List<String> _selectedRestrictions = [];
  final TextEditingController _healthNotesController = TextEditingController();

  bool _editingEmergency = false;
  bool _savingEmergency = false;
  final TextEditingController _emergencyNameController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();

  final MaskTextInputFormatter _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );
  String? _selectedRelationship;

  final List<String> conditionOptions = [
    'Nenhuma dor',
    'Coluna/Lombar',
    'Joelho',
    'Ombro',
    'Hipertensão',
    'Outra',
  ];

  final List<String> restrictionOptions = [
    'Não possuo',
    'Asma/Bronquite',
    'Látex/Elásticos',
    'Outras',
  ];

  final Set<String> relationshipOptions = {
    'Cônjuge / Parceiro(a)',
    'Pai / Mãe',
    'Irmão / Irmã',
    'Filho(a)',
    'Amigo(a) Próximo(a)',
    'Outro',
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _healthNotesController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFF),

      appBar: CustomAppBar(
        title: 'GRAZI BRAZ',
        backgroundColor: Colors.deepPurple,
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
                child: StatefulBuilder(
                  builder: (context, refreshHealthCard) {
                    final health = user.registrationProfile?.health;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader(
                          icon: Icons.health_and_safety_outlined,
                          title: 'SAÚDE E FICHA CLÍNICA',
                        ),
                        const SizedBox(height: 12),
                        const _PrivacyBanner(),
                        const SizedBox(height: 12),
                        if (_editingHealth) ...[
                          const Text(
                            'Condições crônicas',
                            style: TextStyle(
                              color: Color(0xFF092837),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children:
                                conditionOptions.map((option) {
                                  final isSelected = _selectedConditions
                                      .contains(option);
                                  return FilterChip(
                                    label: Text(option),
                                    selected: isSelected,
                                    selectedColor: const Color(0xFFD5F3ED),
                                    checkmarkColor: const Color(0xFF005A4F),
                                    backgroundColor: const Color(0xFFF5FAFF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color:
                                            isSelected
                                                ? const Color(0xFF005A4F)
                                                : const Color(0xFFE9EEEC),
                                      ),
                                    ),
                                    onSelected: (selected) {
                                      refreshHealthCard(() {
                                        if (option == 'Nenhuma dor') {
                                          _selectedConditions.clear();
                                          if (selected) {
                                            _selectedConditions.add(option);
                                          }
                                        } else {
                                          _selectedConditions.remove(
                                            'Nenhuma dor',
                                          );
                                          if (selected) {
                                            _selectedConditions.add(option);
                                          } else {
                                            _selectedConditions.remove(option);
                                          }
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Restrições no treino',
                            style: TextStyle(
                              color: Color(0xFF092837),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children:
                                restrictionOptions.map((option) {
                                  final isSelected = _selectedRestrictions
                                      .contains(option);
                                  return FilterChip(
                                    label: Text(option),
                                    selected: isSelected,
                                    selectedColor: const Color(0xFFD5F3ED),
                                    checkmarkColor: const Color(0xFF005A4F),
                                    backgroundColor: const Color(0xFFF5FAFF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color:
                                            isSelected
                                                ? const Color(0xFF005A4F)
                                                : const Color(0xFFE9EEEC),
                                      ),
                                    ),
                                    onSelected: (selected) {
                                      refreshHealthCard(() {
                                        if (option == 'Não possuo') {
                                          _selectedRestrictions.clear();
                                          if (selected) {
                                            _selectedRestrictions.add(option);
                                          }
                                        } else {
                                          _selectedRestrictions.remove(
                                            'Não possuo',
                                          );
                                          if (selected) {
                                            _selectedRestrictions.add(option);
                                          } else {
                                            _selectedRestrictions.remove(
                                              option,
                                            );
                                          }
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _healthNotesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Observações adicionais (opcional)',
                              hintText: 'Detalhe dores, cirurgias, etc.',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ] else ...[
                          _InfoCardList(
                            label: 'Condições Crônicas',
                            value: health?.conditions,
                          ),
                          const SizedBox(height: 10),
                          _InfoCardList(
                            label: 'Restrições no Treino',
                            value: health?.restrictions,
                          ),
                          const SizedBox(height: 10),
                          _InfoCardString(
                            label: 'Observações',
                            value: health?.notes,
                          ),
                        ],
                        const SizedBox(height: 14),
                        if (_editingHealth) ...[
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed:
                                  _savingHealth
                                      ? null
                                      : () {
                                        refreshHealthCard(() {
                                          _editingHealth = false;
                                        });
                                      },
                              child: const Text('CANCELAR'),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed:
                                _savingHealth
                                    ? null
                                    : () async {
                                      if (!_editingHealth) {
                                        final List<String> safeConditions = [];
                                        if (health?.conditions != null) {
                                          for (var item in health!.conditions) {
                                            safeConditions.add(item.toString());
                                          }
                                        }
                                        if (safeConditions.isEmpty) {
                                          safeConditions.add('Nenhuma dor');
                                        }

                                        final List<String> safeRestrictions =
                                            [];
                                        if (health?.restrictions != null) {
                                          for (var item
                                              in health!.restrictions) {
                                            safeRestrictions.add(
                                              item.toString(),
                                            );
                                          }
                                        }
                                        if (safeRestrictions.isEmpty) {
                                          safeRestrictions.add('Não possuo');
                                        }

                                        _selectedConditions = safeConditions;
                                        _selectedRestrictions =
                                            safeRestrictions;
                                        _healthNotesController.text =
                                            health?.notes ?? '';

                                        refreshHealthCard(() {
                                          _editingHealth = true;
                                        });
                                        return;
                                      }

                                      refreshHealthCard(() {
                                        _savingHealth = true;
                                      });

                                      try {
                                        final newNotes =
                                            _healthNotesController.text.trim();

                                        await _updateDataController
                                            .updateHealthProfile(
                                              userId: user.id,
                                              conditions: _selectedConditions,
                                              restrictions:
                                                  _selectedRestrictions,
                                              notes: newNotes,
                                            );

                                        if (health != null) {
                                          health.conditions.clear();
                                          health.conditions.addAll(
                                            _selectedConditions,
                                          );

                                          health.restrictions.clear();
                                          health.restrictions.addAll(
                                            _selectedRestrictions,
                                          );

                                          health.notes = newNotes;
                                        }

                                        refreshHealthCard(() {
                                          _editingHealth = false;
                                        });

                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Ficha de saúde salva com sucesso!',
                                              ),
                                              backgroundColor: Color(
                                                0xFF16794E,
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Falha ao salvar. Tente novamente.',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      } finally {
                                        refreshHealthCard(() {
                                          _savingHealth = false;
                                        });
                                      }
                                    },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF005A4F),
                              side: const BorderSide(color: Color(0xFF005A4F)),
                            ),
                            child:
                                _savingHealth
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF005A4F),
                                      ),
                                    )
                                    : Text(
                                      _editingHealth
                                          ? 'SALVAR ALTERAÇÕES'
                                          : 'ATUALIZAR FICHA DE SAÚDE',
                                    ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              _SectionCard(
                child: StatefulBuilder(
                  builder: (context, refreshEmergencyCard) {
                    final emergency = profile?.emergencyContact;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader(
                          icon: Icons.contact_phone_outlined,
                          title: 'CONTATO DE EMERGÊNCIA',
                        ),
                        const SizedBox(height: 16),

                        if (_editingEmergency) ...[
                          TextField(
                            controller: _emergencyNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nome do contato',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _emergencyPhoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [_phoneMaskFormatter],
                            decoration: const InputDecoration(
                              labelText: 'Telefone',
                              hintText: '(11) 99999-9999',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedRelationship,
                            decoration: const InputDecoration(
                              labelText: 'Grau de Parentesco',
                              border: OutlineInputBorder(),
                            ),
                            items:
                                relationshipOptions.map((entry) {
                                  return DropdownMenuItem<String>(
                                    value: entry,
                                    child: Text(entry),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              refreshEmergencyCard(() {
                                _selectedRelationship = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed:
                                  _savingEmergency
                                      ? null
                                      : () {
                                        refreshEmergencyCard(() {
                                          _editingEmergency = false;
                                        });
                                      },
                              child: const Text('CANCELAR'),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ] else ...[
                          _InfoCardList(
                            label: 'Contato Salvo',
                            value:
                                emergency != null
                                    ? [
                                      emergency.name,
                                      formatPhone(emergency.phone),
                                      relationshipOptions ??
                                          emergency.relationship,
                                    ]
                                    : ['Não informado'],
                          ),
                          const SizedBox(height: 14),
                        ],

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed:
                                _savingEmergency
                                    ? null
                                    : () async {
                                      if (!_editingEmergency) {
                                        _emergencyNameController.text =
                                            emergency?.name ?? '';
                                        _emergencyPhoneController
                                            .text = _phoneMaskFormatter
                                            .maskText(emergency?.phone ?? '');

                                        if (emergency?.relationship != null &&
                                            relationshipOptions.contains(
                                              emergency!.relationship,
                                            )) {
                                          _selectedRelationship =
                                              emergency.relationship;
                                        } else {
                                          _selectedRelationship = 'other';
                                        }

                                        refreshEmergencyCard(() {
                                          _editingEmergency = true;
                                        });
                                        return;
                                      }

                                      refreshEmergencyCard(() {
                                        _savingEmergency = true;
                                      });

                                      try {
                                        final newName =
                                            _emergencyNameController.text
                                                .trim();
                                        final newPhone =
                                            _emergencyPhoneController.text
                                                .trim()
                                                .replaceAll(RegExp(r'\D'), '');
                                        final newRelationship =
                                            _selectedRelationship ?? 'other';

                                        await _updateDataController
                                            .updateEmergencyContact(
                                              userId: user.id,
                                              name: newName,
                                              phone: newPhone,
                                              relationship: newRelationship,
                                            );

                                        if (emergency != null) {
                                          emergency.name = newName;
                                          emergency.phone = newPhone;
                                          emergency.relationship =
                                              newRelationship;
                                        }

                                        refreshEmergencyCard(() {
                                          _editingEmergency = false;
                                        });

                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Contato salvo com sucesso!',
                                              ),
                                              backgroundColor: Color(
                                                0xFF16794E,
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Falha ao salvar contato. Tente novamente.',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      } finally {
                                        refreshEmergencyCard(() {
                                          _savingEmergency = false;
                                        });
                                      }
                                    },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF005A4F),
                              side: const BorderSide(color: Color(0xFF005A4F)),
                            ),
                            child:
                                _savingEmergency
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF005A4F),
                                      ),
                                    )
                                    : Text(
                                      _editingEmergency
                                          ? 'SALVAR CONTATO'
                                          : 'ATUALIZAR CONTATO',
                                    ),
                          ),
                        ),
                      ],
                    );
                  },
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
  final List<dynamic>? value;

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
