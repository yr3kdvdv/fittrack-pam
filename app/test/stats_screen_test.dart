import 'package:fittrack/data/formatters.dart';
import 'package:fittrack/data/mock_data.dart';
import 'package:fittrack/data/workout_session.dart';
import 'package:fittrack/models/workout_stats.dart';
import 'package:fittrack/screens/stats_screen.dart';
import 'package:fittrack/widgets/error_view.dart';
import 'package:fittrack/widgets/metric_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Итоги seed-а L3 по неделям, сначала новые: (понедельник, сессий, минут).
final _seedWeeks = [
  (DateTime(2026, 10, 12), 3, 180),
  (DateTime(2026, 10, 5), 2, 105),
  (DateTime(2026, 9, 28), 2, 120),
  (DateTime(2026, 9, 21), 3, 160),
  (DateTime(2026, 9, 14), 1, 60),
  (DateTime(2026, 9, 7), 2, 95),
];

void main() {
  test('подпись недели внутри месяца и на стыке месяцев', () {
    expect(formatWeekRange(DateTime(2026, 10, 12)), '12–18 окт.');
    expect(formatWeekRange(DateTime(2026, 9, 28)), '28 сент. – 4 окт.');
  });

  group('WorkoutStats', () {
    test('seed L3: 13 тренировок, 12 ч, 6 недель с понедельника', () {
      final stats = WorkoutStats.fromSessions(mockSessions);
      expect(stats.totalSessions, 13);
      expect(stats.totalMinutes, 720);
      expect(stats.averageMinutes, 55);
      expect(stats.busiestWeekSessions, 3);
      expect(stats.longestWeekMinutes, 180);
      expect([
        for (final w in stats.weeks)
          (w.weekStart, w.sessionCount, w.totalMinutes),
      ], _seedWeeks);
      for (final week in stats.weeks) {
        expect(week.weekStart.weekday, DateTime.monday);
      }
    });

    test('пустой дневник: нули без деления на ноль', () {
      final stats = WorkoutStats.fromSessions(const []);
      expect(stats.totalSessions, 0);
      expect(stats.totalMinutes, 0);
      expect(stats.averageMinutes, 0);
      expect(stats.busiestWeekSessions, 0);
      expect(stats.weeks, isEmpty);
    });

    test('воскресенье относится к неделе, начатой в понедельник', () {
      final stats = WorkoutStats.fromSessions([
        WorkoutSession(
          id: 'a',
          userId: 'u',
          date: DateTime(2026, 11, 29), // воскресенье
          exerciseIds: ['ex-01'],
          durationMin: 30,
          notes: '',
        ),
      ]);
      expect(stats.weeks.single.weekStart, DateTime(2026, 11, 23));
    });
  });

  testWidgets('статистика: итоги и все недели', (tester) async {
    await pumpScreen(tester, const StatsScreen());

    expect(find.byType(MetricCard), findsNWidgets(4));
    expect(find.text('13'), findsOneWidget);
    expect(find.text(formatDuration(720)), findsOneWidget);
    expect(find.textContaining('За всё время'), findsOneWidget);

    for (final (monday, count, minutes) in _seedWeeks) {
      await tester.scrollUntilVisible(find.text(formatWeekRange(monday)), 200);
      expect(
        find.text('Тренировок: $count · ${formatDuration(minutes)}'),
        findsOneWidget,
      );
    }
    expect(find.byType(LinearProgressIndicator), findsWidgets);
  });

  testWidgets('новая тренировка сегодня сразу меняет статистику', (
    tester,
  ) async {
    await pumpScreen(tester, const StatsScreen());
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final adding = workoutsModel(tester).add(
      WorkoutSession(
        id: '',
        userId: '',
        date: today,
        exerciseIds: ['ex-01'],
        durationMin: 30,
        notes: '',
      ),
    );
    await tester.pump(Duration.zero);
    expect(await adding, isNull);
    await tester.pump();

    expect(find.text('14'), findsOneWidget);
    expect(find.text(formatDuration(750)), findsOneWidget);
    expect(
      find.text(formatWeekRange(WorkoutStats.mondayOf(today))),
      findsOneWidget,
    );
  });

  testWidgets('авария: ошибка с retry, затем данные', (tester) async {
    final backend = TestBackend()..network.simulateError = true;
    await pumpScreen(tester, const StatsScreen(), backend: backend);
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.byType(MetricCard), findsNothing);

    backend.network.simulateError = false;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.byType(MetricCard), findsNWidgets(4));
  });

  testWidgets('пустой дневник: понятная подсказка без crash', (tester) async {
    await pumpScreen(tester, const StatsScreen());
    final model = workoutsModel(tester);
    for (final session in model.sessions) {
      final removing = model.remove(session.id);
      await tester.pump(Duration.zero);
      await removing;
    }
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('появится после первой'), findsOneWidget);
  });

  testWidgets('статистика без overflow на узком экране', (tester) async {
    useNarrowScreenWithKeyboard(tester);
    await pumpScreen(tester, const StatsScreen());

    await tester.scrollUntilVisible(
      find.text(formatWeekRange(_seedWeeks.last.$1)),
      200,
    );

    expect(tester.takeException(), isNull);
  });
}
