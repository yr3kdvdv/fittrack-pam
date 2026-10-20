import 'package:flutter/material.dart';

/// Иконка группы мышц. Заменяет фотографию упражнения на L2.
IconData muscleGroupIcon(String muscleGroup) {
  return switch (muscleGroup) {
    'Ноги' => Icons.directions_run,
    'Грудь' => Icons.fitness_center,
    'Спина' => Icons.rowing,
    'Плечи' => Icons.accessibility_new,
    'Руки' => Icons.sports_martial_arts,
    'Пресс' => Icons.self_improvement,
    _ => Icons.sports_gymnastics,
  };
}

/// Круглый значок группы мышц; размер задаётся радиусом, чтобы один widget
/// подходил и для строки списка, и для крупной иллюстрации.
class MuscleGroupAvatar extends StatelessWidget {
  const MuscleGroupAvatar({
    super.key,
    required this.muscleGroup,
    this.radius = 20,
  });

  final String muscleGroup;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer,
      child: Icon(
        muscleGroupIcon(muscleGroup),
        size: radius,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }
}
