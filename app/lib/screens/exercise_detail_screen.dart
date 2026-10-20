import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/muscle_group_avatar.dart';
import '../widgets/section_title.dart';

/// Карточка упражнения: иллюстрация, группа мышц, описание и техника.
class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final steps = exerciseTechnique[exercise.id] ?? const <String>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Упражнение')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Вместо фотографии — крупная иконка группы мышц (см. EXPLAIN L2).
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: MuscleGroupAvatar(
              muscleGroup: exercise.muscleGroup,
              radius: 56,
            ),
          ),
          const SizedBox(height: 16),
          Text(exercise.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: Icon(muscleGroupIcon(exercise.muscleGroup)),
              label: Text(exercise.muscleGroup),
            ),
          ),
          const SectionTitle('Описание', icon: Icons.info_outline),
          Text(exercise.description, style: theme.textTheme.bodyLarge),
          const SectionTitle('Техника выполнения', icon: Icons.checklist),
          for (var i = 0; i < steps.length; i++)
            _TechniqueStep(number: i + 1, text: steps[i]),
        ],
      ),
    );
  }
}

class _TechniqueStep extends StatelessWidget {
  const _TechniqueStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            child: Text('$number', style: theme.textTheme.labelLarge),
          ),
          const SizedBox(width: 12),
          // Expanded даёт тексту остаток ширины строки и включает перенос.
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
