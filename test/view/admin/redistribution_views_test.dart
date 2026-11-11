import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/admin/admin_student_service.dart';
import 'package:academiagrazi/view/admin/auto_redistribution_view.dart';
import 'package:academiagrazi/view/admin/manual_redistribution_view.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;

  setUp(() async {
    await locator.reset();
    db = FakeFirebaseFirestore();
    locator.registerSingleton<AdminStudentService>(AdminStudentService(db: db));
    await db.collection('users').doc('p1').set({
      'name': 'Prof. Lucas',
      'type': 'instructor',
    });
    await db.collection('users').doc('p2').set({
      'name': 'Prof. Marina',
      'type': 'instructor',
    });
  });

  tearDown(() async => locator.reset());

  Future<void> addStudent(String id, String? responsable, int dia) {
    return db.collection('users').doc(id).set({
      'name': 'Aluno $id',
      'email': '$id@test.com',
      'type': 'user',
      if (responsable != null) 'responsable': responsable,
      'createdAt': DateTime(2026, 1, dia).toUtc().toIso8601String(),
    });
  }

  Future<String?> professorDe(String id) async =>
      (await db.collection('users').doc(id).get()).data()!['responsable']
          as String?;

  void telaGrande(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('automática', () {
    /// Abre a prévia por cima de uma tela, para capturar o resultado.
    Future<List<int?>> abrir(WidgetTester tester) async {
      telaGrande(tester);
      final resultado = <int?>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder:
                (context) => TextButton(
                  onPressed: () async {
                    resultado.add(
                      await Navigator.of(context).push<int>(
                        MaterialPageRoute(
                          builder: (_) => const AutoRedistributionView(),
                        ),
                      ),
                    );
                  },
                  child: const Text('abrir'),
                ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      return resultado;
    }

    testWidgets('mostra a prévia e aplica a redistribuição', (tester) async {
      for (var i = 1; i <= 4; i++) {
        await addStudent('a$i', 'p1', i);
      }
      final resultado = await abrir(tester);

      expect(find.text('2 aluno(s) vão mudar de professor.'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('linha_redistribuicao_p1')),
          matching: find.text('4 → 2'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('botao_aplicar_redistribuicao')));
      await tester.pumpAndSettle();

      expect(resultado, [2]);
      // Saem os mais recentes (a4 e a3).
      expect(await professorDe('a4'), 'p2');
      expect(await professorDe('a3'), 'p2');
      expect(await professorDe('a1'), 'p1');
    });

    testWidgets('equipe equilibrada não oferece aplicar', (tester) async {
      await addStudent('a1', 'p1', 1);
      await addStudent('a2', 'p2', 2);
      await abrir(tester);

      expect(find.textContaining('já está equilibrada'), findsOneWidget);
      expect(
        find.byKey(const Key('botao_aplicar_redistribuicao')),
        findsNothing,
      );
    });
  });

  group('manual', () {
    Future<void> abrir(WidgetTester tester, {String? origem}) async {
      telaGrande(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ManualRedistributionView(initialFromInstructorId: origem),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('move os alunos marcados para o destino', (tester) async {
      await addStudent('a1', 'p1', 1);
      await addStudent('a2', 'p1', 2);
      await addStudent('a3', 'p1', 3);
      await abrir(tester, origem: 'p1');

      expect(find.text('0 de 3 selecionado(s)'), findsOneWidget);
      await tester.tap(find.byKey(const Key('selecionar_aluno_a1')));
      await tester.tap(find.byKey(const Key('selecionar_aluno_a3')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('campo_destino_redistribuicao_p1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prof. Marina · 0/30 alunos').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('botao_mover_alunos')));
      await tester.pumpAndSettle();
      expect(find.text('Mover 2 aluno(s)?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('botao_confirmar_mover_alunos')));
      await tester.pumpAndSettle();

      expect(await professorDe('a1'), 'p2');
      expect(await professorDe('a3'), 'p2');
      expect(await professorDe('a2'), 'p1');
      expect(
        find.text('2 aluno(s) movido(s) para Prof. Marina.'),
        findsOneWidget,
      );
      // A lista da origem já não mostra quem saiu.
      expect(find.text('0 de 1 selecionado(s)'), findsOneWidget);
    });

    testWidgets('selecionar todos marca os alunos da origem', (tester) async {
      await addStudent('a1', 'p1', 1);
      await addStudent('a2', 'p1', 2);
      await abrir(tester, origem: 'p1');

      await tester.tap(find.byKey(const Key('botao_selecionar_todos')));
      await tester.pumpAndSettle();

      expect(find.text('2 de 2 selecionado(s)'), findsOneWidget);
      expect(find.text('Limpar seleção'), findsOneWidget);
    });

    testWidgets('sem origem pede para escolher e não deixa mover', (
      tester,
    ) async {
      await addStudent('a1', 'p1', 1);
      await abrir(tester);

      expect(find.text('Escolha o professor de origem.'), findsOneWidget);
      final botao = tester.widget<FilledButton>(
        find.byKey(const Key('botao_mover_alunos')),
      );
      expect(botao.onPressed, isNull);
    });

    testWidgets('oferece alunos sem professor como origem', (tester) async {
      await addStudent('a1', null, 1);
      await abrir(tester);

      await tester.tap(find.byKey(const Key('campo_origem_redistribuicao')));
      await tester.pumpAndSettle();

      expect(find.text('Sem professor (1 alunos)').last, findsOneWidget);
    });
  });
}
