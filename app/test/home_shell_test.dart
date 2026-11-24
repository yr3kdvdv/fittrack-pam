import 'package:fittrack/data/mock_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Badge на иконке вкладки «Дневник».
Finder _journalBadge() => find.descendant(
  of: find.byType(NavigationBar),
  matching: find.byType(Badge),
);

String _badgeLabel(WidgetTester tester) {
  final badge = tester.widget<Badge>(_journalBadge().first);
  expect(badge.isLabelVisible, isTrue);
  return (badge.label! as Text).data!;
}

void main() {
  testWidgets(
    'badge дневника показывает число тренировок и следит за моделью',
    (tester) async {
      // Badge виден из другой вкладки: мутация не связана с этим экраном.
      await pumpApp(tester, location: '/exercises');
      expect(_badgeLabel(tester), '${mockSessions.length}');

      final model = workoutsModel(tester);
      model.remove(mockSessions.first.id);
      await tester.pump();
      expect(_badgeLabel(tester), '${mockSessions.length - 1}');

      model.add(mockSessions.first);
      await tester.pump();
      expect(_badgeLabel(tester), '${mockSessions.length}');
    },
  );
}
