import 'package:fittrack/data/formatters.dart';
import 'package:fittrack/data/mock_data.dart';
import 'package:fittrack/screens/workouts_screen.dart';
import 'package:fittrack/widgets/session_card.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  test('русские подписи даты и длительности', () {
    expect(formatLongDate(DateTime(2026, 10, 17)), 'Суббота, 17 октября');
    expect(formatDuration(45), '45 мин');
    expect(formatDuration(75), '1 ч 15 мин');
    expect(formatDuration(720), '12 ч');
  });

  testWidgets('дневник начинается с последней тренировки', (tester) async {
    await pumpScreen(tester, const WorkoutsScreen());

    final newest = mockSessions.first;
    expect(find.byType(SessionCard), findsWidgets);
    expect(find.text(formatLongDate(newest.date)), findsOneWidget);
    expect(find.text(formatDuration(newest.durationMin)), findsWidgets);
    expect(
      find.textContaining(exerciseById(newest.exerciseIds.first).name),
      findsOneWidget,
    );
  });

  testWidgets('дневник без overflow на узком экране до последней записи', (
    tester,
  ) async {
    useNarrowScreenWithKeyboard(tester);
    await pumpScreen(tester, const WorkoutsScreen());

    await tester.scrollUntilVisible(
      find.text(formatLongDate(mockSessions.last.date)),
      200,
    );

    expect(tester.takeException(), isNull);
  });
}
