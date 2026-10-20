import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/admin/admin_dashboard.dart';
import 'package:academiagrazi/view/admin/admin_home_view.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDashboardService extends AdminDashboardService {
  final Future<StudentStats> Function() onGetStats;

  _FakeDashboardService(this.onGetStats) : super(db: FakeFirebaseFirestore());

  @override
  Future<StudentStats> getStudentStats({DateTime? now}) => onGetStats();
}

void main() {
  setUp(() {
    locator.reset();
    locator.allowReassignment = true;
  });

  tearDown(() => locator.reset());

  void registerService(Future<StudentStats> Function() onGetStats) {
    locator.registerSingleton<AdminDashboardService>(
      _FakeDashboardService(onGetStats),
    );
  }

  testWidgets('mostra o total de alunos vindo do banco e o crescimento', (
    tester,
  ) async {
    registerService(
      () async => const StudentStats(total: 156, newLast30Days: 6),
    );

    await tester.pumpWidget(const MaterialApp(home: AdminHomeView()));
    await tester.pumpAndSettle();

    expect(find.text('Visão Geral'), findsOneWidget);
    expect(find.text('156'), findsOneWidget);
    expect(find.text('+4%'), findsOneWidget);
    expect(find.text('Acesso Rápido'), findsOneWidget);
    expect(find.text('Alertas Operacionais'), findsOneWidget);
  });

  testWidgets('mostra -- quando a busca de alunos falha', (tester) async {
    registerService(() async => throw Exception('sem permissão'));

    await tester.pumpWidget(const MaterialApp(home: AdminHomeView()));
    await tester.pumpAndSettle();

    expect(find.text('--'), findsOneWidget);
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
