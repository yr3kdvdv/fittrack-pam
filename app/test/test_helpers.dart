import 'package:fittrack/data/mock_exercise_repository.dart';
import 'package:fittrack/data/mock_network.dart';
import 'package:fittrack/data/mock_workout_repository.dart';
import 'package:fittrack/main.dart';
import 'package:fittrack/models/exercises_model.dart';
import 'package:fittrack/models/workouts_model.dart';
import 'package:fittrack/router.dart';
import 'package:fittrack/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Те же mock repositories, что в main.dart, но без задержки: тесты не ждут
/// 800 мс. Свежий экземпляр на тест — мутации одного теста не видны другому.
class TestBackend {
  TestBackend({Duration latency = Duration.zero})
    : network = MockNetwork(latency: latency) {
    workouts = MockWorkoutRepository(network);
    exercises = MockExerciseRepository(network);
  }

  final MockNetwork network;
  late final MockWorkoutRepository workouts;
  late final MockExerciseRepository exercises;

  Widget wrap(Widget child) => FitTrackProviders(
    network: network,
    workouts: workouts,
    exercises: exercises,
    child: child,
  );
}

/// Модели над приложением, как в main.dart.
Widget withModels(Widget child, {TestBackend? backend}) =>
    (backend ?? TestBackend()).wrap(child);

/// Модель дневника, видимая из [finder] (по умолчанию — из MaterialApp).
WorkoutsModel workoutsModel(WidgetTester tester, [Finder? finder]) =>
    Provider.of<WorkoutsModel>(
      tester.element(finder ?? find.byType(MaterialApp)),
      listen: false,
    );

ExercisesModel exercisesModel(WidgetTester tester) =>
    Provider.of<ExercisesModel>(
      tester.element(find.byType(MaterialApp)),
      listen: false,
    );

/// Показывает отдельный экран в теме FitTrack, без маршрутизатора, и ждёт
/// окончания загрузки. Подходит для вёрстки и состояний, не для переходов.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  TestBackend? backend,
}) async {
  await tester.pumpWidget(
    withModels(
      MaterialApp(theme: buildFitTrackTheme(), home: screen),
      backend: backend,
    ),
  );
  await tester.pumpAndSettle();
}

/// Запускает всё приложение со свежим роутером, открытым по [location].
/// Свой экземпляр на тест: стек одного теста не влияет на другой.
Future<GoRouter> pumpApp(
  WidgetTester tester, {
  String location = '/login',
  TestBackend? backend,
}) async {
  final router = createRouter(initialLocation: location);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    withModels(FitTrackApp(router: router), backend: backend),
  );
  await tester.pumpAndSettle();
  return router;
}

/// Заполняет форму входа и нажимает «Войти». По умолчанию данные валидны;
/// любые другие правдоподобные значения тоже подходят — аккаунтов нет.
Future<void> logIn(
  WidgetTester tester, {
  String email = 'student@example.com',
  String password = 'secret1',
}) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'E-mail'), email);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Пароль'),
    password,
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
  await tester.pumpAndSettle();
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
