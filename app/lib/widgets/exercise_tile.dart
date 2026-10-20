import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import 'muscle_group_avatar.dart';

/// Карточка упражнения в списке. Действие и правая часть передаются снаружи,
/// поэтому одна карточка служит и каталогу, и выбору упражнений в форме.
class ExerciseTile extends StatelessWidget {
  const ExerciseTile({
    super.key,
    required this.exercise,
    this.onTap,
    this.trailing,
  });

  final Exercise exercise;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: MuscleGroupAvatar(muscleGroup: exercise.muscleGroup),
        // Длинные названия переносятся на несколько строк, а не обрезаются.
        title: Text(exercise.name),
        subtitle: Text(exercise.muscleGroup),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
