import 'dart:convert';
import 'dart:typed_data';

import 'package:academiagrazi/view/teacher/services/seletor_imagem_exercicio.dart';
import 'package:academiagrazi/view/teacher/ui_models/montagem_treino_ui_models.dart';
import 'package:academiagrazi/view/teacher/widgets/cadastrar_exercicio_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _SeletorImagemFake implements SeletorImagemExercicio {
  @override
  Future<Uint8List?> selecionarDaGaleria() async {
    return base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91Jpz'
      'AAAAFklEQVR4nGNkSPFnYGBgYmBgYGBgAAAIPwC3KfeDEQAA'
      'AABJRU5ErkJggg==',
    );
  }
}

void main() {
  testWidgets('valida campos e imagem e cadastra exercício', (tester) async {
    ExercicioCatalogoProfessorUi? cadastro;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder:
                (context) => TextButton(
                  onPressed: () async {
                    cadastro = await showDialog<ExercicioCatalogoProfessorUi>(
                      context: context,
                      builder:
                          (_) => CadastrarExercicioDialog(
                            exercicioId: 'manual-1',
                            seletorImagem: _SeletorImagemFake(),
                          ),
                    );
                  },
                  child: const Text('Cadastrar'),
                ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    // Valida os campos vazios e a ausência de imagem.
    await tester.tap(find.byKey(const Key('confirmar_exercicio_manual')));
    await tester.pumpAndSettle();

    expect(find.text('Informe o nome.'), findsOneWidget);
    expect(find.text('Selecione uma imagem da galeria.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('nome_exercicio_manual')),
      'Elevação lateral',
    );
    await tester.enterText(
      find.byKey(const Key('grupo_exercicio_manual')),
      'Ombros',
    );

    await tester.tap(find.byKey(const Key('selecionar_imagem_manual')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('preview_imagem_manual')), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirmar_exercicio_manual')));
    await tester.pumpAndSettle();

    expect(cadastro?.nome, 'Elevação lateral');
    expect(cadastro?.grupoMuscular, 'Ombros');
    expect(cadastro?.imagemBytes, isNotNull);
  });
}
