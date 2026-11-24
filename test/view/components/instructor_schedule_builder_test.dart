import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/units/instructor_shift_service.dart';
import 'package:academiagrazi/service/units/unit_service.dart';
import 'package:academiagrazi/view/components/instructor_schedule_builder.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 2026-11-09 é uma segunda-feira.
  final segunda9h = DateTime(2026, 11, 9, 9);

  group('nextShiftWhen', () {
    test('hoje, amanhã ou o dia da semana', () {
      expect(
        nextShiftWhen(DateTime(2026, 11, 9, 14), segunda9h),
        'Hoje às 14:00',
      );
      expect(
        nextShiftWhen(DateTime(2026, 11, 10, 7, 30), segunda9h),
        'Amanhã às 07:30',
      );
      expect(
        nextShiftWhen(DateTime(2026, 11, 11, 8), segunda9h),
        'Quarta às 08:00',
      );
    });
  });

  group('InstructorScheduleBuilder', () {
    late FakeFirebaseFirestore db;

    setUp(() async {
      await locator.reset();
      db = FakeFirebaseFirestore();
      locator.registerSingleton<InstructorShiftService>(
        InstructorShiftService(db: db),
      );
      locator.registerSingleton<UnitService>(UnitService(db: db));
    });

    tearDown(() async => locator.reset());

    Future<void> abrir(WidgetTester tester, DateTime agora) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InstructorScheduleBuilder(
              instructorId: 'p1',
              clock: () => agora,
              builder:
                  (context, escala) => Column(
                    children: [
                      Text(escala.currentLabel, key: const Key('atual')),
                      Text(escala.nextUnitLabel, key: const Key('proximo')),
                      Text(escala.nextWhenLabel, key: const Key('quando')),
                    ],
                  ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    String texto(WidgetTester tester, String key) =>
        tester.widget<Text>(find.byKey(Key(key))).data!;

    Future<void> escala() async {
      final unidades = locator<UnitService>();
      final blocoA = await unidades.createUnit(name: 'Bloco A');
      final blocoB = await unidades.createUnit(name: 'Bloco B');
      final turnos = locator<InstructorShiftService>();
      await turnos.addShift(
        instructorId: 'p1',
        unitId: blocoA,
        weekday: DateTime.monday,
        startTime: '07:00',
        endTime: '11:00',
      );
      await turnos.addShift(
        instructorId: 'p1',
        unitId: blocoB,
        weekday: DateTime.monday,
        startTime: '14:00',
        endTime: '18:00',
      );
    }

    testWidgets('dentro do turno mostra o bloco atual e o próximo', (
      tester,
    ) async {
      await escala();
      await abrir(tester, segunda9h);

      expect(texto(tester, 'atual'), 'Bloco atual: Bloco A (07:00–11:00)');
      expect(texto(tester, 'proximo'), 'Bloco B');
      expect(texto(tester, 'quando'), 'Hoje às 14:00');
    });

    testWidgets('fora do turno mostra "Sem turno agora"', (tester) async {
      await escala();
      await abrir(tester, DateTime(2026, 11, 9, 20));

      expect(texto(tester, 'atual'), 'Sem turno agora');
      // Próximo: a segunda seguinte, às 07:00.
      expect(texto(tester, 'proximo'), 'Bloco A');
      expect(texto(tester, 'quando'), 'Segunda às 07:00');
    });

    testWidgets('sem escala avisa que não há turnos', (tester) async {
      await abrir(tester, segunda9h);

      expect(texto(tester, 'atual'), 'Sem turno agora');
      expect(texto(tester, 'proximo'), 'Sem escala');
      expect(texto(tester, 'quando'), 'Nenhum turno cadastrado');
    });

    testWidgets('sem os services no locator não quebra', (tester) async {
      await locator.reset();
      await abrir(tester, segunda9h);

      expect(texto(tester, 'atual'), 'Sem turno agora');
    });
  });
}
