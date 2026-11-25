import 'package:fittrack/data/mock_data.dart';
import 'package:fittrack/screens/exercises_screen.dart';
import 'package:fittrack/theme.dart';
import 'package:fittrack/widgets/error_view.dart';
import 'package:fittrack/widgets/exercise_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Группы мышц seed-а в порядке первого появления.
final _groups = mockExercises.map((e) => e.muscleGroup).toSet().toList();

Future<void> _scrollTo(WidgetTester tester, Finder target) => tester
    .scrollUntilVisible(target, 300, scrollable: find.byType(Scrollable).first);

void main() {
  testWidgets('каталог: поиск, фильтр по всем группам мышц, список', (
    tester,
  ) async {
    await pumpScreen(tester, const ExercisesScreen());

    expect(find.byType(SearchBar), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Все'), findsOneWidget);
    for (final group in _groups) {
      expect(find.widgetWithText(FilterChip, group), findsOneWidget);
    }
    expect(find.byType(ExerciseTile), findsWidgets);
    expect(find.text(mockExercises.first.name), findsOneWidget);
  });

  testWidgets('каталог показывает последнее упражнение после прокрутки', (
    tester,
  ) async {
    await pumpScreen(tester, const ExercisesScreen());

    await _scrollTo(tester, find.text(mockExercises.last.name));

    expect(find.text(mockExercises.last.name), findsOneWidget);
  });

  testWidgets('800 мс spinner, затем данные из repository', (tester) async {
    final backend = TestBackend(latency: const Duration(milliseconds: 800));
    await tester.pumpWidget(
      backend.wrap(
        MaterialApp(theme: buildFitTrackTheme(), home: const ExercisesScreen()),
      ),
    );

    await tester.pump(const Duration(milliseconds: 799));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(ExerciseTile), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(mockExercises.first.name), findsOneWidget);
  });

  testWidgets('авария: «Обновить» → ошибка, «Повторить» → данные', (
    tester,
  ) async {
    final backend = TestBackend();
    await pumpScreen(tester, const ExercisesScreen(), backend: backend);

    backend.network.simulateError = true;
    await tester.tap(find.byTooltip('Обновить'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Сервер не отвечает — повторите попытку'), findsOneWidget);

    // Авария всё ещё включена: retry снова приводит к ошибке, без crash.
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);

    backend.network.simulateError = false;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text(mockExercises.first.name), findsOneWidget);
  });

  testWidgets('поиск и фильтр работают вместе и не меняют модель', (
    tester,
  ) async {
    await pumpScreen(tester, const ExercisesScreen());

    await tester.tap(find.widgetWithText(FilterChip, 'Ноги'));
    await tester.pump();
    final legs = mockExercises.where((e) => e.muscleGroup == 'Ноги');
    expect(find.byType(ExerciseTile), findsNWidgets(legs.length));

    // «жим» есть и в груди, и в плечах, но не в ногах.
    await tester.enterText(find.byType(SearchBar), 'ЖИМ');
    await tester.pump();
    expect(find.byType(ExerciseTile), findsNothing);
    expect(find.text('Ничего не найдено'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Грудь'));
    await tester.pump();
    // Жим лёжа и отЖИМания: поиск по подстроке без учёта регистра.
    expect(find.byType(ExerciseTile), findsNWidgets(2));
    expect(find.text('Жим штанги лёжа'), findsOneWidget);
    expect(find.text('Отжимания на брусьях'), findsOneWidget);

    // Снять фильтр: все упражнения со словом «жим».
    await tester.tap(find.widgetWithText(FilterChip, 'Все'));
    await tester.pump();
    final presses = mockExercises.where(
      (e) => e.name.toLowerCase().contains('жим'),
    );
    expect(find.byType(ExerciseTile), findsNWidgets(presses.length));

    await tester.enterText(find.byType(SearchBar), '');
    await tester.pump();
    await _scrollTo(tester, find.text(mockExercises.last.name));
    expect(exercisesModel(tester).exercises, hasLength(mockExercises.length));
  });

  testWidgets('текст поиска переживает перезагрузку каталога', (tester) async {
    await pumpScreen(tester, const ExercisesScreen());
    await tester.enterText(find.byType(SearchBar), 'планка');
    await tester.pump();

    await tester.tap(find.byTooltip('Обновить'));
    await tester.pumpAndSettle();

    expect(find.text('планка'), findsOneWidget);
    expect(find.byType(ExerciseTile), findsOneWidget);
  });

  testWidgets('каталог без overflow на узком экране с клавиатурой', (
    tester,
  ) async {
    useNarrowScreenWithKeyboard(tester);
    await pumpScreen(tester, const ExercisesScreen());

    await tester.showKeyboard(find.byType(SearchBar));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text(mockExercises[1].name),
      100,
      scrollable: find.byType(Scrollable).first,
    );

    expect(tester.takeException(), isNull);
  });
}
