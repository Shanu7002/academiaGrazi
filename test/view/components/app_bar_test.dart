import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe o título recebido e a cor padrão', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(appBar: CustomAppBar(title: 'Montagem de treino')),
      ),
    );

    expect(find.text('MONTAGEM DE TREINO'), findsOneWidget);

    final appBar = tester.widget<AppBar>(find.byType(AppBar));

    expect(appBar.backgroundColor, AppColors.surface);
  });
}
