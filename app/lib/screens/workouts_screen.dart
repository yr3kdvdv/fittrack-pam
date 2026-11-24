import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/exercises_model.dart';
import '../models/workouts_model.dart';
import '../widgets/error_view.dart';
import '../widgets/session_card.dart';

/// Дневник тренировок. Сессии из WorkoutsModel, сначала самые новые;
/// названия упражнений — из ExercisesModel. Карточке нужны обе модели,
/// поэтому экран ждёт и показывает ошибку любой из них.
class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  /// Retry и «Обновить»: перезапросить обе модели.
  void _reload(BuildContext context) {
    context.read<WorkoutsModel>().load();
    context.read<ExercisesModel>().load();
  }

  @override
  Widget build(BuildContext context) {
    final workouts = context.watch<WorkoutsModel>();
    final exercises = context.watch<ExercisesModel>();

    final Widget body;
    if (workouts.isLoading || exercises.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (workouts.error ?? exercises.error case final error?) {
      body = ErrorView(message: error, onRetry: () => _reload(context));
    } else if (workouts.sessions.isEmpty) {
      body = const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Пока нет тренировок. Добавьте первую кнопкой ниже.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      final sessions = workouts.sessions;
      body = ListView.separated(
        // Нижний отступ, чтобы кнопка не закрывала последнюю карточку.
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: sessions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final session = sessions[index];
          return SessionCard(
            // Идентичность из данных: при вставке и удалении Flutter
            // сопоставляет карточки по id, а не по позиции.
            key: ValueKey(session.id),
            session: session,
            exerciseNames: [
              for (final id in session.exerciseIds)
                exercises.byId(id)?.name ?? 'Упражнение удалено из каталога',
            ],
            // В адрес передаётся только id; форма сама найдёт сессию.
            onTap: () => context.push('/workouts/${session.id}/edit'),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Дневник'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () => _reload(context),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/workouts/new'),
        icon: const Icon(Icons.add),
        label: const Text('Новая тренировка'),
      ),
    );
  }
}
