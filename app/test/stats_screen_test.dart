import 'package:fittrack/data/formatters.dart';
import 'package:fittrack/data/mock_data.dart';
import 'package:fittrack/screens/stats_screen.dart';
import 'package:fittrack/widgets/metric_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  test('подпись недели внутри месяца и на стыке месяцев', () {
    expect(formatWeekRange(DateTime(2026, 10, 12)), '12–18 окт.');
    expect(formatWeekRange(DateTime(2026, 9, 28)), '28 сент. – 4 окт.');
  });

  testWidgets('статистика: итоги и все недели', (tester) async {
    await pumpScreen(tester, const StatsScreen());

    expect(find.byType(MetricCard), findsNWidgets(4));
    expect(find.text('$mockTotalSessions'), findsOneWidget);
    expect(find.text(formatDuration(mockTotalMinutes)), findsOneWidget);

    for (final week in mockWeeklyStats) {
      await tester.scrollUntilVisible(
        find.text(formatWeekRange(week.weekStart)),
        200,
      );
      expect(
        find.text(
          'Тренировок: ${week.sessionCount} · '
          '${formatDuration(week.totalMinutes)}',
        ),
        findsOneWidget,
      );
    }
    expect(find.byType(LinearProgressIndicator), findsWidgets);
  });

  testWidgets('статистика без overflow на узком экране', (tester) async {
    useNarrowScreenWithKeyboard(tester);
    await pumpScreen(tester, const StatsScreen());

    await tester.scrollUntilVisible(
      find.text(formatWeekRange(mockWeeklyStats.last.weekStart)),
      200,
    );

    expect(tester.takeException(), isNull);
  });
}
