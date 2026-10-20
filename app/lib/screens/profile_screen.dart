import 'package:flutter/material.dart';

import '../data/formatters.dart';
import '../data/mock_data.dart';
import '../widgets/metric_card.dart';
import '../widgets/section_title.dart';
import 'login_screen.dart';

/// Профиль пользователя: личные данные, итоги и настройки (статично).
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
                  // Настройки начнут сохраняться вместе с состоянием на L4.
                  onChanged: (_) {},
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
            // Выход только возвращает на экран входа: сессии пользователя пока нет.
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Выйти'),
          ),
        ],
      ),
    );
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
