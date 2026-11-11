/// Nomes dos dias no padrão do `DateTime.weekday` (1 = segunda).
const List<String> weekdayNames = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];

/// Nome do dia da semana em pt-BR (1 = segunda, 7 = domingo).
String weekdayName(int weekday) => weekdayNames[weekday - 1];
