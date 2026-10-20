import 'package:fittrack/data/mock_data.dart';
import 'package:fittrack/screens/login_screen.dart';
import 'package:fittrack/screens/profile_screen.dart';
import 'package:fittrack/widgets/metric_card.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('профиль: имя, e-mail, итоги и личные данные', (tester) async {
    await pumpScreen(tester, const ProfileScreen());

    expect(find.text(mockUser.fullName), findsOneWidget);
    expect(find.text(mockUser.email), findsOneWidget);
    expect(find.text('АЧ'), findsOneWidget);
    expect(find.byType(MetricCard), findsNWidgets(2));
    expect(find.text('$mockTotalSessions'), findsOneWidget);

    await tester.scrollUntilVisible(find.text(mockUser.goal), 200);
    expect(find.text('${mockUser.heightCm} см'), findsOneWidget);
  });

  testWidgets('«Выйти» возвращает на экран входа', (tester) async {
    await pumpScreen(tester, const ProfileScreen());

    await tester.scrollUntilVisible(find.text('Выйти'), 200);
    await tester.ensureVisible(find.text('Выйти'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выйти'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(ProfileScreen), findsNothing);
  });

  testWidgets('профиль без overflow на узком экране', (tester) async {
    useNarrowScreenWithKeyboard(tester);
    await pumpScreen(tester, const ProfileScreen());

    await tester.scrollUntilVisible(find.text('Выйти'), 200);

    expect(tester.takeException(), isNull);
  });
}
