import 'package:fittrack/data/mock_data.dart';
import 'package:fittrack/main.dart';
import 'package:fittrack/screens/exercise_detail_screen.dart';
import 'package:fittrack/screens/exercises_screen.dart';
import 'package:fittrack/screens/home_shell.dart';
import 'package:fittrack/screens/login_screen.dart';
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

void main() {
  testWidgets('демонстрационный маршрут проходит все 7 экранов', (
    tester,
  ) async {
    await tester.pumpWidget(const FitTrackApp());

    // 1. Вход → оболочка с каталогом.
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeShell), findsOneWidget);

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

  testWidgets('вкладки оболочки без overflow на узком экране с клавиатурой', (
    tester,
  ) async {
    useNarrowScreenWithKeyboard(tester);
    await pumpScreen(tester, const HomeShell());

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
