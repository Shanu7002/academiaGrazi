import 'package:flutter/foundation.dart';

/// Pedido para uma aba da área do professor abrir um aluno (ou voltar para
/// a lista), vindo de outra aba, como as prioridades do painel.
///
/// As abas ficam montadas no `IndexedStack`; elas ouvem este pedido em vez
/// de abrir uma segunda cópia da tela.
class StudentOpenRequest extends ChangeNotifier {
  String? _studentId;

  /// Aluno pedido; null pede a lista de alunos.
  String? get studentId => _studentId;

  void open(String studentId) {
    _studentId = studentId;
    notifyListeners();
  }

  void showList() {
    _studentId = null;
    notifyListeners();
  }
}
