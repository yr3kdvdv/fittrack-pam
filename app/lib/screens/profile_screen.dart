import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/formatters.dart';
import '../data/mock_network.dart';
import '../data/user_profile.dart';
import '../models/profile_model.dart';
import '../models/workout_stats.dart';
import '../models/workouts_model.dart';
import '../widgets/error_view.dart';
import '../widgets/metric_card.dart';
import '../widgets/section_title.dart';

/// Профиль пользователя: личные данные из ProfileModel, итоги из дневника,
/// настройки и выход с подтверждением. Настройки и выход видны в любом
/// состоянии загрузки — даже когда данные профиля упали.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// Положение выключателя аварии — эфемерное состояние этого экрана.
  late bool _simulateError;

  @override
  void initState() {
    super.initState();
    // После выхода и повторного входа экран создаётся заново, а авария
    // могла остаться включённой: начинаем с фактического флага.
    _simulateError = context.read<MockNetwork>().simulateError;
  }

  void _setSimulateError(bool value) {
    setState(() => _simulateError = value);
    // Единственное место UI, которое знает о mock: леса демонстрации,
    // исчезают на L5 вместе с MockNetwork.
    context.read<MockNetwork>().simulateError = value;
  }

  void _reload(BuildContext context) {
    context.read<ProfileModel>().load();
    context.read<WorkoutsModel>().load();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileModel>();
    final workouts = context.watch<WorkoutsModel>();
    final user = profile.profile;

    final List<Widget> data;
    if (profile.isLoading || workouts.isLoading) {
      data = const [
        Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    } else if (profile.error ?? workouts.error case final error?) {
      data = [ErrorView(message: error, onRetry: () => _reload(context))];
    } else if (user == null) {
      // Без ошибки и без данных бывает только до первой загрузки.
      data = const [];
    } else {
      data = _buildData(context, user, workouts.stats);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () => _reload(context),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...data,
          const SectionTitle('Настройки', icon: Icons.settings_outlined),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Напоминания о тренировках'),
                  value: true,
                  // Сохранять настройку между запусками — задача L6, поэтому
                  // переключатель не меняется, а честно сообщает об этом.
                  onChanged: (_) => _showNotSavedYet(context),
                ),
                const ListTile(
                  leading: Icon(Icons.straighten),
                  title: Text('Единицы измерения'),
                  subtitle: Text('Килограммы, сантиметры'),
                ),
                // Доступен и при ошибке профиля: иначе аварию нельзя было
                // бы выключить с этого экрана.
                SwitchListTile(
                  secondary: const Icon(Icons.wifi_off),
                  title: const Text('Симулировать сбой сети'),
                  subtitle: const Text(
                    'Демонстрация: все запросы завершаются ошибкой',
                  ),
                  value: _simulateError,
                  onChanged: _setSimulateError,
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

  List<Widget> _buildData(
    BuildContext context,
    UserProfile user,
    WorkoutStats stats,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final initials = user.fullName.split(' ').map((part) => part[0]).join();
    return [
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
      // Итоги из живого дневника: меняются после любой мутации.
      MetricPair(
        left: MetricCard(
          icon: Icons.event_available,
          value: '${stats.totalSessions}',
          label: 'Тренировок',
        ),
        right: MetricCard(
          icon: Icons.schedule,
          value: formatDuration(stats.totalMinutes),
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
    ];
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
