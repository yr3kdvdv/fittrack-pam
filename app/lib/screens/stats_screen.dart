import 'package:flutter/material.dart';

import '../data/formatters.dart';
import '../data/mock_data.dart';
import '../widgets/metric_card.dart';
import '../widgets/section_title.dart';

/// Статистика прогресса: общие итоги и сессии по неделям.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final averageMinutes = (mockTotalMinutes / mockTotalSessions).round();
    final busiestWeek = mockWeeklyStats
        .map((week) => week.sessionCount)
        .reduce((a, b) => a > b ? a : b);
    // Длина полосы недели считается относительно самой длинной недели.
    final maxWeekMinutes = mockWeeklyStats
        .map((week) => week.totalMinutes)
        .reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('Статистика')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Последние ${mockWeeklyStats.length} недель',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 8),
          MetricPair(
            left: MetricCard(
              icon: Icons.timer_outlined,
              value: formatDuration(averageMinutes),
              label: 'Средняя тренировка',
            ),
            right: MetricCard(
              icon: Icons.emoji_events_outlined,
              value: '$busiestWeek',
              label: 'Максимум тренировок за неделю',
            ),
          ),
          const SectionTitle('Сессии по неделям', icon: Icons.date_range),
          for (final week in mockWeeklyStats)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _WeekCard(week: week, maxMinutes: maxWeekMinutes),
            ),
        ],
      ),
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
              value: week.totalMinutes / maxMinutes,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}
