import 'package:fittrack/data/formatters.dart';
import 'package:fittrack/data/mock_data.dart';
import 'package:fittrack/screens/workout_edit_screen.dart';
import 'package:fittrack/screens/workouts_screen.dart';
import 'package:fittrack/widgets/exercise_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Прокручивает форму до [target]. Жест начинается у левого края списка:
/// в центре экрана может оказаться многострочное поле «Заметки», которое
/// само перехватывает вертикальную прокрутку.
Future<void> _scrollFormTo(WidgetTester tester, Finder target) async {
  final formList = find
      .descendant(
        of: find.byType(WorkoutEditScreen),
        matching: find.byType(Scrollable),
      )
      .first;
  for (var i = 0; i < 30 && target.evaluate().isEmpty; i++) {
    final start = tester.getTopLeft(formList) + const Offset(6, 40);
    await tester.dragFrom(start, const Offset(0, -200));
    await tester.pump();
  }
  await tester.ensureVisible(target);
  await tester.pump();
}

void main() {
  testWidgets('форма: дата, длительность, упражнения, заметки, сохранить', (
    tester,
  ) async {
    await pumpScreen(tester, const WorkoutEditScreen());

    expect(find.text('Новая тренировка'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.widgetWithText(TextField, 'Дата'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Длительность'), findsOneWidget);
    // Новая сессия показывает зашитую демонстрационную дату, а не текущую.
    expect(find.text(formatNumericDate(mockToday)), findsOneWidget);
    expect(find.text('60'), findsOneWidget);
    expect(find.text('Упражнения'), findsOneWidget);
    await _scrollFormTo(tester, find.text('Сохранить'));
    expect(find.text('Заметки'), findsOneWidget);
    expect(find.text('Сохранить'), findsOneWidget);
  });

  testWidgets('редактирование показывает данные сессии в полях', (
    tester,
  ) async {
    final session = mockSessions.first;
    await pumpScreen(tester, WorkoutEditScreen(session: session));

    expect(find.text('Редактирование тренировки'), findsOneWidget);
    expect(find.text(formatNumericDate(session.date)), findsOneWidget);
    expect(find.text('${session.durationMin}'), findsOneWidget);

    final firstExercise = exerciseById(session.exerciseIds.first);
    await _scrollFormTo(tester, find.text(firstExercise.name));
    final checkbox = tester.widget<Checkbox>(
      find.descendant(
        of: find.widgetWithText(ExerciseTile, firstExercise.name),
        matching: find.byType(Checkbox),
      ),
    );
    expect(checkbox.value, isTrue);

    await _scrollFormTo(tester, find.text(session.notes));
    expect(find.text(session.notes), findsOneWidget);
  });

  testWidgets('дневник открывает новую и редактируемую тренировку', (
    tester,
  ) async {
    await pumpScreen(tester, const WorkoutsScreen());

    await tester.tap(find.text('Новая тренировка'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutEditScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text(formatLongDate(mockSessions.first.date)));
    await tester.pumpAndSettle();
    expect(find.text('Редактирование тренировки'), findsOneWidget);

    await _scrollFormTo(tester, find.text('Сохранить'));
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutEditScreen), findsNothing);
    expect(find.byType(WorkoutsScreen), findsOneWidget);
  });

  testWidgets('форма без overflow на узком экране с клавиатурой', (
    tester,
  ) async {
    useNarrowScreenWithKeyboard(tester);
    await pumpScreen(tester, WorkoutEditScreen(session: mockSessions[2]));

    await tester.showKeyboard(find.widgetWithText(TextField, 'Дата'));
    await tester.pump();
    await _scrollFormTo(tester, find.text('Сохранить'));

    expect(tester.takeException(), isNull);
  });
}
