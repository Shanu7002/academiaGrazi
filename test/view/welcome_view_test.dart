import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/welcome_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget testStrip() {
    return const MaterialApp(
      home: Scaffold(
        backgroundColor: AppColors.primary,
        body: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: WelcomeBottomBand(
                child: ColoredBox(color: AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('faixa da welcome fica centralizada e limitada no desktop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(testStrip());

    final band = find.byKey(const Key('welcome_bottom_band'));
    expect(band, findsOneWidget);
    expect(tester.getSize(band), const Size(430, 32));
    expect(tester.getTopLeft(band), const Offset(505, 868));
  });

  testWidgets('faixa acompanha a largura total em um celular estreito', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(testStrip());

    final band = find.byKey(const Key('welcome_bottom_band'));
    expect(band, findsOneWidget);
    expect(tester.getSize(band), const Size(390, 32));
    expect(tester.getTopLeft(band), const Offset(0, 812));
  });
}
