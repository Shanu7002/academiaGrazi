import 'package:academiagrazi/service/memberships/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formata centavos em reais com milhar e vírgula', () {
    expect(formatBrl(12990), r'R$ 129,90');
    expect(formatBrl(5), r'R$ 0,05');
    expect(formatBrl(129900), r'R$ 1.299,00');
    expect(formatBrl(123456789), r'R$ 1.234.567,89');
  });

  test('lê valores digitados no formato brasileiro', () {
    expect(parseBrlToCents('129,90'), 12990);
    expect(parseBrlToCents('1.299,9'), 129990);
    expect(parseBrlToCents(r'R$ 50'), 5000);
    expect(parseBrlToCents('80.5'), 8050);
  });

  test('recusa textos que não são valor', () {
    expect(parseBrlToCents(''), isNull);
    expect(parseBrlToCents('abc'), isNull);
    expect(parseBrlToCents('12,345'), isNull);
    expect(parseBrlToCents('-10'), isNull);
  });
}
