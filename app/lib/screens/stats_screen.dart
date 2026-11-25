import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/formatters.dart';
import '../models/workout_stats.dart';
import '../models/workouts_model.dart';
import '../widgets/error_view.dart';
import '../widgets/metric_card.dart';
import '../widgets/section_title.dart';

/// Статистика прогресса: итоги за всё время и сессии по неделям.
/// Считается из актуального дневника — новая тренировка сразу меняет цифры.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<WorkoutsModel>();

    final Widget body;
    if (model.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (model.error case final error?) {
      body = ErrorView(
        message: error,
        onRetry: () => context.read<WorkoutsModel>().load(),
      );
    } else if (model.count == 0) {
      body = const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Статистика появится после первой тренировки в дневнике.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      body = _StatsList(stats: model.stats);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () => context.read<WorkoutsModel>().load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: body,
    );
  }
}

class _StatsList extends StatelessWidget {
  const _StatsList({required this.stats});

  final WorkoutStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Период назван явно: итоги — по всем записям дневника, а список
        // недель — только недели, в которых были тренировки.
        Text(
          'За всё время · недель с тренировками: ${stats.weeks.length}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 8),
        MetricPair(
          left: MetricCard(
            icon: Icons.timer_outlined,
            value: formatDuration(stats.averageMinutes),
            label: 'Средняя тренировка',
          ),
          right: MetricCard(
            icon: Icons.emoji_events_outlined,
            value: '${stats.busiestWeekSessions}',
            label: 'Максимум тренировок за неделю',
          ),
        ),
        const SectionTitle('Сессии по неделям', icon: Icons.date_range),
        for (final week in stats.weeks)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _WeekCard(week: week, maxMinutes: stats.longestWeekMinutes),
          ),
      ],
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.week, required this.maxMinutes});

  final WeeklyStat week;
  final int maxMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatWeekRange(week.weekStart),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Тренировок: ${week.sessionCount} · '
              '${formatDuration(week.totalMinutes)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              // Неделя в списке всегда с тренировками, но 0 мин не исключён.
              value: maxMinutes == 0 ? 0 : week.totalMinutes / maxMinutes,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}
