import 'package:fittrack/data/mock_data.dart';
import 'package:fittrack/main.dart';
import 'package:fittrack/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Badge на иконке вкладки «Дневник».
Badge _journalBadge(WidgetTester tester) => tester.widget<Badge>(
  find
      .descendant(of: find.byType(NavigationBar), matching: find.byType(Badge))
      .first,
);

String _badgeLabel(WidgetTester tester) {
  final badge = _journalBadge(tester);
  expect(badge.isLabelVisible, isTrue);
  return (badge.label! as Text).data!;
}

void main() {
  testWidgets('badge дневника следит за моделью из другой вкладки', (
    tester,
  ) async {
    // Badge виден из каталога: мутация не связана с этим экраном.
    await pumpApp(tester, location: '/exercises');
    expect(_badgeLabel(tester), '${mockSessions.length}');

    final model = workoutsModel(tester);
    final removed = model.sessions.first;
    final removing = model.remove(removed.id);
    // pump без duration не двигает поддельные часы, и Timer из
    // Future.delayed(Duration.zero) в MockNetwork не сработал бы.
    await tester.pump(Duration.zero);
    expect(await removing, isNull);
    await tester.pump();
    expect(_badgeLabel(tester), '${mockSessions.length - 1}');

    final adding = model.add(removed);
    await tester.pump(Duration.zero);
    expect(await adding, isNull);
    await tester.pump();
    expect(_badgeLabel(tester), '${mockSessions.length}');
  });

  testWidgets('пока дневник грузится 800 мс, число на badge скрыто', (
    tester,
  ) async {
    final backend = TestBackend(latency: const Duration(milliseconds: 800));
    final router = createRouter(initialLocation: '/exercises');
    addTearDown(router.dispose);
    await tester.pumpWidget(backend.wrap(FitTrackApp(router: router)));

    await tester.pump(const Duration(milliseconds: 799));
    expect(_journalBadge(tester).isLabelVisible, isFalse);

    await tester.pump(const Duration(milliseconds: 1));
    expect(_badgeLabel(tester), '${mockSessions.length}');
  });
}
