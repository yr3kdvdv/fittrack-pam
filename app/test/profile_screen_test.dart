import 'package:fittrack/data/mock_data.dart';
import 'package:fittrack/screens/home_shell.dart';
import 'package:fittrack/screens/login_screen.dart';
import 'package:fittrack/screens/profile_screen.dart';
import 'package:fittrack/widgets/metric_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'test_helpers.dart';

/// Открывает профиль в полном приложении и нажимает «Выйти» на экране.
Future<GoRouter> _openLogoutDialog(WidgetTester tester) async {
  final router = await pumpApp(tester, location: '/profile');
  final button = find.widgetWithText(OutlinedButton, 'Выйти');
  await tester.scrollUntilVisible(button, 200);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsOneWidget);
  return router;
}

Finder _dialogButton(String label) => find.descendant(
  of: find.byType(AlertDialog),
  matching: find.widgetWithText(TextButton, label),
);

/// Диалог закрыт, а пользователь остался в профиле внутри оболочки.
void _expectStillInProfile(GoRouter router) {
  expect(find.byType(AlertDialog), findsNothing);
  expect(currentPath(router), '/profile');
  expect(find.byType(ProfileScreen), findsOneWidget);
  expect(find.byType(HomeShell), findsOneWidget);
  expect(find.byType(LoginScreen), findsNothing);
}

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

  testWidgets('переключатель напоминаний честно сообщает, что не сохраняется', (
    tester,
  ) async {
    await pumpScreen(tester, const ProfileScreen());
    final tile = find.widgetWithText(
      SwitchListTile,
      'Напоминания о тренировках',
    );
    await tester.scrollUntilVisible(tile, 200);
    await tester.pumpAndSettle();

    await tester.tap(tile);
    await tester.pump();

    expect(find.text('Настройка пока не сохраняется'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);
  });

  testWidgets('«Выйти» сначала спрашивает подтверждение', (tester) async {
    final router = await _openLogoutDialog(tester);

    expect(find.text('Выйти из профиля?'), findsOneWidget);
    expect(_dialogButton('Отмена'), findsOneWidget);
    expect(_dialogButton('Выйти'), findsOneWidget);
    // Пока диалог открыт, профиль и адрес не меняются.
    expect(currentPath(router), '/profile');
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('«Отмена» закрывает диалог и оставляет профиль', (tester) async {
    final router = await _openLogoutDialog(tester);

    await tester.tap(_dialogButton('Отмена'));
    await tester.pumpAndSettle();

    _expectStillInProfile(router);
  });

  testWidgets('тап мимо диалога (результат null) не выходит', (tester) async {
    final router = await _openLogoutDialog(tester);

    // Угол экрана — затемнённый фон за диалогом.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    _expectStillInProfile(router);
  });

  testWidgets('системное «Назад» закрывает только диалог', (tester) async {
    final router = await _openLogoutDialog(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    _expectStillInProfile(router);
  });

  testWidgets('подтверждение открывает вход и убирает оболочку из стека', (
    tester,
  ) async {
    final router = await _openLogoutDialog(tester);

    await tester.tap(_dialogButton('Выйти'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(currentPath(router), '/login');
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeShell), findsNothing);
    expect(find.byType(ProfileScreen), findsNothing);
    expect(router.canPop(), isFalse);
  });

  testWidgets('профиль и диалог выхода без overflow на узком экране', (
    tester,
  ) async {
    useNarrowScreenWithKeyboard(tester);
    await pumpScreen(tester, const ProfileScreen());

    final button = find.widgetWithText(OutlinedButton, 'Выйти');
    await tester.scrollUntilVisible(button, 200);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
