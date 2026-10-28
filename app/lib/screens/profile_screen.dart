import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/formatters.dart';
import '../data/mock_data.dart';
import '../widgets/metric_card.dart';
import '../widgets/section_title.dart';

/// Профиль пользователя: личные данные, итоги, настройки (статично)
/// и выход с подтверждением.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const user = mockUser;
    final initials = user.fullName.split(' ').map((part) => part[0]).join();

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: Text(initials, style: theme.textTheme.headlineSmall),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.fullName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          MetricPair(
            left: const MetricCard(
              icon: Icons.event_available,
              value: '$mockTotalSessions',
              label: 'Тренировок',
            ),
            right: MetricCard(
              icon: Icons.schedule,
              value: formatDuration(mockTotalMinutes),
              label: 'Общее время',
            ),
          ),
          const SectionTitle('Личные данные', icon: Icons.badge_outlined),
          Card(
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.cake_outlined,
                  label: 'Возраст',
                  value: '${user.age} год',
                ),
                _InfoTile(
                  icon: Icons.height,
                  label: 'Рост',
                  value: '${user.heightCm} см',
                ),
                _InfoTile(
                  icon: Icons.monitor_weight_outlined,
                  label: 'Вес',
                  value: '${user.weightKg.toString().replaceAll('.', ',')} кг',
                ),
                _InfoTile(
                  icon: Icons.flag_outlined,
                  label: 'Цель',
                  value: user.goal,
                ),
                _InfoTile(
                  icon: Icons.repeat,
                  label: 'План',
                  value: 'Тренировок в неделю: ${user.weeklyTarget}',
                ),
              ],
            ),
          ),
          const SectionTitle('Настройки', icon: Icons.settings_outlined),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Напоминания о тренировках'),
                  value: true,
                  // Хранить настройку негде до общего состояния L4, поэтому
                  // переключатель не меняется, а честно сообщает об этом.
                  onChanged: (_) => _showNotSavedYet(context),
                ),
                const ListTile(
                  leading: Icon(Icons.straighten),
                  title: Text('Единицы измерения'),
                  subtitle: Text('Килограммы, сантиметры'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  void _showNotSavedYet(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Настройка пока не сохраняется')),
      );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      // Кнопки закрывают диалог через его собственный dialogCtx: context
      // профиля относится к странице под диалогом, а не к самому диалогу.
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Выйти из профиля?'),
        content: const Text('Чтобы продолжить, нужно будет снова войти.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    // Тап мимо диалога и системное «Назад» дают null — это тоже не выход.
    // Пока диалог был открыт, экран мог исчезнуть, поэтому проверяем mounted.
    if (ok == true && context.mounted) {
      // go заменяет весь стек, вместе с оболочкой вкладок: «Назад» с входа
      // не вернёт в приложение, а новый вход начнёт вкладки с корней.
      context.go('/login');
    }
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
