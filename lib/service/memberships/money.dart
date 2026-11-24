/// Valor em centavos no formato brasileiro: `R$ 1.299,90`.
String formatBrl(int cents) {
  final negative = cents < 0;
  final absolute = cents.abs();
  final reais = (absolute ~/ 100).toString();
  final centavos = (absolute % 100).toString().padLeft(2, '0');
  final grouped = StringBuffer();
  for (var i = 0; i < reais.length; i++) {
    if (i > 0 && (reais.length - i) % 3 == 0) grouped.write('.');
    grouped.write(reais[i]);
  }
  return '${negative ? '-' : ''}R\$ $grouped,$centavos';
}

/// Lê um valor digitado em reais ("129,90", "1.299,9", "R$ 50") e devolve
/// centavos; `null` quando o texto não é um valor válido.
int? parseBrlToCents(String input) {
  var text = input.replaceAll(RegExp(r'R\$|\s'), '');
  if (text.isEmpty) return null;
  if (text.contains(',')) {
    // Formato brasileiro: ponto separa milhar, vírgula separa centavos.
    text = text.replaceAll('.', '').replaceAll(',', '.');
  }
  final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(text);
  if (match == null) return null;
  final reais = int.parse(match[1]!);
  final centavos = int.parse((match[2] ?? '0').padRight(2, '0'));
  return reais * 100 + centavos;
}
