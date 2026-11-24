import 'package:academiagrazi/view/user/ui_models/termos_privacidade_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renderiza a tela de termos e privacidade', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyTermsView()));
    await tester.pumpAndSettle();

    expect(find.byType(PrivacyTermsView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
