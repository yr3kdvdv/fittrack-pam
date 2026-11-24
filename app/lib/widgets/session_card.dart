import 'package:flutter/material.dart';

import '../data/formatters.dart';
import '../data/workout_session.dart';

/// Карточка тренировки: дата, длительность, упражнения и заметки.
/// Названия упражнений передаёт экран: widget не знает, откуда данные.
class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.session,
    required this.exerciseNames,
    this.onTap,
  });

  final WorkoutSession session;
  final List<String> exerciseNames;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      formatLongDate(session.date),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DurationBadge(minutes: session.durationMin),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                exerciseNames.join(' · '),
                style: theme.textTheme.bodyMedium,
              ),
              if (session.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        session.notes,
                        // В списке заметка — подсказка; целиком она видна в форме.
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationBadge extends StatelessWidget {
  const _DurationBadge({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 16,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              formatDuration(minutes),
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: colorScheme.onSecondaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}
