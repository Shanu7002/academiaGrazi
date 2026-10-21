import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/admin/admin_dashboard.dart';
import 'package:academiagrazi/view/admin/admin_team_view.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDashboardService extends AdminDashboardService {
  final Future<List<InstructorWorkload>> Function() onGetTeam;

  _FakeDashboardService(this.onGetTeam) : super(db: FakeFirebaseFirestore());

  @override
  Future<List<InstructorWorkload>> getTeamWorkload() => onGetTeam();
}

void main() {
  setUp(() {
    locator.reset();
    locator.allowReassignment = true;
  });

  tearDown(() => locator.reset());

  void registerService(Future<List<InstructorWorkload>> Function() onGetTeam) {
    locator.registerSingleton<AdminDashboardService>(
      _FakeDashboardService(onGetTeam),
    );
  }

  Future<void> pumpView(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminTeamView()));
    await tester.pumpAndSettle();
  }

  testWidgets('lista os professores com carga e sobrecarga', (tester) async {
    registerService(
      () async => const [
        InstructorWorkload(
          id: 'p2',
          name: 'Juliana Lima',
          email: 'ju@grazi.com',
          activeStudents: 33,
        ),
        InstructorWorkload(
          id: 'p1',
          name: 'Marcos',
          email: 'marcos@grazi.com',
          activeStudents: 24,
        ),
      ],
    );

    await pumpView(tester);

    expect(find.text('Carga da Equipe'), findsOneWidget);
    expect(find.text('Juliana Lima'), findsWidgets);
    expect(find.text('JL'), findsOneWidget);
    expect(find.text('Sobrecarga'), findsOneWidget);
    expect(find.text('Carga equilibrada'), findsOneWidget);
    expect(find.text('Capacidade (110%)'), findsOneWidget);
    expect(find.text('33/30'), findsOneWidget);
    expect(find.text('Capacidade (80%)'), findsOneWidget);
    expect(find.text('Distribuição de Alunos'), findsOneWidget);
  });

  testWidgets('mostra estado vazio sem professores', (tester) async {
    registerService(() async => const []);

    await pumpView(tester);

    expect(find.text('Nenhum professor cadastrado ainda.'), findsOneWidget);
    expect(find.text('Lista de Professores'), findsNothing);
  });

  testWidgets('permite tentar de novo quando a busca falha', (tester) async {
    var calls = 0;
    registerService(() async {
      calls++;
      if (calls == 1) throw Exception('permission-denied');
      return const [];
    });

    await pumpView(tester);
    expect(find.textContaining('Não foi possível carregar'), findsOneWidget);

    await tester.ensureVisible(find.text('Tentar novamente'));
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('Nenhum professor cadastrado ainda.'), findsOneWidget);
  });

  testWidgets('redistribuir alunos avisa que ainda não está disponível', (
    tester,
  ) async {
    registerService(() async => const []);

    await pumpView(tester);
    await tester.tap(find.byKey(const Key('botao_redistribuir_alunos')));
    await tester.pump();

    expect(
      find.text('Redistribuir alunos estará disponível em breve.'),
      findsOneWidget,
    );
  });
}
