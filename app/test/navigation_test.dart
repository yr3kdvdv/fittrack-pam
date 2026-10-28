import 'package:fittrack/data/formatters.dart';
import 'package:fittrack/data/mock_data.dart';
import 'package:fittrack/screens/exercise_detail_screen.dart';
import 'package:fittrack/screens/exercises_screen.dart';
import 'package:fittrack/screens/home_shell.dart';
import 'package:fittrack/screens/login_screen.dart';
import 'package:fittrack/screens/not_found_screen.dart';
import 'package:fittrack/screens/profile_screen.dart';
import 'package:fittrack/screens/stats_screen.dart';
import 'package:fittrack/screens/workout_edit_screen.dart';
import 'package:fittrack/screens/workouts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

/// Смещение вертикального списка видимой вкладки. Скрытые ветки
/// indexedStack находятся в Offstage, и find их пропускает.
double _scrollOffset(WidgetTester tester, Type listType) {
  final scrollable = find
      .descendant(of: find.byType(listType), matching: find.byType(Scrollable))
      .first;
  return tester.state<ScrollableState>(scrollable).position.pixels;
}

void main() {
  testWidgets('демонстрационный маршрут проходит все 7 экранов', (
    tester,
  ) async {
    final router = await pumpApp(tester);

    // 1. Вход → оболочка с каталогом.
    expect(find.byType(LoginScreen), findsOneWidget);
    await logIn(tester);
    expect(find.byType(HomeShell), findsOneWidget);
    expect(currentPath(router), '/exercises');

    // 2–3. Каталог → карточка упражнения → назад.
    expect(find.byType(ExercisesScreen), findsOneWidget);
    await tester.tap(find.text(mockExercises.first.name));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseDetailScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ExercisesScreen), findsOneWidget);

    // 4–5. Дневник → форма новой тренировки → назад.
    await _openTab(tester, 'Дневник');
    expect(find.byType(WorkoutsScreen), findsOneWidget);
    await tester.tap(find.text('Новая тренировка'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutEditScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutsScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    // 6. Статистика.
    await _openTab(tester, 'Статистика');
    expect(find.byType(StatsScreen), findsOneWidget);

    // 7. Профиль → выход на экран входа.
    await _openTab(tester, 'Профиль');
    expect(find.byType(ProfileScreen), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Выйти'), 200);
    await tester.ensureVisible(find.text('Выйти'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выйти'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeShell), findsNothing);
  });

  group('каждый экран открывается прямым адресом', () {
    final screens = <String, Type>{
      '/login': LoginScreen,
      '/exercises': ExercisesScreen,
      '/exercises/ex-01': ExerciseDetailScreen,
      '/workouts': WorkoutsScreen,
      '/workouts/new': WorkoutEditScreen,
      '/workouts/ws-13/edit': WorkoutEditScreen,
      '/stats': StatsScreen,
      '/profile': ProfileScreen,
    };
    for (final MapEntry(key: path, value: screen) in screens.entries) {
      testWidgets(path, (tester) async {
        final router = await pumpApp(tester, location: path);

        expect(find.byType(screen), findsOneWidget);
        expect(currentPath(router), path);
        // Панель видна везде, кроме входа, в том числе в деталях и форме.
        expect(
          find.byType(NavigationBar),
          path == '/login' ? findsNothing : findsOneWidget,
        );
      });
    }
  });

  testWidgets('каталог открывает детали двух разных упражнений по id', (
    tester,
  ) async {
    final router = await pumpApp(tester, location: '/exercises');

    for (final exercise in mockExercises.take(2)) {
      await tester.tap(find.text(exercise.name));
      await tester.pumpAndSettle();
      expect(currentPath(router), '/exercises/${exercise.id}');
      expect(find.text(exercise.description), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(currentPath(router), '/exercises');
    }
  });

  testWidgets('неизвестный id упражнения — сообщение и возврат в каталог', (
    tester,
  ) async {
    final router = await pumpApp(tester, location: '/exercises/ex-404');

    expect(tester.takeException(), isNull);
    expect(find.byType(NotFoundScreen), findsOneWidget);
    expect(find.text('Упражнение не найдено'), findsOneWidget);

    await tester.tap(find.text('К каталогу'));
    await tester.pumpAndSettle();
    expect(currentPath(router), '/exercises');
    expect(find.byType(ExercisesScreen), findsOneWidget);
  });

  testWidgets('дневник: new — новая форма, :id/edit — найденная сессия', (
    tester,
  ) async {
    final router = await pumpApp(tester, location: '/workouts');

    await tester.tap(find.text('Новая тренировка'));
    await tester.pumpAndSettle();
    expect(currentPath(router), '/workouts/new');
    expect(find.widgetWithText(AppBar, 'Новая тренировка'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    final session = mockSessions[1];
    await tester.tap(find.text(formatLongDate(session.date)));
    await tester.pumpAndSettle();
    expect(currentPath(router), '/workouts/${session.id}/edit');
    expect(find.text('Редактирование тренировки'), findsOneWidget);
    expect(find.text('${session.durationMin}'), findsOneWidget);
  });

  testWidgets('неизвестный id сессии — сообщение и возврат в дневник', (
    tester,
  ) async {
    final router = await pumpApp(tester, location: '/workouts/ws-404/edit');

    expect(tester.takeException(), isNull);
    expect(find.text('Тренировка не найдена'), findsOneWidget);

    await tester.tap(find.text('К дневнику'));
    await tester.pumpAndSettle();
    expect(currentPath(router), '/workouts');
  });

  testWidgets('после входа и после выхода назад вернуться нельзя', (
    tester,
  ) async {
    final router = await pumpApp(tester);

    await logIn(tester);
    // go заменил стек: под каталогом нет экрана входа.
    expect(router.canPop(), isFalse);
    expect(find.byType(LoginScreen), findsNothing);

    await _openTab(tester, 'Профиль');
    await tester.scrollUntilVisible(find.text('Выйти'), 200);
    await tester.ensureVisible(find.text('Выйти'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выйти'));
    await tester.pumpAndSettle();
    expect(currentPath(router), '/login');
    expect(router.canPop(), isFalse);
  });

  testWidgets('у каждой вкладки свой стек: детали и форма ждут возврата', (
    tester,
  ) async {
    final router = await pumpApp(tester, location: '/exercises');
    final exercise = mockExercises.first;

    await tester.tap(find.text(exercise.name));
    await tester.pumpAndSettle();
    expect(currentPath(router), '/exercises/${exercise.id}');

    await _openTab(tester, 'Дневник');
    await tester.tap(find.text('Новая тренировка'));
    await tester.pumpAndSettle();
    expect(currentPath(router), '/workouts/new');
    expect(find.byType(NavigationBar), findsOneWidget);

    // Возврат на вкладку показывает те же детали, а не корень каталога.
    await _openTab(tester, 'Упражнения');
    expect(currentPath(router), '/exercises/${exercise.id}');
    expect(find.byType(ExerciseDetailScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    // Повторный выбор активной вкладки не сбрасывает её к корню.
    await _openTab(tester, 'Упражнения');
    expect(currentPath(router), '/exercises/${exercise.id}');

    // Под деталями по-прежнему каталог.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(currentPath(router), '/exercises');
    expect(find.byType(ExercisesScreen), findsOneWidget);

    // Форма дневника тоже дождалась возврата, под ней — список сессий.
    await _openTab(tester, 'Дневник');
    expect(currentPath(router), '/workouts/new');
    expect(find.byType(WorkoutEditScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(currentPath(router), '/workouts');
    expect(find.byType(WorkoutsScreen), findsOneWidget);
  });

  testWidgets('прокрутка каталога и дневника сохраняется между вкладками', (
    tester,
  ) async {
    await pumpApp(tester, location: '/exercises');

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    final exercisesOffset = _scrollOffset(tester, CustomScrollView);
    expect(exercisesOffset, greaterThan(0));

    await _openTab(tester, 'Дневник');
    expect(_scrollOffset(tester, ListView), 0);
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();
    final workoutsOffset = _scrollOffset(tester, ListView);
    expect(workoutsOffset, greaterThan(0));

    // Повторный выбор активной вкладки не возвращает список в начало.
    await _openTab(tester, 'Дневник');
    expect(_scrollOffset(tester, ListView), workoutsOffset);

    await _openTab(tester, 'Упражнения');
    expect(_scrollOffset(tester, CustomScrollView), exercisesOffset);

    await _openTab(tester, 'Дневник');
    expect(_scrollOffset(tester, ListView), workoutsOffset);
  });

  testWidgets('вкладки оболочки без overflow на узком экране с клавиатурой', (
    tester,
  ) async {
    useNarrowScreenWithKeyboard(tester);
    await pumpApp(tester, location: '/exercises');

    // Клавиатура открыта из поиска внутри вложенного Scaffold вкладки.
    await tester.showKeyboard(find.byType(SearchBar));
    await tester.pump();
    expect(tester.takeException(), isNull);

    for (final label in ['Дневник', 'Статистика', 'Профиль', 'Упражнения']) {
      await _openTab(tester, label);
      expect(tester.takeException(), isNull, reason: label);
    }
  });
}
