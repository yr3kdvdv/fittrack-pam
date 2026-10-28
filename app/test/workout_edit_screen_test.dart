import 'package:fittrack/data/formatters.dart';
import 'package:fittrack/data/mock_data.dart';
import 'package:fittrack/screens/workout_edit_screen.dart';
import 'package:fittrack/screens/workouts_screen.dart';
import 'package:fittrack/widgets/exercise_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

String _fieldText(WidgetTester tester, String label) =>
    tester.widget<TextFormField>(_field(label)).controller!.text;

bool _isChecked(WidgetTester tester, Exercise exercise) => tester
    .widget<Checkbox>(
      find.descendant(
        of: find.widgetWithText(ExerciseTile, exercise.name),
        matching: find.byType(Checkbox),
      ),
    )
    .value!;

Future<void> _tapVisible(WidgetTester tester, Finder target) async {
  // После enterText поле в следующем кадре само прокручивает к курсору;
  // без этого ожидания оно отменило бы ensureVisible ниже.
  await tester.pumpAndSettle();
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) =>
    _tapVisible(tester, find.text('Сохранить'));

/// Снимок всех mock-сессий строками: списки сравниваются по содержимому.
List<String> _snapshotSessions() => [
  for (final s in mockSessions)
    '${s.id}|${s.date}|${s.exerciseIds.join(',')}|${s.durationMin}|${s.notes}',
];

void main() {
  group('правила полей', () {
    test('дата: существующий день в формате ДД.ММ.ГГГГ', () {
      expect(validateWorkoutDate(''), 'Укажите дату');
      expect(validateWorkoutDate('   '), 'Укажите дату');
      for (final wrongFormat in ['1.2.2026', '17.10.26', '2026.10.17', '..']) {
        expect(
          validateWorkoutDate(wrongFormat),
          'Введите дату в формате ДД.ММ.ГГГГ',
          reason: wrongFormat,
        );
      }
      for (final missing in [
        '31.02.2026',
        '29.02.2026',
        '00.10.2026',
        '17.13.2026',
      ]) {
        expect(
          validateWorkoutDate(missing),
          'Такой даты нет в календаре',
          reason: missing,
        );
      }
      // 2028 — високосный год, 29 февраля существует.
      expect(validateWorkoutDate('29.02.2028'), isNull);
      expect(validateWorkoutDate('17.10.2026'), isNull);
    });

    test('длительность: положительное целое число минут', () {
      expect(validateWorkoutDuration(''), 'Укажите длительность в минутах');
      expect(validateWorkoutDuration('0'), 'Длительность должна быть больше 0');
      expect(
        validateWorkoutDuration('000'),
        'Длительность должна быть больше 0',
      );
      // Больше максимального int: tryParse возвращает null без исключения.
      expect(
        validateWorkoutDuration('99999999999999999999'),
        'Слишком большое число',
      );
      expect(validateWorkoutDuration('45'), isNull);
    });
  });

  testWidgets('новая тренировка: текущая дата, пустые длительность и выбор', (
    tester,
  ) async {
    await pumpScreen(tester, const WorkoutEditScreen());

    expect(find.text('Новая тренировка'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(_fieldText(tester, 'Дата'), formatNumericDate(mockToday));
    expect(_fieldText(tester, 'Длительность'), isEmpty);
    for (final exercise in mockExercises) {
      expect(_isChecked(tester, exercise), isFalse, reason: exercise.id);
    }

    // next с даты переводит фокус на длительность.
    await tester.showKeyboard(_field('Дата'));
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    final durationInput = tester.widget<EditableText>(
      find.descendant(
        of: _field('Длительность'),
        matching: find.byType(EditableText),
      ),
    );
    expect(durationInput.focusNode.hasFocus, isTrue);
  });

  testWidgets('редактирование заполняет поля данными сессии', (tester) async {
    final session = mockSessions.first;
    await pumpScreen(tester, WorkoutEditScreen(sessionId: session.id));

    expect(find.text('Редактирование тренировки'), findsOneWidget);
    expect(_fieldText(tester, 'Дата'), formatNumericDate(session.date));
    expect(_fieldText(tester, 'Длительность'), '${session.durationMin}');
    expect(find.text(session.notes), findsOneWidget);
    for (final exercise in mockExercises) {
      expect(
        _isChecked(tester, exercise),
        session.exerciseIds.contains(exercise.id),
        reason: exercise.id,
      );
    }
  });

  testWidgets('фильтры не пропускают буквы в дату и длительность', (
    tester,
  ) async {
    await pumpScreen(tester, const WorkoutEditScreen());

    await tester.enterText(_field('Длительность'), '4a5 мин');
    await tester.enterText(_field('Дата'), '17/10/2026');
    await tester.pump();

    expect(_fieldText(tester, 'Длительность'), '45');
    expect(_fieldText(tester, 'Дата'), '17102026');
  });

  testWidgets('ошибки под полями, форма остаётся открытой; выбор снимает '
      'ошибку упражнений', (tester) async {
    await pumpScreen(tester, const WorkoutEditScreen());

    await tester.enterText(_field('Дата'), '31.02.2026');
    await _save(tester);

    expect(find.byType(WorkoutEditScreen), findsOneWidget);
    expect(find.text('Такой даты нет в календаре'), findsOneWidget);
    expect(find.text('Укажите длительность в минутах'), findsOneWidget);
    expect(find.text('Выберите хотя бы одно упражнение'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    // После первой попытки ошибки пересчитываются сразу при исправлении.
    await _tapVisible(tester, find.text(mockExercises[3].name));
    expect(_isChecked(tester, mockExercises[3]), isTrue);
    expect(find.text('Выберите хотя бы одно упражнение'), findsNothing);

    await tester.enterText(_field('Дата'), '29.02.2028');
    await tester.pump();
    expect(find.text('Такой даты нет в календаре'), findsNothing);
  });

  testWidgets('узкий экран с клавиатурой: первая ошибка видна, без overflow', (
    tester,
  ) async {
    useNarrowScreenWithKeyboard(tester);
    await pumpScreen(tester, const WorkoutEditScreen());

    await tester.showKeyboard(_field('Дата'));
    await tester.pump();
    // Кнопка внизу формы: длительность к этому моменту ушла за верх экрана.
    await _save(tester);

    expect(tester.takeException(), isNull);
    expect(
      find.text('Укажите длительность в минутах').hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('с низа формы первая ошибка видна вместе с подписью поля', (
    tester,
  ) async {
    useNarrowScreenWithKeyboard(tester);
    await pumpScreen(tester, const WorkoutEditScreen());

    await tester.enterText(_field('Дата'), '31.02.2026');
    await tester.enterText(_field('Длительность'), '0');
    // _save сначала прокручивает к кнопке: дата уходит далеко за верх экрана.
    await _save(tester);

    final viewport = tester.getRect(find.byType(SingleChildScrollView));
    final label = tester.getRect(
      find.descendant(of: _field('Дата'), matching: find.text('Дата')),
    );
    final error = tester.getRect(find.text('Такой даты нет в календаре'));
    // Плавающая подпись рамки выступает над полем; она не должна касаться
    // верхнего края прокрутки под AppBar.
    expect(label.top, greaterThan(viewport.top));
    expect(error.bottom, lessThanOrEqualTo(viewport.bottom));
    expect(find.text('Длительность должна быть больше 0'), findsOneWidget);
    expect(find.text('Выберите хотя бы одно упражнение'), findsOneWidget);
  });

  testWidgets('смена sessionId в том же State загружает другую сессию', (
    tester,
  ) async {
    final first = mockSessions[0];
    final second = mockSessions[1];
    await pumpScreen(tester, WorkoutEditScreen(sessionId: first.id));
    final state = tester.state(find.byType(WorkoutEditScreen));

    await tester.enterText(_field('Длительность'), '');
    await _save(tester);
    expect(find.text('Укажите длительность в минутах'), findsOneWidget);

    await pumpScreen(tester, WorkoutEditScreen(sessionId: second.id));
    await tester.pump();

    expect(tester.state(find.byType(WorkoutEditScreen)), same(state));
    expect(_fieldText(tester, 'Дата'), formatNumericDate(second.date));
    expect(_fieldText(tester, 'Длительность'), '${second.durationMin}');
    expect(find.text(second.notes), findsOneWidget);
    expect(find.text('Укажите длительность в минутах'), findsNothing);
    for (final exercise in mockExercises) {
      expect(
        _isChecked(tester, exercise),
        second.exerciseIds.contains(exercise.id),
        reason: exercise.id,
      );
    }
  });

  testWidgets('новая тренировка: SnackBar, возврат в дневник, mock тот же', (
    tester,
  ) async {
    final before = _snapshotSessions();
    await pumpApp(tester, location: '/workouts');
    await tester.tap(find.text('Новая тренировка'));
    await tester.pumpAndSettle();

    await tester.enterText(_field('Длительность'), '45');
    await _tapVisible(tester, find.text(mockExercises.first.name));
    await _save(tester);

    // Закрытие формы освобождает контроллеры без исключений.
    expect(tester.takeException(), isNull);
    expect(find.byType(WorkoutEditScreen), findsNothing);
    expect(find.byType(WorkoutsScreen), findsOneWidget);
    expect(
      find.text(
        'Тренировка ${formatNumericDate(mockToday)} сохранена: '
        '45 мин, упражнений: 1',
      ),
      findsOneWidget,
    );
    expect(_snapshotSessions(), before);
  });

  testWidgets('редактирование: SnackBar, возврат, mock-сессия не изменилась', (
    tester,
  ) async {
    final before = _snapshotSessions();
    final session = mockSessions.first;
    await pumpApp(tester, location: '/workouts/${session.id}/edit');

    await tester.enterText(_field('Длительность'), '90');
    await tester.enterText(_field('Дата'), '16.10.2026');
    // Снимаем одно выбранное упражнение и добавляем невыбранное.
    await _tapVisible(
      tester,
      find.text(exerciseById(session.exerciseIds.first).name),
    );
    await _tapVisible(tester, find.text(mockExercises.last.name));
    await tester.enterText(find.text(session.notes), 'Другие заметки');
    await _save(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(WorkoutsScreen), findsOneWidget);
    expect(
      find.text(
        'Тренировка 16.10.2026 сохранена: 1 ч 30 мин, упражнений: '
        '${session.exerciseIds.length}',
      ),
      findsOneWidget,
    );
    expect(_snapshotSessions(), before);
  });
}
