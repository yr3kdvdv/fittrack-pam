import 'package:fittrack/data/formatters.dart';
import 'package:fittrack/data/mock_data.dart';
import 'package:fittrack/data/mock_network.dart';
import 'package:fittrack/screens/workout_edit_screen.dart';
import 'package:fittrack/screens/workouts_screen.dart';
import 'package:fittrack/widgets/error_view.dart';
import 'package:fittrack/widgets/session_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Ошибки моделей, на которых стоит форма, после того как данные уже были
/// загружены (кеш есть, но текущее состояние — ошибка).

Finder _field(String label) => find.widgetWithText(TextFormField, label);

String _fieldText(WidgetTester tester, String label) =>
    tester.widget<TextFormField>(_field(label)).controller!.text;

Future<void> _tapVisible(WidgetTester tester, Finder target) async {
  await tester.pumpAndSettle();
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

FilledButton _saveButton(WidgetTester tester) => tester.widget<FilledButton>(
  find.ancestor(
    of: find.text('Сохранить'),
    matching: find.byWidgetPredicate((w) => w is FilledButton),
  ),
);

void main() {
  testWidgets('свежая новая форма при ошибке каталога в кеше — ErrorView и '
      'retry, затем сохранение обновляет дневник', (tester) async {
    final backend = TestBackend();
    await pumpApp(tester, location: '/exercises', backend: backend);

    // Каталог загружен, затем «Обновить» при аварии.
    backend.network.simulateError = true;
    await tester.tap(find.byTooltip('Обновить'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);

    await _openTab(tester, 'Дневник');
    await tester.tap(find.text('Новая тренировка'));
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutEditScreen), findsOneWidget);
    expect(find.byType(ErrorView), findsOneWidget);
    expect(_field('Длительность'), findsNothing);

    backend.network.simulateError = false;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsNothing);

    await tester.enterText(_field('Длительность'), '25');
    await _tapVisible(tester, find.text(mockExercises.first.name));
    await _tapVisible(tester, find.text('Сохранить'));

    expect(find.byType(WorkoutsScreen), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text(formatLongDate(DateTime.now())), findsOneWidget);
    expect(find.byType(SessionCard), findsWidgets);
  });

  testWidgets('свежая форма редактирования при ошибке дневника в кеше — '
      'ErrorView, не устаревшие поля', (tester) async {
    final backend = TestBackend();
    final router = await pumpApp(
      tester,
      location: '/workouts',
      backend: backend,
    );
    backend.network.simulateError = true;
    await tester.tap(find.byTooltip('Обновить'));
    await tester.pumpAndSettle();

    router.push('/workouts/${mockSessions.first.id}/edit');
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutEditScreen), findsOneWidget);
    expect(find.byType(ErrorView), findsOneWidget);
    expect(_field('Длительность'), findsNothing);

    backend.network.simulateError = false;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(
      _fieldText(tester, 'Длительность'),
      '${mockSessions.first.durationMin}',
    );
  });

  testWidgets('показанная форма: сбой перезагрузки на другой вкладке не '
      'стирает черновик, сохранение ждёт явного retry', (tester) async {
    final backend = TestBackend();
    await pumpApp(tester, location: '/workouts', backend: backend);
    await tester.tap(find.text('Новая тренировка'));
    await tester.pumpAndSettle();

    await tester.enterText(_field('Длительность'), '47');
    await tester.enterText(_field('Дата'), '21.11.2026');
    await _tapVisible(tester, find.text(mockExercises[4].name));

    // Другая вкладка перезагружает данные при аварии.
    await _openTab(tester, 'Статистика');
    backend.network.simulateError = true;
    await tester.tap(find.byTooltip('Обновить'));
    await tester.pumpAndSettle();
    await _openTab(tester, 'Упражнения');
    await tester.tap(find.byTooltip('Обновить'));
    await tester.pumpAndSettle();
    backend.network.simulateError = false;

    // Назад к черновику: поля целы, ошибка видна, сохранение выключено.
    await _openTab(tester, 'Дневник');
    expect(find.byType(WorkoutEditScreen), findsOneWidget);
    expect(_fieldText(tester, 'Длительность'), '47');
    expect(_fieldText(tester, 'Дата'), '21.11.2026');
    expect(find.text(MockNetwork.errorMessage), findsOneWidget);
    expect(_saveButton(tester).onPressed, isNull);

    // Явный retry внутри формы: данные свежие, черновик тот же.
    await _tapVisible(tester, find.text('Повторить'));
    expect(find.text(MockNetwork.errorMessage), findsNothing);
    expect(_fieldText(tester, 'Длительность'), '47');
    expect(_saveButton(tester).onPressed, isNotNull);

    await _tapVisible(tester, find.text('Сохранить'));
    expect(find.byType(WorkoutsScreen), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('Суббота, 21 ноября'), findsOneWidget);
    expect(workoutsModel(tester).count, mockSessions.length + 1);
  });
}
