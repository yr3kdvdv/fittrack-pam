import 'package:fittrack/main.dart';
import 'package:fittrack/screens/home_shell.dart';
import 'package:fittrack/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('вход: два поля, скрытый пароль и кнопка «Войти»', (
    tester,
  ) async {
    await tester.pumpWidget(const FitTrackApp());

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    final password = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Пароль'),
    );
    expect(password.obscureText, isTrue);
    expect(find.widgetWithText(FilledButton, 'Войти'), findsOneWidget);
    expect(find.text('Нет аккаунта? Зарегистрируйтесь'), findsOneWidget);
  });

  testWidgets('«Войти» заменяет вход главной оболочкой', (tester) async {
    await tester.pumpWidget(const FitTrackApp());

    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('вход без overflow на узком экране с клавиатурой', (
    tester,
  ) async {
    useNarrowScreenWithKeyboard(tester);
    await pumpScreen(tester, const LoginScreen());

    await tester.showKeyboard(find.widgetWithText(TextField, 'Пароль'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
