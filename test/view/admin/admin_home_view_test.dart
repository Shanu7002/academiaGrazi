import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/admin/admin_dashboard.dart';
import 'package:academiagrazi/service/admin/hourly_movement.dart';
import 'package:academiagrazi/view/admin/admin_home_view.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDashboardService extends AdminDashboardService {
  final Future<StudentStats> Function() onGetStats;
  final Future<HourlyMovement> Function() onGetMovement;

  _FakeDashboardService(this.onGetStats, this.onGetMovement)
    : super(db: FakeFirebaseFirestore());

  @override
  Future<StudentStats> getStudentStats({DateTime? now}) => onGetStats();

  @override
  Future<HourlyMovement> getHourlyMovement({DateTime? now}) => onGetMovement();
}

Future<HourlyMovement> _semMovimento() async => hourlyMovement(const []);

void main() {
  setUp(() {
    locator.reset();
    locator.allowReassignment = true;
  });

  tearDown(() => locator.reset());

  void registerService(
    Future<StudentStats> Function() onGetStats, {
    Future<HourlyMovement> Function() onGetMovement = _semMovimento,
  }) {
    locator.registerSingleton<AdminDashboardService>(
      _FakeDashboardService(onGetStats, onGetMovement),
    );
  }

  Future<StudentStats> umAluno() async =>
      const StudentStats(total: 1, newLast30Days: 1);

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

  testWidgets('atalhos ainda não implementados avisam com SnackBar', (
    tester,
  ) async {
    registerService(() async => const StudentStats(total: 1, newLast30Days: 1));

    await tester.pumpWidget(const MaterialApp(home: AdminHomeView()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Finanças'));
    await tester.tap(find.text('Finanças'));
    await tester.pump();

    expect(find.text('Finanças estará disponível em breve.'), findsOneWidget);
  });
}
