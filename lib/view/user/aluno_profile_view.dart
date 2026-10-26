import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/preferences_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:academiagrazi/controller/users/update_data.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/users/profile_photo.dart';
import 'package:academiagrazi/service/users/register_user.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:academiagrazi/view/components/invite_code_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  final ProfilePhotoService _profilePhotoService =
      locator<ProfilePhotoService>();
  UserModel? _currentUser;
  UserModel? _currentResponsable;
  bool _isLoading = true;
  bool _uploadingPhoto = false;

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

  Future<void> _changePhoto() async {
    final user = _currentUser;
    if (user == null || _uploadingPhoto) return;

    // Na web não há câmera via image_picker; vai direto para a galeria.
    final source =
        kIsWeb
            ? ImageSource.gallery
            : await showModalBottomSheet<ImageSource>(
              context: context,
              builder:
                  (sheetContext) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo_library_outlined),
                          title: const Text('Escolher da galeria'),
                          onTap:
                              () => Navigator.pop(
                                sheetContext,
                                ImageSource.gallery,
                              ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_camera_outlined),
                          title: const Text('Tirar foto'),
                          onTap:
                              () => Navigator.pop(
                                sheetContext,
                                ImageSource.camera,
                              ),
                        ),
                      ],
                    ),
                  ),
            );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await _profilePhotoService.upload(
        bytes: await picked.readAsBytes(),
        fileName: picked.name,
        userId: user.id,
      );
      await _updateDataController.updatePhotoUrl(
        userId: user.id,
        photoUrl: url,
      );

      if (!mounted) return;
      setState(() => _currentUser = user.copyWith(photoUrl: url));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil atualizada!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível atualizar a foto. Tente novamente.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> logout() async {
    try {
      print('Executing sign out...');
      await _authInstance.signOut();
      print('Sign out successful.');
    } catch (e) {
      print('Logout Error: $e');
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
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'GRAZI BRAZ', showBackButton: false),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Meu Perfil',
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.type == UserType.admin
                        ? 'Seus dados e preferências'
                        : 'Seus dados, saúde e preferências',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.slateText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ProfileSummary(
                    user: user,
                    isUploadingPhoto: _uploadingPhoto,
                    onChangePhoto: _changePhoto,
                  ),
                  if (user.type == UserType.instructor) ...[
                    const SizedBox(height: 20),
                    _SectionCard(
                      child: InviteCodeCard(
                        instructorId: user.id,
                        title: 'Seu código de convite',
                        description:
                            'Compartilhe com seus alunos para eles se '
                            'cadastrarem vinculados a você.',
                      ),
                    ),
                  ],
                  // O admin não tem professor, ficha clínica, contato de
                  // emergência nem plano; essas seções são só de alunos e
                  // professores.
                  if (user.type != UserType.admin) ...[
                    const SizedBox(height: 20),

                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionHeader(
                            icon: Icons.badge_outlined,
                            title: 'ACOMPANHAMENTO PROFISSIONAL',
                          ),
                          const SizedBox(height: 16),
                          _ProfessionalInfoCard(
                            avatar: const CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.avatarBackground,
                              child: Icon(
                                Icons.person,
                                color: AppColors.primary,
                              ),
                            ),
                            label: 'PROFESSOR RESPONSÁVEL',
                            title:
                                responsable?.name ?? 'Professor não encontrado',
                            subtitle: 'Especialista',
                            subtitleColor: AppColors.primaryText,
                          ),
                          const SizedBox(height: 12),
                          _ProfessionalInfoCard(
                            avatar: CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                'A',
                                style: GoogleFonts.barlowCondensed(
                                  color: Colors.white,
                                  fontSize: 20,
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
                    const SizedBox(height: 20),

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
                                Text(
                                  'Condições crônicas',
                                  style: _ProfileText.fieldTitle,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      conditionOptions.map((option) {
                                        final isSelected = _selectedConditions
                                            .contains(option);
                                        return FilterChip(
                                          label: Text(option),
                                          labelStyle: _ProfileText.chip(
                                            isSelected,
                                          ),
                                          selected: isSelected,
                                          selectedColor:
                                              AppColors.primaryChipSurface,
                                          checkmarkColor: AppColors.primary,
                                          backgroundColor:
                                              AppColors.surfaceSoft,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 6,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            side: BorderSide(
                                              color:
                                                  isSelected
                                                      ? AppColors.primary
                                                      : AppColors.border,
                                            ),
                                          ),
                                          onSelected: (selected) {
                                            refreshHealthCard(() {
                                              if (option == 'Nenhuma dor') {
                                                _selectedConditions.clear();
                                                if (selected) {
                                                  _selectedConditions.add(
                                                    option,
                                                  );
                                                }
                                              } else {
                                                _selectedConditions.remove(
                                                  'Nenhuma dor',
                                                );
                                                if (selected) {
                                                  _selectedConditions.add(
                                                    option,
                                                  );
                                                } else {
                                                  _selectedConditions.remove(
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
                                Text(
                                  'Restrições no treino',
                                  style: _ProfileText.fieldTitle,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      restrictionOptions.map((option) {
                                        final isSelected = _selectedRestrictions
                                            .contains(option);
                                        return FilterChip(
                                          label: Text(option),
                                          labelStyle: _ProfileText.chip(
                                            isSelected,
                                          ),
                                          selected: isSelected,
                                          selectedColor:
                                              AppColors.primaryChipSurface,
                                          checkmarkColor: AppColors.primary,
                                          backgroundColor:
                                              AppColors.surfaceSoft,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 6,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            side: BorderSide(
                                              color:
                                                  isSelected
                                                      ? AppColors.primary
                                                      : AppColors.border,
                                            ),
                                          ),
                                          onSelected: (selected) {
                                            refreshHealthCard(() {
                                              if (option == 'Não possuo') {
                                                _selectedRestrictions.clear();
                                                if (selected) {
                                                  _selectedRestrictions.add(
                                                    option,
                                                  );
                                                }
                                              } else {
                                                _selectedRestrictions.remove(
                                                  'Não possuo',
                                                );
                                                if (selected) {
                                                  _selectedRestrictions.add(
                                                    option,
                                                  );
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
                                  style: _ProfileText.input,
                                  decoration: _profileInputDecoration(
                                    label: 'Observações adicionais (opcional)',
                                    hint: 'Detalhe dores, cirurgias, etc.',
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
                                    style: _ProfileButtonStyles.secondary(),
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
                                              final List<String>
                                              safeConditions = [];
                                              if (health?.conditions != null) {
                                                for (var item
                                                    in health!.conditions) {
                                                  safeConditions.add(
                                                    item.toString(),
                                                  );
                                                }
                                              }
                                              if (safeConditions.isEmpty) {
                                                safeConditions.add(
                                                  'Nenhuma dor',
                                                );
                                              }

                                              final List<String>
                                              safeRestrictions = [];
                                              if (health?.restrictions !=
                                                  null) {
                                                for (var item
                                                    in health!.restrictions) {
                                                  safeRestrictions.add(
                                                    item.toString(),
                                                  );
                                                }
                                              }
                                              if (safeRestrictions.isEmpty) {
                                                safeRestrictions.add(
                                                  'Não possuo',
                                                );
                                              }

                                              _selectedConditions =
                                                  safeConditions;
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
                                                  _healthNotesController.text
                                                      .trim();

                                              await _updateDataController
                                                  .updateHealthProfile(
                                                    userId: user.id,
                                                    conditions:
                                                        _selectedConditions,
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
                                                    backgroundColor:
                                                        AppColors.success,
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
                                  style: _ProfileButtonStyles.primary(
                                    filled: _editingHealth,
                                  ),
                                  child:
                                      _savingHealth
                                          ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
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
                    const SizedBox(height: 20),

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
                                  style: _ProfileText.input,
                                  decoration: _profileInputDecoration(
                                    label: 'Nome do contato',
                                    icon: Icons.person_outline,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _emergencyPhoneController,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [_phoneMaskFormatter],
                                  style: _ProfileText.input,
                                  decoration: _profileInputDecoration(
                                    label: 'Telefone',
                                    hint: '(11) 99999-9999',
                                    icon: Icons.phone_outlined,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value:
                                      relationshipOptions.contains(
                                            _selectedRelationship,
                                          )
                                          ? _selectedRelationship
                                          : null,
                                  style: _ProfileText.input,
                                  decoration: _profileInputDecoration(
                                    label: 'Grau de Parentesco',
                                    icon: Icons.people_outline,
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
                                    style: _ProfileButtonStyles.secondary(),
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
                                              _emergencyPhoneController.text =
                                                  _phoneMaskFormatter.maskText(
                                                    emergency?.phone ?? '',
                                                  );

                                              if (emergency?.relationship !=
                                                      null &&
                                                  relationshipOptions.contains(
                                                    emergency!.relationship,
                                                  )) {
                                                _selectedRelationship =
                                                    emergency.relationship;
                                              } else {
                                                _selectedRelationship = 'Outro';
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
                                                      .replaceAll(
                                                        RegExp(r'\D'),
                                                        '',
                                                      );
                                              final newRelationship =
                                                  _selectedRelationship ??
                                                  'Outro';

                                              await _updateDataController
                                                  .updateEmergencyContact(
                                                    userId: user.id,
                                                    name: newName,
                                                    phone: newPhone,
                                                    relationship:
                                                        newRelationship,
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
                                                    backgroundColor:
                                                        AppColors.success,
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
                                  style: _ProfileButtonStyles.primary(
                                    filled: _editingEmergency,
                                  ),
                                  child:
                                      _savingEmergency
                                          ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
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
                    const SizedBox(height: 20),

                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionHeader(
                            icon: Icons.credit_card,
                            title: 'PLANO E MENSALIDADE',
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Plano Conexão Semestral',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Renovação em 10/11/2023',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Row(
                            children: [
                              Expanded(
                                child: _InfoCardString(
                                  label: 'Modalidades',
                                  value: 'Musculação + Pilates',
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _InfoCardString(
                                  label: 'Matrícula',
                                  value: '#GB-2023-0482',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  _SectionCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: _SectionHeader(
                            icon: Icons.tune,
                            title: 'PREFERÊNCIAS & AJUSTES',
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _PreferenceSwitch(
                          icon: Icons.alarm,
                          title: 'Lembrete diário de treino',
                          type: PreferenceType.dailyReminder,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _PreferenceSwitch(
                          icon: Icons.notifications_active_outlined,
                          title: 'Avisos do Prof. Marcos',
                          type: PreferenceType.professorNotices,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        Material(
                          color: Colors.transparent,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 4,
                            ),
                            leading: const Icon(
                              Icons.shield_outlined,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              'Privacidade & Termos',
                              style: _ProfileText.listTitle,
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => logout(),
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('Sair'),
                    style: _ProfileButtonStyles.danger(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({
    required this.user,
    required this.isUploadingPhoto,
    required this.onChangePhoto,
  });

  final UserModel user;
  final bool isUploadingPhoto;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Row(
        children: [
          Stack(
            children: [
              _ProfileAvatar(
                photoUrl: user.photoUrl,
                isUploading: isUploadingPhoto,
                onTap: onChangePhoto,
              ),
              const Positioned(right: 0, top: 0, child: _VerifiedBadge()),
              Positioned(
                right: 0,
                bottom: 0,
                child: _EditPhotoButton(onTap: onChangePhoto),
              ),
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
                  style: GoogleFonts.barlowCondensed(
                    color: AppColors.primaryDark,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppColors.slateText,
                    fontSize: 14,
                  ),
                ),
                if (user.type != UserType.admin) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.avatarBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.fitness_center,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Plano Presencial + App',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.photoUrl,
    required this.isUploading,
    required this.onTap,
  });

  final String? photoUrl;
  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const placeholder = Icon(Icons.person, size: 40, color: AppColors.primary);
    final url = photoUrl;

    // A borda fica num anel externo, com uma folga branca, e a foto é
    // recortada por dentro; assim a imagem nunca cobre a borda.
    return GestureDetector(
      key: const Key('profile_avatar'),
      onTap: isUploading ? null : onTap,
      child: Container(
        width: 80,
        height: 80,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.chartBar, width: 2),
        ),
        child: ClipOval(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: AppColors.avatarBackground),
              if (url == null || url.isEmpty)
                placeholder
              else
                Image.network(
                  ProfilePhotoService.thumbnailUrl(url),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  frameBuilder:
                      (_, child, frame, wasSynchronouslyLoaded) =>
                          wasSynchronouslyLoaded || frame != null
                              ? child
                              : placeholder,
                  errorBuilder: (_, __, ___) => placeholder,
                ),
              if (isUploading)
                const ColoredBox(
                  color: Colors.black38,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditPhotoButton extends StatelessWidget {
  const _EditPhotoButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('profile_edit_photo'),
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.photo_camera, color: Colors.white, size: 14),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.success,
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
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderTranslucent),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

enum PreferenceType { dailyReminder, professorNotices }

class _PreferenceSwitch extends StatefulWidget {
  const _PreferenceSwitch({
    Key? key,
    required this.icon,
    required this.title,
    required this.type,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final PreferenceType type;

  @override
  State<_PreferenceSwitch> createState() => _PreferenceSwitchState();
}

class _PreferenceSwitchState extends State<_PreferenceSwitch> {
  bool _currentValue = false;
  late final PreferencesService _prefs;

  @override
  void initState() {
    super.initState();
    _prefs = locator<PreferencesService>();

    _currentValue =
        widget.type == PreferenceType.dailyReminder
            ? _prefs.dailyReminder
            : _prefs.professorNotices;
  }

  Future<void> _handleToggle(bool value) async {
    setState(() => _currentValue = value);

    if (widget.type == PreferenceType.dailyReminder) {
      await _prefs.setDailyReminder(value);
    } else {
      await _prefs.setProfessorNotices(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        value: _currentValue,
        onChanged: _handleToggle,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        activeThumbColor: AppColors.surface,
        activeTrackColor: AppColors.primary,
        secondary: Icon(widget.icon, color: AppColors.primary),
        title: Text(widget.title, style: _ProfileText.listTitle),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.barlowCondensed(
              color: AppColors.primaryDark,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.1,
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
    this.subtitleColor = AppColors.textSecondary,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _ProfileText.label),
                const SizedBox(height: 4),
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: _ProfileText.value,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: subtitleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoSoftSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Proteção de dados: informações visíveis apenas a você e ao seu professor tutor.',
              style: GoogleFonts.inter(
                color: AppColors.textBody,
                fontSize: 13,
                height: 1.4,
              ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: _ProfileText.label),
          const SizedBox(height: 6),
          Text(displayValue, style: _ProfileText.value),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: _ProfileText.label),
          const SizedBox(height: 6),
          Text(displayValue, style: _ProfileText.value),
        ],
      ),
    );
  }
}

abstract final class _ProfileText {
  static TextStyle get label => GoogleFonts.inter(
    color: AppColors.slateText,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: .5,
  );

  static TextStyle get value => GoogleFonts.inter(
    color: AppColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle get fieldTitle => GoogleFonts.inter(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get input =>
      GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15);

  static TextStyle get listTitle => GoogleFonts.inter(
    color: AppColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  static TextStyle chip(bool selected) => GoogleFonts.inter(
    color: selected ? AppColors.primary : AppColors.textBody,
    fontSize: 14,
    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
  );
}

abstract final class _ProfileButtonStyles {
  static const Size _minimumSize = Size.fromHeight(52);

  static OutlinedBorder get _shape =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

  static TextStyle get _text => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: .3,
  );

  /// Ação principal do card. Fica preenchida enquanto o card está em edição
  /// (botão de salvar) e contornada no modo leitura.
  static ButtonStyle primary({required bool filled}) {
    return OutlinedButton.styleFrom(
      minimumSize: _minimumSize,
      shape: _shape,
      textStyle: _text,
      backgroundColor: filled ? AppColors.primary : AppColors.surface,
      foregroundColor: filled ? Colors.white : AppColors.primary,
      disabledBackgroundColor:
          filled ? AppColors.primaryBorderAlpha : AppColors.surface,
      side: const BorderSide(color: AppColors.primary, width: 1.5),
    );
  }

  static ButtonStyle secondary() {
    return OutlinedButton.styleFrom(
      minimumSize: _minimumSize,
      shape: _shape,
      textStyle: _text,
      foregroundColor: AppColors.slateText,
      side: const BorderSide(color: AppColors.border, width: 1.5),
    );
  }

  static ButtonStyle danger() {
    return OutlinedButton.styleFrom(
      minimumSize: _minimumSize,
      shape: _shape,
      textStyle: _text,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.danger,
      side: const BorderSide(color: AppColors.dangerSurface, width: 1.5),
    );
  }
}

InputDecoration _profileInputDecoration({
  required String label,
  String? hint,
  IconData? icon,
}) {
  final radius = BorderRadius.circular(12);

  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.slateText),
    hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
    prefixIcon: icon == null ? null : Icon(icon, color: AppColors.primary),
    filled: true,
    fillColor: AppColors.surfaceSoft,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );
}
