import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Понятное сообщение вместо исключения, если id из адреса нет в mock-данных
/// (например, адрес набран вручную или запись удалена).
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({
    super.key,
    required this.title,
    required this.message,
    required this.backLabel,
    required this.backPath,
  });

  final String title;
  final String message;
  final String backLabel;

  /// Адрес списка, куда безопасно вернуться.
  final String backPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              // go, а не pop: при прямом открытии адреса возвращаться некуда.
              FilledButton.tonal(
                onPressed: () => context.go(backPath),
                child: Text(backLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
