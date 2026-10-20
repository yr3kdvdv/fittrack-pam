import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/exercise_tile.dart';
import '../widgets/muscle_group_avatar.dart';

/// Каталог упражнений. Поиск и фильтры на L2 только визуальные:
/// работать они начнут вместе с состоянием на L4.
class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Упражнения')),
      // Поиск, фильтры и список прокручиваются вместе, поэтому открытая
      // клавиатура на маленьком экране не вызывает overflow.
      body: CustomScrollView(
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: SearchBar(
                hintText: 'Поиск упражнений',
                leading: Icon(Icons.search),
                elevation: WidgetStatePropertyAll(0),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: _MuscleGroupFilters()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            sliver: SliverList.separated(
              itemCount: mockExercises.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  ExerciseTile(exercise: mockExercises[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleGroupFilters extends StatelessWidget {
  const _MuscleGroupFilters();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        spacing: 8,
        children: [
          // Выбор фильтра не меняет список до L4, поэтому «Все» выбран всегда.
          FilterChip(
            label: const Text('Все'),
            selected: true,
            onSelected: (_) {},
          ),
          for (final group in muscleGroups)
            FilterChip(
              avatar: Icon(muscleGroupIcon(group)),
              label: Text(group),
              selected: false,
              onSelected: (_) {},
            ),
        ],
      ),
    );
  }
}
