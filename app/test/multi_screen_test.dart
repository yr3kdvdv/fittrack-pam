import 'package:fittrack/data/formatters.dart';
import 'package:fittrack/data/mock_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Finder _metric(String value, String label) => find.ancestor(
  of: find.text(label),
  matching: find.ancestor(of: find.text(value), matching: find.byType(Card)),
);

void main() {
  testWidgets('одна мутация в форме видна в дневнике, badge, статистике и '
      'профиле без перезагрузки', (tester) async {
    await pumpApp(tester, location: '/stats');
    await _openTab(tester, 'Профиль');
    final total = mockSessions.length;
    expect(_metric('$total', 'Тренировок'), findsOneWidget);

    await _openTab(tester, 'Дневник');
    await tester.tap(find.text('Новая тренировка'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Длительность'),
      '60',
    );
    await tester.pumpAndSettle();
    final exercise = find.text(mockExercises.first.name);
    await tester.ensureVisible(exercise);
    await tester.pumpAndSettle();
    await tester.tap(exercise);
    final save = find.text('Сохранить');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    // Дневник: новая запись сверху, badge вырос.
    expect(find.text(formatLongDate(DateTime.now())), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('${total + 1}'),
      ),
      findsOneWidget,
    );

    // Статистика и профиль были построены раньше и не перезагружались.
    await _openTab(tester, 'Статистика');
    expect(_metric('${total + 1}', 'Тренировок'), findsOneWidget);
    expect(_metric(formatDuration(780), 'Общее время'), findsOneWidget);

    await _openTab(tester, 'Профиль');
    expect(_metric('${total + 1}', 'Тренировок'), findsOneWidget);
  });
}
