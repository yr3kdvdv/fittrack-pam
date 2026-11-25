import 'package:fittrack/data/formatters.dart';
import 'package:fittrack/data/mock_data.dart';
import 'package:fittrack/data/mock_network.dart';
import 'package:fittrack/screens/not_found_screen.dart';
import 'package:fittrack/screens/workout_edit_screen.dart';
import 'package:fittrack/screens/workouts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

final _newest = mockSessions.first; // ws-13, первая карточка дневника

Finder _dialogButton(String label) => find.descendant(
  of: find.byType(AlertDialog),
  matching: find.widgetWithText(TextButton, label),
);

Future<void> _openDeleteDialog(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Удалить тренировку'));
  await tester.pumpAndSettle();
  expect(find.text('Удалить тренировку?'), findsOneWidget);
}

Future<void> _swipe(WidgetTester tester, String id) async {
  await tester.drag(find.byKey(ValueKey(id)), const Offset(-600, 0));
  await tester.pumpAndSettle();
}

String? _badge(WidgetTester tester) {
  final badge = tester.widget<Badge>(
    find
        .descendant(
          of: find.byType(NavigationBar),
          matching: find.byType(Badge),
        )
        .first,
  );
  return (badge.label as Text?)?.data;
}

void main() {
  testWidgets('форма: «Отмена», тап мимо и «Назад» ничего не удаляют', (
    tester,
  ) async {
    final router = await pumpApp(
      tester,
      location: '/workouts/${_newest.id}/edit',
    );

    await _openDeleteDialog(tester);
    await tester.tap(_dialogButton('Отмена'));
    await tester.pumpAndSettle();

    await _openDeleteDialog(tester);
    await tester.tapAt(const Offset(5, 5)); // результат null
    await tester.pumpAndSettle();

    await _openDeleteDialog(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(currentPath(router), '/workouts/${_newest.id}/edit');
    expect(workoutsModel(tester).byId(_newest.id), isNotNull);
    expect(workoutsModel(tester).count, mockSessions.length);
  });

  testWidgets('форма: подтверждение удаляет отовсюду и закрывает форму', (
    tester,
  ) async {
    // Прямой адрес: под формой go_router строит дневник, туда и вернёмся.
    final router = await pumpApp(
      tester,
      location: '/workouts/${_newest.id}/edit',
    );
    expect(_badge(tester), '${mockSessions.length}');

    await _openDeleteDialog(tester);
    await tester.tap(_dialogButton('Удалить'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(currentPath(router), '/workouts');
    expect(find.byType(WorkoutEditScreen), findsNothing);
    expect(find.byType(NotFoundScreen), findsNothing);
    expect(find.byType(WorkoutsScreen), findsOneWidget);
    expect(find.byKey(ValueKey(_newest.id)), findsNothing);
    expect(find.text(formatLongDate(_newest.date)), findsNothing);
    expect(find.text('Тренировка удалена'), findsOneWidget);
    expect(_badge(tester), '${mockSessions.length - 1}');
    expect(workoutsModel(tester).stats.totalSessions, mockSessions.length - 1);

    // Удалённая сессия по старому адресу — сообщение, не вечный spinner.
    router.go('/workouts/${_newest.id}/edit');
    await tester.pumpAndSettle();
    expect(find.text('Тренировка не найдена'), findsOneWidget);
  });

  testWidgets('форма: ошибка удаления — SnackBar, сессия и форма на месте', (
    tester,
  ) async {
    final backend = TestBackend();
    final router = await pumpApp(
      tester,
      location: '/workouts/${_newest.id}/edit',
      backend: backend,
    );
    backend.network.simulateError = true;

    await _openDeleteDialog(tester);
    await tester.tap(_dialogButton('Удалить'));
    await tester.pumpAndSettle();

    expect(find.text(MockNetwork.errorMessage), findsOneWidget);
    expect(currentPath(router), '/workouts/${_newest.id}/edit');
    expect(find.byType(WorkoutEditScreen), findsOneWidget);
    expect(workoutsModel(tester).byId(_newest.id), isNotNull);
  });

  testWidgets('свайп: отмена возвращает карточку, подтверждение удаляет', (
    tester,
  ) async {
    await pumpApp(tester, location: '/workouts');

    await _swipe(tester, _newest.id);
    await tester.tap(_dialogButton('Отмена'));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey(_newest.id)), findsOneWidget);
    expect(workoutsModel(tester).count, mockSessions.length);

    await _swipe(tester, _newest.id);
    await tester.tap(_dialogButton('Удалить'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(ValueKey(_newest.id)), findsNothing);
    expect(workoutsModel(tester).byId(_newest.id), isNull);
    expect(_badge(tester), '${mockSessions.length - 1}');
    // Следующая карточка стала первой и осталась целой.
    expect(find.byKey(ValueKey(mockSessions[1].id)), findsOneWidget);
  });

  testWidgets('свайп: ошибка хранилища возвращает карточку', (tester) async {
    final backend = TestBackend();
    await pumpApp(tester, location: '/workouts', backend: backend);
    backend.network.simulateError = true;

    await _swipe(tester, _newest.id);
    await tester.tap(_dialogButton('Удалить'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(MockNetwork.errorMessage), findsOneWidget);
    expect(find.byKey(ValueKey(_newest.id)), findsOneWidget);
    expect(workoutsModel(tester).count, mockSessions.length);
  });
}
