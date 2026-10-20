import 'package:fittrack/data/mock_data.dart';
import 'package:fittrack/screens/exercises_screen.dart';
import 'package:fittrack/widgets/exercise_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('каталог: поиск, фильтр по всем группам мышц, список', (
    tester,
  ) async {
    await pumpScreen(tester, const ExercisesScreen());

    expect(find.byType(SearchBar), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Все'), findsOneWidget);
    for (final group in muscleGroups) {
      expect(find.widgetWithText(FilterChip, group), findsOneWidget);
    }
    expect(find.byType(ExerciseTile), findsWidgets);
    expect(find.text(mockExercises.first.name), findsOneWidget);
  });

  testWidgets('каталог показывает последнее упражнение после прокрутки', (
    tester,
  ) async {
    await pumpScreen(tester, const ExercisesScreen());

    await tester.scrollUntilVisible(
      find.text(mockExercises.last.name),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text(mockExercises.last.name), findsOneWidget);
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
