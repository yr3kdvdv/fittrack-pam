import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/exercise.dart';
import '../models/exercises_model.dart';
import '../widgets/error_view.dart';
import '../widgets/muscle_group_avatar.dart';
import '../widgets/section_title.dart';
import 'not_found_screen.dart';

/// Карточка упражнения: иллюстрация, группа мышц, описание и техника.
/// Из адреса приходит только id; упражнение и техника — из ExercisesModel.
class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  @override
  void initState() {
    super.initState();
    _requestTechnique();
  }

  @override
  void didUpdateWidget(ExerciseDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseId != widget.exerciseId) _requestTechnique();
  }

  /// Загрузка извещает подписчиков, а извещать во время build нельзя,
  /// поэтому запрос уходит после первого кадра.
  void _requestTechnique() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final model = context.read<ExercisesModel>();
      if (model.techniqueOf(widget.exerciseId) == null) {
        model.loadTechnique(widget.exerciseId);
      }
    });
  }

  void _reload() {
    final model = context.read<ExercisesModel>();
    model.load();
    model.loadTechnique(widget.exerciseId);
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ExercisesModel>();
    final exercise = model.byId(widget.exerciseId);

    final Widget body;
    if (model.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (model.error case final error?) {
      body = ErrorView(message: error, onRetry: _reload);
    } else if (exercise == null) {
      // Каталог загружен, а такого id в нём нет: старая ссылка или адрес,
      // набранный вручную. Сообщение, а не вечный spinner.
      return const NotFoundScreen(
        title: 'Упражнение',
        message: 'Упражнение не найдено',
        backLabel: 'К каталогу',
        backPath: '/exercises',
      );
    } else {
      body = _buildDetails(context, model, exercise);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Упражнение'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildDetails(
    BuildContext context,
    ExercisesModel model,
    Exercise exercise,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final steps = model.techniqueOf(exercise.id);
    final techniqueError = model.techniqueErrorOf(exercise.id);

    return ListView(
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
        // Своя триада у техники: описание уже видно, пока шаги грузятся.
        if (steps != null)
          for (var i = 0; i < steps.length; i++)
            _TechniqueStep(number: i + 1, text: steps[i])
        else if (techniqueError != null)
          ErrorView(
            message: techniqueError,
            onRetry: () =>
                context.read<ExercisesModel>().loadTechnique(exercise.id),
          )
        else
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
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
