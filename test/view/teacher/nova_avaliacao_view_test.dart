import 'package:academiagrazi/controller/teachers/teacher_user_searcher.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/users/registration_profile.dart';
import 'package:academiagrazi/service/evaluations/physical_evaluation_service.dart';
import 'package:academiagrazi/view/teacher/nova_avaliacao_view.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUser extends Fake implements User {
  @override
  String get uid => 'prof-1';
}

class _FakeAuth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => _FakeUser();
}

void main() {
  late FakeFirebaseFirestore db;

  setUp(() async {
    await locator.reset();
    db = FakeFirebaseFirestore();
    locator.registerSingleton<FirebaseAuth>(_FakeAuth());
    locator.registerSingleton<PhysicalEvaluationService>(
      PhysicalEvaluationService(db: db),
    );
  });

  tearDown(() async => locator.reset());

  testWidgets('calcula o resultado ao digitar e salva a avaliação', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    bool? salvou;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => TextButton(
                onPressed: () async {
                  salvou = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder:
                          (_) => const NovaAvaliacaoView(
                            aluno: UserSummary(
                              id: 'aluno-1',
                              name: 'Ana',
                              measurements: BodyMeasurements(
                                age: 30,
                                heightCm: 180,
                                weightKg: 80,
                              ),
                            ),
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

    // Medidas do cadastro vêm pré-preenchidas.
    expect(find.widgetWithText(TextFormField, '30'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '80.0'), findsOneWidget);

    const dobras = {
      'Peitoral': '10',
      'Axilar média': '12',
      'Tríceps': '14',
      'Subescapular': '16',
      'Abdominal': '20',
      'Suprailíaca': '15',
      'Coxa': '13',
    };
    for (final MapEntry(:key, :value) in dobras.entries) {
      await tester.enterText(find.widgetWithText(TextFormField, key), value);
    }
    await tester.pump();

    // Sem o sexo não há como calcular nem salvar.
    expect(
      find.text('Preencha o sexo e todas as medidas para calcular.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('botao_salvar_avaliacao')));
    await tester.pump();
    expect(find.text('Selecione o sexo do aluno.'), findsOneWidget);

    await tester.tap(find.text('Masculino'));
    await tester.pump();
    expect(find.text('14,6 %'), findsOneWidget);
    expect(find.text('68,3 kg'), findsOneWidget);

    await tester.tap(find.byKey(const Key('botao_salvar_avaliacao')));
    await tester.pumpAndSettle();

    expect(salvou, isTrue);
    final docs =
        await db
            .collection('users')
            .doc('aluno-1')
            .collection('evaluations')
            .get();
    expect(docs.size, 1);
    final dados = docs.docs.single.data();
    expect(dados['instructorId'], 'prof-1');
    expect(dados['sex'], 'male');
    expect((dados['skinfolds'] as Map)['abdominal'], 20);
  });

  Future<void> abrirComGenero(WidgetTester tester, Gender gender) async {
    tester.view.physicalSize = const Size(430, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: NovaAvaliacaoView(
          aluno: UserSummary(
            id: 'aluno-1',
            name: 'Ana',
            gender: gender,
            measurements: const BodyMeasurements(
              age: 30,
              heightCm: 180,
              weightKg: 80,
            ),
          ),
        ),
      ),
    );
    const dobras = {
      'Peitoral': '10',
      'Axilar média': '12',
      'Tríceps': '14',
      'Subescapular': '16',
      'Abdominal': '20',
      'Suprailíaca': '15',
      'Coxa': '13',
    };
    for (final MapEntry(:key, :value) in dobras.entries) {
      await tester.enterText(find.widgetWithText(TextFormField, key), value);
    }
    await tester.pump();
  }

  testWidgets('pré-seleciona o sexo pelo gênero informado no cadastro', (
    tester,
  ) async {
    await abrirComGenero(tester, Gender.male);

    // Sem tocar em "Masculino", o resultado já é calculado.
    expect(find.text('14,6 %'), findsOneWidget);
  });

  testWidgets('"Prefiro não informar" deixa o sexo para o professor', (
    tester,
  ) async {
    await abrirComGenero(tester, Gender.undisclosed);

    expect(
      find.text('Preencha o sexo e todas as medidas para calcular.'),
      findsOneWidget,
    );
  });
}
