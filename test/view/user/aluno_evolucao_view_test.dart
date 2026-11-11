import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/evaluations/physical_evaluation.dart';
import 'package:academiagrazi/service/evaluations/physical_evaluation_service.dart';
import 'package:academiagrazi/view/user/aluno_evolucao_view.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PhysicalEvaluation _avaliacao(DateTime date, double weightKg) =>
    PhysicalEvaluation(
      date: date,
      instructorId: 'prof-1',
      sex: BiologicalSex.male,
      age: 30,
      weightKg: weightKg,
      heightCm: 180,
      skinfolds: const Skinfolds(
        chest: 10,
        midaxillary: 12,
        triceps: 14,
        subscapular: 16,
        abdominal: 20,
        suprailiac: 15,
        thigh: 13,
      ),
    );

void main() {
  late PhysicalEvaluationService service;

  setUp(() async {
    await locator.reset();
    service = PhysicalEvaluationService(db: FakeFirebaseFirestore());
    locator.registerSingleton<PhysicalEvaluationService>(service);
  });

  tearDown(() async => locator.reset());

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: EvolucaoAlunoConteudo(alunoId: 'aluno-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('informa quando ainda não há avaliações', (tester) async {
    await abrir(tester);

    expect(
      find.text('Nenhuma avaliação física registrada ainda.'),
      findsOneWidget,
    );
  });

  testWidgets('mostra a última avaliação e atualiza ao receber uma nova', (
    tester,
  ) async {
    final hoje = DateTime.now();
    await service.addEvaluation(
      'aluno-1',
      _avaliacao(DateTime(hoje.year, hoje.month - 2, 1), 82),
    );
    await abrir(tester);

    expect(find.text('82,0'), findsOneWidget);
    expect(find.text('14,6 %'), findsOneWidget);
    expect(find.textContaining('desde a última'), findsNothing);

    // O professor registra outra avaliação: a tela do aluno reflete na hora.
    await service.addEvaluation(
      'aluno-1',
      _avaliacao(DateTime(hoje.year, hoje.month - 1, 1), 80),
    );
    await tester.pumpAndSettle();

    expect(find.text('80,0'), findsOneWidget);
    expect(find.text('- 2,0 kg desde a última'), findsOneWidget);
    expect(find.text('80,0 kg · 14,6 % gordura'), findsOneWidget);
    expect(find.text('82,0 kg · 14,6 % gordura'), findsOneWidget);
  });

  testWidgets('troca a métrica do gráfico pelo dropdown', (tester) async {
    final hoje = DateTime.now();
    await service.addEvaluation(
      'aluno-1',
      _avaliacao(DateTime(hoje.year, hoje.month - 2, 1), 82),
    );
    await service.addEvaluation(
      'aluno-1',
      _avaliacao(DateTime(hoje.year, hoje.month - 1, 1), 80),
    );
    await abrir(tester);

    final seletor = find.byKey(const Key('seletor_metrica_grafico'));
    expect(
      find.descendant(of: seletor, matching: find.text('Peso Corporal')),
      findsOneWidget,
    );
    expect(find.text('- 2,0 kg desde a última'), findsOneWidget);

    await tester.tap(seletor);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Massa Magra').last);
    await tester.pumpAndSettle();

    // 80 kg com 14,6 % de gordura -> 68,3 kg de massa magra.
    expect(find.text('68,3'), findsOneWidget);
    expect(find.text('- 1,7 kg desde a última'), findsOneWidget);

    await tester.tap(seletor);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gordura').last);
    await tester.pumpAndSettle();

    expect(find.text('14,6'), findsOneWidget);
    expect(find.text('+ 0,0 % desde a última'), findsOneWidget);
  });
}
