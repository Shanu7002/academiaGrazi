import 'package:academiagrazi/models/training/training_session.dart';
import 'package:academiagrazi/service/training/training_session_service.dart';
import 'package:academiagrazi/view/user/aluno_historico_sessoes_view.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _HistoricoQueFalha extends TrainingSessionService {
  _HistoricoQueFalha() : super(db: FakeFirebaseFirestore());

  @override
  Stream<List<TrainingSession>> watchHistory(String studentId) =>
      Stream.error(Exception('offline'));
}

void main() {
  testWidgets('mostra erro com "Tentar novamente" quando o histórico falha', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AlunoHistoricoSessoesView(
          studentId: 'aluno-1',
          service: _HistoricoQueFalha(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar seu histórico.'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
