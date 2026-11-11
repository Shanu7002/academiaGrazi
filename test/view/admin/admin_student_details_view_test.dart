import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/admin/admin_dashboard.dart';
import 'package:academiagrazi/service/admin/admin_student_service.dart';
import 'package:academiagrazi/view/admin/admin_student_details_view.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;

  setUp(() async {
    await locator.reset();
    db = FakeFirebaseFirestore();
    locator.registerSingleton<AdminStudentService>(
      AdminStudentService(db: db, clock: () => DateTime(2026, 11, 11, 10)),
    );
    locator.registerSingleton<AdminDashboardService>(
      AdminDashboardService(db: db),
    );
    await db.collection('users').doc('p1').set({
      'name': 'Prof. Lucas',
      'type': 'instructor',
    });
    await db.collection('users').doc('p2').set({
      'name': 'Prof. Marina',
      'type': 'instructor',
      'studentCapacity': 1,
    });
    await db.collection('users').doc('a1').set({
      'name': 'Ana Lima',
      'email': 'ana@test.com',
      'type': 'user',
      'responsable': 'p1',
      'createdAt': DateTime(2026, 11, 1).toUtc().toIso8601String(),
      'registrationProfile': {
        'measurements': {'age': 30, 'heightCm': 165, 'weightKg': 62.5},
        'primaryGoal': 'muscleGain',
        'health': {
          'conditions': ['Dor no joelho'],
          'restrictions': ['Não possuo'],
          'notes': '',
        },
        'emergencyContact': {
          'name': 'Maria',
          'relationship': 'Mãe',
          'phone': '11987654321',
        },
      },
    });
  });

  tearDown(() async => locator.reset());

  Future<void> abrir(WidgetTester tester, {String id = 'a1'}) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: AdminStudentDetailsView(studentId: id)),
    );
    await tester.pumpAndSettle();
  }

  Future<Map<String, dynamic>> aluno() async =>
      (await db.collection('users').doc('a1').get()).data()!;

  testWidgets('mostra os dados, a situação e a ficha de saúde', (tester) async {
    await abrir(tester);

    expect(find.text('Ana Lima'), findsOneWidget);
    expect(find.text('ana@test.com'), findsOneWidget);
    expect(find.text('Novo'), findsOneWidget);
    expect(find.text('Nenhum treino finalizado'), findsOneWidget);
    expect(find.text('Prof. Lucas'), findsOneWidget);
    expect(find.text('Ainda não definida'), findsOneWidget);
    expect(find.text('Ganho de Massa Muscular'), findsOneWidget);
    expect(find.text('Dor no joelho'), findsOneWidget);
    expect(find.textContaining('Maria'), findsOneWidget);
  });

  testWidgets('troca o professor responsável com confirmação', (tester) async {
    await abrir(tester);

    await tester.tap(find.byKey(const Key('botao_trocar_professor')));
    await tester.pumpAndSettle();

    // O professor atual não aparece como opção.
    expect(find.byKey(const Key('opcao_professor_p1')), findsNothing);
    expect(find.text('0/1 alunos'), findsOneWidget);

    await tester.tap(find.byKey(const Key('opcao_professor_p2')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('A ficha atual continua valendo'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('botao_confirmar_troca_professor')));
    await tester.pumpAndSettle();

    expect((await aluno())['responsable'], 'p2');
    expect(find.text('Professor responsável atualizado.'), findsOneWidget);
    expect(find.text('Prof. Marina'), findsOneWidget);
  });

  testWidgets('cancelar a troca mantém o professor', (tester) async {
    await abrir(tester);

    await tester.tap(find.byKey(const Key('botao_trocar_professor')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('opcao_professor_p2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect((await aluno())['responsable'], 'p1');
  });

  testWidgets('define a modalidade como remoto', (tester) async {
    await abrir(tester);

    await tester.tap(find.text('Remoto'));
    await tester.pumpAndSettle();

    expect((await aluno())['modality'], 'remote');
    expect(find.text('Remoto (treina em casa)'), findsOneWidget);
    expect(find.text('Modalidade atualizada.'), findsOneWidget);
  });

  testWidgets('aluno inexistente mostra aviso', (tester) async {
    await abrir(tester, id: 'nao-existe');

    expect(find.text('Aluno não encontrado.'), findsOneWidget);
  });
}
