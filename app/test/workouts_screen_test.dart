import 'package:fittrack/data/formatters.dart';
import 'package:fittrack/data/mock_data.dart';
import 'package:fittrack/screens/workouts_screen.dart';
import 'package:fittrack/theme.dart';
import 'package:fittrack/widgets/error_view.dart';
import 'package:fittrack/widgets/session_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

String _exerciseName(String id) =>
    mockExercises.firstWhere((e) => e.id == id).name;

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
      find.textContaining(_exerciseName(newest.exerciseIds.first)),
      findsOneWidget,
    );
    // Карточки помечены id из данных.
    expect(find.byKey(ValueKey(newest.id)), findsOneWidget);
  });

  testWidgets('spinner на время задержки, затем список', (tester) async {
    final backend = TestBackend(latency: const Duration(milliseconds: 800));
    await tester.pumpWidget(
      backend.wrap(
        MaterialApp(theme: buildFitTrackTheme(), home: const WorkoutsScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(SessionCard), findsWidgets);
  });

  testWidgets('авария: «Обновить» → ошибка, «Повторить» → данные', (
    tester,
  ) async {
    final backend = TestBackend();
    await pumpScreen(tester, const WorkoutsScreen(), backend: backend);

    backend.network.simulateError = true;
    await tester.tap(find.byTooltip('Обновить'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.byType(SessionCard), findsNothing);

    backend.network.simulateError = false;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.byType(SessionCard), findsWidgets);
  });

  testWidgets('пустой дневник — подсказка, без ошибок', (tester) async {
    final backend = TestBackend();
    await pumpScreen(tester, const WorkoutsScreen(), backend: backend);

    final model = workoutsModel(tester);
    for (final session in model.sessions) {
      final removing = model.remove(session.id);
      await tester.pump(Duration.zero);
      expect(await removing, isNull);
    }
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SessionCard), findsNothing);
    expect(find.textContaining('Пока нет тренировок'), findsOneWidget);
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
