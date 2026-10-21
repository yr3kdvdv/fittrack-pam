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
          // Значения сессии показаны подсказками: контроллер пришлось бы
          // создавать и освобождать (dispose) в State, а макету L2 он не нужен.
          // Подпись всегда сверху, чтобы подсказка была видна до ввода.
          TextField(
            keyboardType: TextInputType.datetime,
            decoration: InputDecoration(
              labelText: 'Дата',
              hintText: formatNumericDate(session?.date ?? mockToday),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              prefixIcon: const Icon(Icons.calendar_today_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Длительность',
              hintText: '${session?.durationMin ?? 60}',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              suffixText: 'мин',
              prefixIcon: const Icon(Icons.timer_outlined),
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
          TextField(
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: session?.notes ?? 'Рабочие веса, подходы, самочувствие',
              hintMaxLines: 6,
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
