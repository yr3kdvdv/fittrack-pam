import 'package:fittrack/main.dart';
import 'package:fittrack/router.dart';
import 'package:fittrack/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Показывает отдельный экран в теме FitTrack, без маршрутизатора.
/// Подходит только для проверки вёрстки, не для переходов.
Future<void> pumpScreen(WidgetTester tester, Widget screen) {
  return tester.pumpWidget(
    MaterialApp(theme: buildFitTrackTheme(), home: screen),
  );
}

/// Запускает всё приложение со свежим роутером, открытым по [location].
/// Свой экземпляр на тест: стек одного теста не влияет на другой.
Future<GoRouter> pumpApp(
  WidgetTester tester, {
  String location = '/login',
}) async {
  final router = createRouter(initialLocation: location);
  addTearDown(router.dispose);
  await tester.pumpWidget(FitTrackApp(router: router));
  await tester.pumpAndSettle();
  return router;
}

/// Путь верхнего экрана, например /exercises/ex-01.
String currentPath(GoRouter router) => router.state.uri.path;

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
