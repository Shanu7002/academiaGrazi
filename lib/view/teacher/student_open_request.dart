import 'package:flutter/foundation.dart';

/// Pedido para uma aba da área do professor abrir um aluno, vindo de outra
/// tela, como as prioridades do painel ou a lista de alunos.
///
/// As abas ficam montadas no `IndexedStack`; elas ouvem este pedido em vez
/// de abrir uma segunda cópia da tela.
class StudentOpenRequest extends ChangeNotifier {
  String? _studentId;
  bool _edit = false;

  /// Aluno pedido.
  String? get studentId => _studentId;

  /// Abrir já na montagem da ficha (editar a atual ou montar uma nova).
  bool get edit => _edit;

  void open(String studentId, {bool edit = false}) {
    _studentId = studentId;
    _edit = edit;
    notifyListeners();
  }
}
