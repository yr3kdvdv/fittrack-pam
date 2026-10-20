import 'package:fittrack/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Показывает экран в теме FitTrack.
Future<void> pumpScreen(WidgetTester tester, Widget screen) {
  return tester.pumpWidget(
    MaterialApp(theme: buildFitTrackTheme(), home: screen),
  );
}

/// Худший проверяемый случай вёрстки: экран 320×640, крупный шрифт 1.3
/// и открытая клавиатура высотой 280 логических пикселей.
void useNarrowScreenWithKeyboard(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = const FakeViewPadding(bottom: 280);
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}
