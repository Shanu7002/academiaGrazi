import 'package:academiagrazi/service/admin/hourly_movement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime as(int hora, [int minuto = 0]) =>
      DateTime(2026, 11, 10, hora, minuto);

  test('agrupa por hora, das 6h às 22h, e acha o pico', () {
    final movimento = hourlyMovement([
      as(6),
      as(18, 5),
      as(18, 59),
      as(7, 30),
      as(18, 30),
      as(21, 59),
    ]);

    expect(movimento.firstHour, 6);
    expect(movimento.counts.length, 16);
    expect(movimento.counts[0], 1);
    expect(movimento.counts[1], 1);
    expect(movimento.counts[18 - 6], 3);
    expect(movimento.counts[21 - 6], 1);
    expect(movimento.total, 6);
    expect(movimento.peakCount, 3);
    expect(movimento.peakHour, 18);
  });

  test('ignora treinos fora da faixa de horário', () {
    final movimento = hourlyMovement([as(5, 59), as(22), as(23, 30), as(0)]);

    expect(movimento.isEmpty, isTrue);
    expect(movimento.peakHour, isNull);
  });

  test('no empate, o pico é o horário mais cedo', () {
    final movimento = hourlyMovement([as(9), as(19), as(9), as(19)]);

    expect(movimento.peakHour, 9);
  });

  test('sem treinos fica vazio, com uma barra zerada por hora', () {
    final movimento = hourlyMovement(const []);

    expect(movimento.isEmpty, isTrue);
    expect(movimento.peakCount, 0);
    expect(movimento.counts, everyElement(0));
  });

  test('usa a hora local de datas gravadas em UTC', () {
    final local = as(18, 15);
    final movimento = hourlyMovement([local.toUtc()]);

    expect(movimento.peakHour, 18);
  });
}
