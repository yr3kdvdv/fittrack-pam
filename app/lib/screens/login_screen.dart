import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Вход. На L3 проверяется только формат полей: подходят любые правдоподобные
/// e-mail и пароль. Учётных записей и аутентификации нет — это L5.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// Простая проверка вида «что-то@что-то.что-то» без пробелов. Полный формат
/// адреса (RFC 5322) сложен, а существование адреса проверит только сервер.
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// E-mail обязателен и похож на адрес; пробелы по краям не считаются.
String? validateLoginEmail(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Введите e-mail';
  if (!_emailPattern.hasMatch(text)) {
    return 'Введите e-mail в формате name@example.com';
  }
  return null;
}

/// Минимальная длина пароля по заданию L3.
const minPasswordLength = 6;

/// Пароль не обрезается: пробел — тоже символ пароля.
String? validateLoginPassword(String? value) {
  final text = value ?? '';
  if (text.isEmpty) return 'Введите пароль';
  if (text.length < minPasswordLength) {
    return 'Пароль должен быть не короче $minPasswordLength символов';
  }
  return null;
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// После первой неудачной попытки ошибки обновляются сразу при исправлении.
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _submitted = true);
      return;
    }
    // go заменяет стек: «Назад» после входа не вернёт на вход.
    context.go('/exercises');
  }

  void _showRegistrationUnavailable() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Регистрация пока недоступна')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          // Прокрутка нужна, чтобы клавиатура на узком экране не вызывала overflow.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                autovalidateMode: _submitted
                    ? AutovalidateMode.always
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.fitness_center,
                        size: 40,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'FitTrack',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Дневник тренировок всегда под рукой',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      // next переводит фокус на пароль.
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        hintText: 'name@example.com',
                        errorMaxLines: 2,
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: validateLoginEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      // done на клавиатуре отправляет форму, как кнопка «Войти».
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Пароль',
                        errorMaxLines: 2,
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: validateLoginPassword,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _submit,
                      child: const Text('Войти'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      // Регистрация требует backend (L5); до него кнопка
                      // честно сообщает, что функции нет, а не молчит.
                      onPressed: _showRegistrationUnavailable,
                      child: const Text('Нет аккаунта? Зарегистрируйтесь'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
