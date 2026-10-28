import 'package:fittrack/screens/home_shell.dart';
import 'package:fittrack/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

const _emailEmpty = 'Введите e-mail';
const _emailFormat = 'Введите e-mail в формате name@example.com';
const _passwordEmpty = 'Введите пароль';
const _passwordShort = 'Пароль должен быть не короче 6 символов';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

/// Внутренний TextField: у TextFormField нет геттеров клавиатуры и action.
TextField _textField(WidgetTester tester, String label) => tester.widget(
  find.descendant(of: _field(label), matching: find.byType(TextField)),
);

void main() {
  group('validateLoginEmail', () {
    test('пусто и одни пробелы — «Введите e-mail»', () {
      expect(validateLoginEmail(null), _emailEmpty);
      expect(validateLoginEmail(''), _emailEmpty);
      expect(validateLoginEmail('   '), _emailEmpty);
    });

    test('не похоже на адрес — ошибка формата', () {
      for (final value in [
        'student',
        'student@',
        '@example.com',
        'student@example',
        'student@example.',
        'stu dent@example.com',
        'student@@example.com',
      ]) {
        expect(validateLoginEmail(value), _emailFormat, reason: value);
      }
    });

    test('правдоподобный адрес верен, пробелы по краям обрезаются', () {
      expect(validateLoginEmail('a@b.c'), isNull);
      expect(validateLoginEmail('ivan.petrov@utm.md'), isNull);
      expect(validateLoginEmail('  student@example.com  '), isNull);
    });
  });

  group('validateLoginPassword', () {
    test('пусто — «Введите пароль»', () {
      expect(validateLoginPassword(null), _passwordEmpty);
      expect(validateLoginPassword(''), _passwordEmpty);
    });

    test('5 символов — коротко, 6 — достаточно', () {
      expect(validateLoginPassword('12345'), _passwordShort);
      expect(validateLoginPassword('123456'), isNull);
      expect(validateLoginPassword('длинный пароль'), isNull);
    });
  });

  testWidgets('поля: e-mail клавиатура и next, пароль скрыт и done', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(Form), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));

    final email = _textField(tester, 'E-mail');
    expect(email.keyboardType, TextInputType.emailAddress);
    expect(email.textInputAction, TextInputAction.next);
    expect(email.obscureText, isFalse);

    final password = _textField(tester, 'Пароль');
    expect(password.obscureText, isTrue);
    expect(password.textInputAction, TextInputAction.done);

    expect(find.widgetWithText(FilledButton, 'Войти'), findsOneWidget);
  });

  testWidgets('пустая форма: обе ошибки видны, вход не выполнен', (
    tester,
  ) async {
    final router = await pumpApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
    await tester.pumpAndSettle();

    expect(currentPath(router), '/login');
    expect(find.byType(HomeShell), findsNothing);
    expect(find.text(_emailEmpty), findsOneWidget);
    expect(find.text(_passwordEmpty), findsOneWidget);
  });

  testWidgets('неверный e-mail и пароль из 5 символов — остаёмся на входе', (
    tester,
  ) async {
    final router = await pumpApp(tester);

    await logIn(tester, email: 'student@example', password: '12345');

    expect(currentPath(router), '/login');
    expect(find.text(_emailFormat), findsOneWidget);
    expect(find.text(_passwordShort), findsOneWidget);

    // После первой попытки ошибка исчезает сразу при исправлении поля.
    await tester.enterText(_field('Пароль'), '123456');
    await tester.pump();
    expect(find.text(_passwordShort), findsNothing);
    expect(find.text(_emailFormat), findsOneWidget);

    await tester.enterText(_field('E-mail'), 'student@example.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
    await tester.pumpAndSettle();
    expect(currentPath(router), '/exercises');
  });

  // Аккаунтов нет: подходит любая пара, прошедшая проверку формата.
  for (final (email, password) in [
    ('student@example.com', 'secret1'),
    ('  ivan.petrov@utm.md ', 'другой пароль 2026'),
  ]) {
    testWidgets('валидные «$email» / «$password» открывают каталог', (
      tester,
    ) async {
      final router = await pumpApp(tester);

      await logIn(tester, email: email, password: password);

      expect(currentPath(router), '/exercises');
      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });
  }

  testWidgets('после входа canPop=false, системное «Назад» не открывает вход', (
    tester,
  ) async {
    final router = await pumpApp(tester);

    await logIn(tester);
    expect(router.canPop(), isFalse);

    // Как кнопка «Назад» Android: роутеру некуда возвращаться.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(HomeShell), findsOneWidget);
    expect(currentPath(router), '/exercises');
  });

  testWidgets('next переводит фокус на пароль, done отправляет форму', (
    tester,
  ) async {
    final router = await pumpApp(tester);

    await tester.showKeyboard(_field('E-mail'));
    tester.testTextInput.enterText('student@example.com');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    final passwordInput = tester.widget<EditableText>(
      find.descendant(
        of: _field('Пароль'),
        matching: find.byType(EditableText),
      ),
    );
    expect(passwordInput.focusNode.hasFocus, isTrue);

    tester.testTextInput.enterText('12345');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    // done с коротким паролем тоже проходит через validate.
    expect(currentPath(router), '/login');
    expect(find.text(_passwordShort), findsOneWidget);

    await tester.showKeyboard(_field('Пароль'));
    tester.testTextInput.enterText('123456');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(currentPath(router), '/exercises');
  });

  testWidgets('регистрация: SnackBar «пока недоступна», экран не меняется', (
    tester,
  ) async {
    final router = await pumpApp(tester);

    await tester.tap(find.text('Нет аккаунта? Зарегистрируйтесь'));
    await tester.pump();

    expect(find.text('Регистрация пока недоступна'), findsOneWidget);
    expect(currentPath(router), '/login');
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('узкий экран с клавиатурой: ошибки без overflow', (tester) async {
    useNarrowScreenWithKeyboard(tester);
    await pumpApp(tester);

    await tester.showKeyboard(_field('Пароль'));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Войти'));
    await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(_emailEmpty), findsOneWidget);
    expect(find.text(_passwordEmpty), findsOneWidget);
  });
}
