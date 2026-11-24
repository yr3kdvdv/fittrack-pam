import 'package:fittrack/data/mock_data.dart';
import 'package:fittrack/screens/exercise_detail_screen.dart';
import 'package:fittrack/screens/exercises_screen.dart';
import 'package:fittrack/screens/not_found_screen.dart';
import 'package:fittrack/theme.dart';
import 'package:fittrack/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  final longExercise = mockExercises.firstWhere((e) => e.name.length > 45);

  testWidgets('детали: название, группа, описание, техника и иллюстрация', (
    tester,
  ) async {
    final exercise = mockExercises.first;
    await pumpScreen(tester, ExerciseDetailScreen(exerciseId: exercise.id));

    expect(find.text(exercise.name), findsOneWidget);
    expect(find.widgetWithText(Chip, exercise.muscleGroup), findsOneWidget);
    expect(find.text('Описание'), findsOneWidget);
    expect(find.text(exercise.description), findsOneWidget);
    expect(find.text('Техника выполнения'), findsOneWidget);
    expect(find.text(exerciseTechnique[exercise.id]!.first), findsOneWidget);
  });

  testWidgets('прямой адрес: spinner, пока каталог грузится, затем данные', (
    tester,
  ) async {
    final backend = TestBackend(latency: const Duration(milliseconds: 800));
    await tester.pumpWidget(
      backend.wrap(
        MaterialApp(
          theme: buildFitTrackTheme(),
          home: const ExerciseDetailScreen(exerciseId: 'ex-01'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(NotFoundScreen), findsNothing);

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text(mockExercises.first.name), findsOneWidget);
    expect(find.text(exerciseTechnique['ex-01']!.first), findsOneWidget);
  });

  testWidgets('неизвестный id после загрузки — сообщение, не вечный spinner', (
    tester,
  ) async {
    await pumpScreen(tester, const ExerciseDetailScreen(exerciseId: 'ex-404'));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(NotFoundScreen), findsOneWidget);
    expect(find.text('Упражнение не найдено'), findsOneWidget);
  });

  testWidgets('авария: ошибка каталога с retry, затем данные и техника', (
    tester,
  ) async {
    final backend = TestBackend()..network.simulateError = true;
    await pumpScreen(
      tester,
      const ExerciseDetailScreen(exerciseId: 'ex-01'),
      backend: backend,
    );
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.byType(NotFoundScreen), findsNothing);

    backend.network.simulateError = false;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text(exerciseTechnique['ex-01']!.first), findsOneWidget);
  });

  testWidgets('ошибка только техники: описание видно, retry шагов', (
    tester,
  ) async {
    final backend = TestBackend();
    // Каталог уже загружен; авария начинается до открытия деталей,
    // поэтому падает только запрос техники.
    await pumpScreen(tester, const ExercisesScreen(), backend: backend);
    backend.network.simulateError = true;
    await pumpScreen(
      tester,
      const ExerciseDetailScreen(exerciseId: 'ex-02'),
      backend: backend,
    );
    expect(find.text(mockExercises[1].description), findsOneWidget);
    expect(find.byType(ErrorView), findsOneWidget);

    backend.network.simulateError = false;
    // Кнопка ниже описания, за краем экрана.
    await tester.ensureVisible(find.text('Повторить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text(exerciseTechnique['ex-02']!.first), findsOneWidget);
  });

  testWidgets('каталог открывает детали, «Назад» возвращает в каталог', (
    tester,
  ) async {
    await pumpApp(tester, location: '/exercises');

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
    await pumpScreen(tester, ExerciseDetailScreen(exerciseId: longExercise.id));

    await tester.scrollUntilVisible(
      find.text(exerciseTechnique[longExercise.id]!.last),
      100,
    );

    expect(tester.takeException(), isNull);
  });
}
