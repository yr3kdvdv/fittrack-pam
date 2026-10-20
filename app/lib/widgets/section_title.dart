import 'package:flutter/material.dart';

/// Заголовок смыслового блока внутри экрана. Единый вид отступов
/// и шрифта для деталей упражнения, формы, статистики и профиля.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
        ],
      ),
    );
  }
}
