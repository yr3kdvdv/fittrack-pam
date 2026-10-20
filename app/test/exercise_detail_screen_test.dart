import 'package:fittrack/data/mock_data.dart';
import 'package:fittrack/screens/exercise_detail_screen.dart';
import 'package:fittrack/screens/exercises_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  final longExercise = mockExercises.firstWhere((e) => e.name.length > 45);

  testWidgets('детали: название, группа, описание, техника и иллюстрация', (
    tester,
  ) async {
    final exercise = mockExercises.first;
    await pumpScreen(tester, ExerciseDetailScreen(exercise: exercise));

    expect(find.text(exercise.name), findsOneWidget);
    expect(find.widgetWithText(Chip, exercise.muscleGroup), findsOneWidget);
    expect(find.text('Описание'), findsOneWidget);
    expect(find.text(exercise.description), findsOneWidget);
    expect(find.text('Техника выполнения'), findsOneWidget);
    expect(find.text(exerciseTechnique[exercise.id]!.first), findsOneWidget);
  });

  testWidgets('каталог открывает детали, «Назад» возвращает в каталог', (
    tester,
  ) async {
    await pumpScreen(tester, const ExercisesScreen());

    await tester.tap(find.text(mockExercises.first.name));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseDetailScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseDetailScreen), findsNothing);
    expect(find.byType(ExercisesScreen), findsOneWidget);
  });

  testWidgets('длинное название без overflow на узком экране', (tester) async {
    useNarrowScreenWithKeyboard(tester);
    await pumpScreen(tester, ExerciseDetailScreen(exercise: longExercise));

    await tester.scrollUntilVisible(
      find.text(exerciseTechnique[longExercise.id]!.last),
      100,
    );

    expect(tester.takeException(), isNull);
  });
}
