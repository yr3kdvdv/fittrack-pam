import 'package:flutter/material.dart';

import '../data/formatters.dart';
import '../data/mock_data.dart';
import '../widgets/exercise_tile.dart';
import '../widgets/section_title.dart';

/// Форма новой тренировки или редактирования существующей (если передана
/// [session]). Макет L2: без Form, валидации и сохранения — это L3/L4.
class WorkoutEditScreen extends StatelessWidget {
  const WorkoutEditScreen({super.key, this.session});

  final WorkoutSession? session;

  @override
  Widget build(BuildContext context) {
    final session = this.session;
    final selectedIds = session?.exerciseIds ?? const <String>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          session == null ? 'Новая тренировка' : 'Редактирование тренировки',
        ),
      ),
      // ListView прокручивает форму, когда клавиатура закрывает часть экрана.
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TextFormField используется ради initialValue: StatelessWidget не
          // может хранить TextEditingController. Form и validator не нужны.
          TextFormField(
            initialValue: formatNumericDate(session?.date ?? DateTime.now()),
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(
              labelText: 'Дата',
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: session?.durationMin.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Длительность',
              suffixText: 'мин',
              prefixIcon: Icon(Icons.timer_outlined),
            ),
          ),
          const SectionTitle('Упражнения', icon: Icons.fitness_center),
          for (final exercise in mockExercises)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ExerciseTile(
                exercise: exercise,
                // Отметка показывает состав тренировки; изменять его начнём на L4.
                trailing: Checkbox(
                  value: selectedIds.contains(exercise.id),
                  onChanged: (_) {},
                ),
              ),
            ),
          const SectionTitle('Заметки', icon: Icons.sticky_note_2_outlined),
          TextFormField(
            initialValue: session?.notes,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Рабочие веса, подходы, самочувствие',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            // Данные не сохраняются: кнопка только возвращает на предыдущий экран.
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check),
            label: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}
