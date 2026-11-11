import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/admin/admin_dashboard.dart';
import 'package:academiagrazi/service/admin/hourly_movement.dart';
import 'package:academiagrazi/service/units/gym_class_service.dart';
import 'package:academiagrazi/service/units/unit_service.dart';
import 'package:academiagrazi/view/admin/admin_home_view.dart';
import 'package:academiagrazi/view/admin/gym_classes_view.dart';
import 'package:academiagrazi/view/admin/instructor_details_view.dart';
import 'package:academiagrazi/view/admin/units_view.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDashboardService extends AdminDashboardService {
  final Future<StudentStats> Function() onGetStats;
  final Future<HourlyMovement> Function() onGetMovement;
  final Future<List<InstructorWorkload>> Function() onGetTeam;

  _FakeDashboardService(this.onGetStats, this.onGetMovement, this.onGetTeam)
    : super(db: FakeFirebaseFirestore());

  @override
  Future<List<InstructorWorkload>> getTeamWorkload() => onGetTeam();

  @override
  Future<StudentStats> getStudentStats({DateTime? now}) => onGetStats();

  @override
  Future<HourlyMovement> getHourlyMovement({DateTime? now}) => onGetMovement();
}

Future<HourlyMovement> _semMovimento() async => hourlyMovement(const []);

Future<List<InstructorWorkload>> _semEquipe() async => const [];

Future<StudentStats> umAluno() async =>
    const StudentStats(total: 1, newLast30Days: 1);

void main() {
  setUp(() {
    locator.reset();
    locator.allowReassignment = true;
  });

  tearDown(() => locator.reset());

  void registerService(
    Future<StudentStats> Function() onGetStats, {
    Future<HourlyMovement> Function() onGetMovement = _semMovimento,
    Future<List<InstructorWorkload>> Function() onGetTeam = _semEquipe,
  }) {
    locator.registerSingleton<AdminDashboardService>(
      _FakeDashboardService(onGetStats, onGetMovement, onGetTeam),
    );
  }

  group('alertas operacionais', () {
    Finder noCard(Finder finder) => find.descendant(
      of: find.byKey(const Key('card_alertas')),
      matching: finder,
    );

    testWidgets('sem alertas mostra o estado vazio', (tester) async {
      registerService(umAluno);

      await tester.pumpWidget(const MaterialApp(home: AdminHomeView()));
      await tester.pumpAndSettle();

      expect(noCard(find.text('Nenhum alerta no momento.')), findsOneWidget);
    });

    testWidgets('alerta de capacidade abre os detalhes do professor', (
      tester,
    ) async {
      registerService(
        () async =>
            const StudentStats(total: 50, newLast30Days: 0, inactive: 20),
        onGetTeam:
            () async => const [
              InstructorWorkload(
                id: 'p1',
                name: 'Prof. Lucas',
                email: 'lucas@test.com',
                activeStudents: 35,
              ),
            ],
      );

      await tester.pumpWidget(const MaterialApp(home: AdminHomeView()));
      await tester.pumpAndSettle();

      expect(
        noCard(find.text('Prof. Lucas está com 35 alunos para 30 vagas.')),
        findsOneWidget,
      );
      expect(noCard(find.text('Muitos alunos inativos')), findsOneWidget);

      final alerta = find.byKey(const Key('alerta_instructorOverCapacity_p1'));
      await tester.ensureVisible(alerta);
      await tester.tap(alerta);
      await tester.pumpAndSettle();

      expect(find.byType(InstructorDetailsView), findsOneWidget);
    });

    testWidgets('na falha mostra erro e tenta de novo', (tester) async {
      var chamadas = 0;
      registerService(
        umAluno,
        onGetTeam: () async {
          chamadas++;
          if (chamadas == 1) throw Exception('sem permissão');
          return const [];
        },
      );

      await tester.pumpWidget(const MaterialApp(home: AdminHomeView()));
      await tester.pumpAndSettle();

      expect(
        noCard(find.text('Não foi possível carregar os alertas.')),
        findsOneWidget,
      );

      await tester.ensureVisible(find.byKey(const Key('botao_tentar_alertas')));
      await tester.tap(find.byKey(const Key('botao_tentar_alertas')));
      await tester.pumpAndSettle();

      expect(noCard(find.text('Nenhum alerta no momento.')), findsOneWidget);
    });
  });

  group('movimentação por horário', () {
    Finder noCard(Finder finder) => find.descendant(
      of: find.byKey(const Key('card_movimentacao')),
      matching: finder,
    );

    testWidgets('mostra o pico calculado dos treinos', (tester) async {
      registerService(
        umAluno,
        onGetMovement:
            () async => hourlyMovement([
              DateTime(2026, 11, 10, 18),
              DateTime(2026, 11, 10, 18, 30),
              DateTime(2026, 11, 10, 7),
            ]),
      );

      await tester.pumpWidget(const MaterialApp(home: AdminHomeView()));
      await tester.pumpAndSettle();

      expect(noCard(find.text('Pico 18h')), findsOneWidget);
      expect(noCard(find.text('06:00')), findsOneWidget);
      expect(noCard(find.text('22:00')), findsOneWidget);
    });

    testWidgets('sem treinos mostra o estado vazio, sem pico', (tester) async {
      registerService(umAluno);

      await tester.pumpWidget(const MaterialApp(home: AdminHomeView()));
      await tester.pumpAndSettle();

      expect(
        noCard(find.text('Nenhum treino finalizado nos últimos 30 dias.')),
        findsOneWidget,
      );
      expect(noCard(find.textContaining('Pico')), findsNothing);
    });

    testWidgets('na falha mostra erro e tenta de novo', (tester) async {
      var chamadas = 0;
      registerService(
        umAluno,
        onGetMovement: () async {
          chamadas++;
          if (chamadas == 1) throw Exception('sem índice');
          return hourlyMovement([DateTime(2026, 11, 10, 9)]);
        },
      );

      await tester.pumpWidget(const MaterialApp(home: AdminHomeView()));
      await tester.pumpAndSettle();

      expect(
        noCard(find.text('Não foi possível carregar a movimentação.')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const Key('botao_tentar_movimentacao')),
      );
      await tester.tap(find.byKey(const Key('botao_tentar_movimentacao')));
      await tester.pumpAndSettle();

      expect(chamadas, 2);
      expect(noCard(find.text('Pico 9h')), findsOneWidget);
    });
  });

  testWidgets('mostra o total de alunos vindo do banco e o crescimento', (
    tester,
  ) async {
    registerService(
      () async => const StudentStats(
        total: 156,
        newLast30Days: 6,
        remote: 24,
        inactive: 8,
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: AdminHomeView()));
    await tester.pumpAndSettle();

    expect(find.text('Visão Geral'), findsOneWidget);
    Finder valor(String card, String texto) =>
        find.descendant(of: find.byKey(Key(card)), matching: find.text(texto));
    // Ativos = total − inativos.
    expect(valor('card_alunos_ativos', '148'), findsOneWidget);
    expect(valor('card_alunos_remotos', '24'), findsOneWidget);
    expect(valor('card_alunos_inativos', '8'), findsOneWidget);
    expect(find.text('+4%'), findsOneWidget);
    expect(find.text('Acesso Rápido'), findsOneWidget);
    expect(find.text('Alertas Operacionais'), findsOneWidget);
  });

  testWidgets('mostra -- quando a busca de alunos falha', (tester) async {
    registerService(() async => throw Exception('sem permissão'));

    await tester.pumpWidget(const MaterialApp(home: AdminHomeView()));
    await tester.pumpAndSettle();

    // Ativos, remotos e inativos.
    expect(find.text('--'), findsNWidgets(3));
  });

  testWidgets('atalho Blocos abre a tela de blocos', (tester) async {
    locator.registerSingleton<UnitService>(
      UnitService(db: FakeFirebaseFirestore()),
    );
    registerService(umAluno);

    await tester.pumpWidget(const MaterialApp(home: AdminHomeView()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('botao_blocos')));
    await tester.tap(find.byKey(const Key('botao_blocos')));
    await tester.pumpAndSettle();

    expect(find.byType(UnitsView), findsOneWidget);
  });

  testWidgets('atalho Aulas abre a grade e Finanças não aparece', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    locator.registerSingleton<UnitService>(UnitService(db: db));
    locator.registerSingleton<GymClassService>(GymClassService(db: db));
    registerService(umAluno);

    await tester.pumpWidget(const MaterialApp(home: AdminHomeView()));
    await tester.pumpAndSettle();

    expect(find.text('Finanças'), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('botao_aulas')));
    await tester.tap(find.byKey(const Key('botao_aulas')));
    await tester.pumpAndSettle();

    expect(find.byType(GymClassesView), findsOneWidget);
    expect(find.textContaining('disponível em breve'), findsNothing);
  });
}
