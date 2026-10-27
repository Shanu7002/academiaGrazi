import 'dart:typed_data';

import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/teacher/services/seletor_imagem_exercicio.dart';
import 'package:academiagrazi/view/teacher/ui_models/montagem_treino_ui_models.dart';
import 'package:flutter/material.dart';

/// Formulário temporário de cadastro de exercício com imagem da galeria.
class CadastrarExercicioDialog extends StatefulWidget {
  final String exercicioId;
  final SeletorImagemExercicio seletorImagem;

  const CadastrarExercicioDialog({
    super.key,
    required this.exercicioId,
    required this.seletorImagem,
  });

  @override
  State<CadastrarExercicioDialog> createState() =>
      _CadastrarExercicioDialogState();
}

class _CadastrarExercicioDialogState extends State<CadastrarExercicioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _grupo = TextEditingController();
  final _orientacoes = TextEditingController();

  Uint8List? _imagem;
  String? _erroImagem;
  bool _selecionando = false;

  @override
  void dispose() {
    _nome.dispose();
    _grupo.dispose();
    _orientacoes.dispose();
    super.dispose();
  }

  Future<void> _selecionarImagem() async {
    setState(() {
      _selecionando = true;
      _erroImagem = null;
    });

    try {
      final bytes = await widget.seletorImagem.selecionarDaGaleria();
      if (!mounted) return;
      if (bytes != null) {
        setState(() => _imagem = bytes);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erroImagem = 'Não foi possível usar essa imagem.';
      });
    } finally {
      if (mounted) {
        setState(() => _selecionando = false);
      }
    }
  }

  void _confirmar() {
    final camposValidos = _formKey.currentState!.validate();

    if (_imagem == null) {
      setState(() {
        _erroImagem = 'Selecione uma imagem da galeria.';
      });
    }

    if (!camposValidos || _imagem == null) return;

    Navigator.of(context).pop(
      ExercicioCatalogoProfessorUi(
        id: widget.exercicioId,
        nome: _nome.text.trim(),
        grupoMuscular: _grupo.text.trim(),
        orientacoes: _orientacoes.text.trim(),
        imagemBytes: _imagem,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cadastrar exercício'),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('nome_exercicio_manual'),
                  controller: _nome,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome do exercício',
                  ),
                  validator:
                      (v) =>
                          (v?.trim().isEmpty ?? true)
                              ? 'Informe o nome.'
                              : null,
                ),
                TextFormField(
                  key: const Key('grupo_exercicio_manual'),
                  controller: _grupo,
                  decoration: const InputDecoration(
                    labelText: 'Grupo muscular',
                  ),
                  validator:
                      (v) =>
                          (v?.trim().isEmpty ?? true)
                              ? 'Informe o grupo muscular.'
                              : null,
                ),
                TextFormField(
                  key: const Key('orientacoes_exercicio_manual'),
                  controller: _orientacoes,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Orientações (opcional)',
                  ),
                ),
                const SizedBox(height: 16),
                if (_imagem != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      _imagem!,
                      key: const Key('preview_imagem_manual'),
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 64,
                    color: AppColors.primary,
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const Key('selecionar_imagem_manual'),
                  onPressed: _selecionando ? null : _selecionarImagem,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(
                    _selecionando ? 'Abrindo galeria...' : 'Escolher imagem',
                  ),
                ),
                if (_erroImagem != null)
                  Text(
                    _erroImagem!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 6),
                const Text(
                  'A imagem ficará apenas nesta sessão. '
                  'Ainda não é salva no Firebase.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('confirmar_exercicio_manual'),
          onPressed: _selecionando ? null : _confirmar,
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}
