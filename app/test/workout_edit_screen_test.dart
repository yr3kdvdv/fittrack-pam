import 'package:fittrack/data/exercise.dart';
import 'package:fittrack/data/formatters.dart';
import 'package:fittrack/data/mock_data.dart';
import 'package:fittrack/data/mock_network.dart';
import 'package:fittrack/screens/not_found_screen.dart';
import 'package:fittrack/screens/workout_edit_screen.dart';
import 'package:fittrack/theme.dart';
import 'package:fittrack/widgets/error_view.dart';
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
    expect(_fieldText(tester, 'Дата'), formatNumericDate(DateTime.now()));
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

  testWidgets('прямой адрес редактирования: spinner, затем заполненная форма', (
    tester,
  ) async {
    final session = mockSessions.first;
    final backend = TestBackend(latency: const Duration(milliseconds: 800));
    await tester.pumpWidget(
      backend.wrap(
        MaterialApp(
          theme: buildFitTrackTheme(),
          home: WorkoutEditScreen(sessionId: session.id),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(NotFoundScreen), findsNothing);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(_fieldText(tester, 'Длительность'), '${session.durationMin}');
  });

  testWidgets('ошибка загрузки формы: retry, затем поля сессии', (
    tester,
  ) async {
    final session = mockSessions.first;
    final backend = TestBackend()..network.simulateError = true;
    await pumpScreen(
      tester,
      WorkoutEditScreen(sessionId: session.id),
      backend: backend,
    );
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.byType(NotFoundScreen), findsNothing);

    backend.network.simulateError = false;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(_fieldText(tester, 'Длительность'), '${session.durationMin}');
  });

  testWidgets('неизвестный id после загрузки — сообщение, не spinner', (
    tester,
  ) async {
    await pumpScreen(tester, const WorkoutEditScreen(sessionId: 'ws-404'));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Тренировка не найдена'), findsOneWidget);
  });

  testWidgets('извещения и перезагрузка модели не стирают ввод', (
    tester,
  ) async {
    final session = mockSessions.first;
    await pumpScreen(tester, WorkoutEditScreen(sessionId: session.id));

    await tester.enterText(_field('Длительность'), '123');
    await tester.enterText(_field('Дата'), '01.11.2026');

    // Мутация другой сессии и полная перезагрузка дневника.
    final model = workoutsModel(tester);
    final removing = model.remove(mockSessions.last.id);
    await tester.pump(Duration.zero);
    expect(await removing, isNull);
    final loading = model.load();
    await tester.pumpAndSettle();
    await loading;

    expect(find.byType(WorkoutEditScreen), findsOneWidget);
    expect(_fieldText(tester, 'Длительность'), '123');
    expect(_fieldText(tester, 'Дата'), '01.11.2026');
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

  testWidgets('новая тренировка: список вырос, badge и SnackBar без reload', (
    tester,
  ) async {
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
    final today = formatNumericDate(DateTime.now());
    expect(
      find.text('Тренировка $today сохранена: 45 мин, упражнений: 1'),
      findsOneWidget,
    );

    // Новая сессия сегодня — она первая в дневнике.
    final model = workoutsModel(tester);
    expect(model.count, mockSessions.length + 1);
    final created = model.sessions.first;
    expect(created.id, isNot(''));
    expect(created.durationMin, 45);
    expect(created.exerciseIds, [mockExercises.first.id]);
    expect(find.byKey(ValueKey(created.id)), findsOneWidget);
    expect(find.text(formatLongDate(DateTime.now())), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('${mockSessions.length + 1}'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('редактирование: модель и карточка обновлены, seed не тронут', (
    tester,
  ) async {
    final session = mockSessions.first;
    await pumpApp(tester, location: '/workouts/${session.id}/edit');

    await tester.enterText(_field('Длительность'), '90');
    await tester.enterText(_field('Дата'), '16.10.2026');
    // Снимаем одно выбранное упражнение и добавляем невыбранное.
    final removedName = mockExercises
        .firstWhere((e) => e.id == session.exerciseIds.first)
        .name;
    await _tapVisible(tester, find.text(removedName));
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

    final updated = workoutsModel(tester).byId(session.id)!;
    expect(updated.durationMin, 90);
    expect(updated.date, DateTime(2026, 10, 16));
    expect(updated.notes, 'Другие заметки');
    expect(updated.exerciseIds, [
      ...session.exerciseIds.skip(1),
      mockExercises.last.id,
    ]);
    expect(find.text('Пятница, 16 октября'), findsOneWidget);
    expect(workoutsModel(tester).count, mockSessions.length);
    // Repository работает с копией: общий seed не изменился.
    expect(mockSessions.first.durationMin, 50);
  });

  testWidgets('авария при сохранении: SnackBar, поля целы, повтор успешен', (
    tester,
  ) async {
    final backend = TestBackend();
    await pumpApp(tester, location: '/workouts', backend: backend);
    await tester.tap(find.text('Новая тренировка'));
    await tester.pumpAndSettle();

    await tester.enterText(_field('Длительность'), '33');
    await tester.enterText(_field('Дата'), '20.11.2026');
    await _tapVisible(tester, find.text(mockExercises[2].name));

    backend.network.simulateError = true;
    await _save(tester);
    expect(find.text(MockNetwork.errorMessage), findsOneWidget);
    expect(find.byType(WorkoutEditScreen), findsOneWidget);
    expect(_fieldText(tester, 'Длительность'), '33');
    expect(_fieldText(tester, 'Дата'), '20.11.2026');
    expect(_isChecked(tester, mockExercises[2]), isTrue);
    expect(workoutsModel(tester).count, mockSessions.length);

    // SnackBar с ошибкой лежит над кнопкой; ждём, пока он скроется.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    backend.network.simulateError = false;
    await _save(tester);
    expect(find.byType(WorkoutEditScreen), findsNothing);
    expect(workoutsModel(tester).count, mockSessions.length + 1);
  });

  testWidgets('двойное нажатие «Сохранить» создаёт одну тренировку', (
    tester,
  ) async {
    final backend = TestBackend(latency: const Duration(milliseconds: 800));
    await pumpApp(tester, location: '/workouts/new', backend: backend);

    await tester.enterText(_field('Длительность'), '40');
    await _tapVisible(tester, find.text(mockExercises.first.name));
    final button = find.text('Сохранить');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();

    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 100));
    // Кнопка выключена, пока запрос в пути.
    await tester.tap(button, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(workoutsModel(tester).count, mockSessions.length + 1);
    expect(find.byType(WorkoutEditScreen), findsNothing);
  });

  test('parseWorkoutDate читает проверенную дату', () {
    expect(parseWorkoutDate(' 05.03.2026 '), DateTime(2026, 3, 5));
  });
}
