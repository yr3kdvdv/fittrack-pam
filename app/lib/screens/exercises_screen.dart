import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/exercise.dart';
import '../models/exercises_model.dart';
import '../widgets/error_view.dart';
import '../widgets/exercise_tile.dart';
import '../widgets/muscle_group_avatar.dart';

/// Каталог упражнений: данные — из ExercisesModel, поиск и фильтр по группе
/// мышц — эфемерное состояние этого экрана (setState), модель они не меняют.
class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  /// Свой контроллер: текст поиска переживает перезагрузку каталога,
  /// когда SearchBar на время исчезает за spinner-ом.
  final _searchController = TextEditingController();

  /// null — «Все» группы.
  String? _group;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Фильтр и поиск работают вместе, над копией из модели.
  List<Exercise> _visible(List<Exercise> all) {
    final query = _searchController.text.trim().toLowerCase();
    return [
      for (final e in all)
        if ((_group == null || e.muscleGroup == _group) &&
            e.name.toLowerCase().contains(query))
          e,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ExercisesModel>(); // watch в build

    final Widget body;
    if (model.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (model.error case final error?) {
      body = ErrorView(
        message: error,
        // read: действие в callback-е, не подписка.
        onRetry: () => context.read<ExercisesModel>().load(),
      );
    } else {
      body = _buildCatalog(model);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Упражнения'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () => context.read<ExercisesModel>().load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildCatalog(ExercisesModel model) {
    final visible = _visible(model.exercises);
    // Поиск, фильтры и список прокручиваются вместе, поэтому открытая
    // клавиатура на маленьком экране не вызывает overflow.
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverToBoxAdapter(
            child: SearchBar(
              controller: _searchController,
              hintText: 'Поиск упражнений',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildFilters(model.muscleGroups)),
        if (visible.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Ничего не найдено', textAlign: TextAlign.center),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            sliver: SliverList.separated(
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final exercise = visible[index];
                return ExerciseTile(
                  key: ValueKey(exercise.id),
                  exercise: exercise,
                  trailing: const Icon(Icons.chevron_right),
                  // push кладёт детали поверх каталога, «Назад» вернёт к списку.
                  onTap: () => context.push('/exercises/${exercise.id}'),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFilters(List<String> groups) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        spacing: 8,
        children: [
          FilterChip(
            label: const Text('Все'),
            selected: _group == null,
            onSelected: (_) => setState(() => _group = null),
          ),
          for (final group in groups)
            FilterChip(
              avatar: Icon(muscleGroupIcon(group)),
              label: Text(group),
              selected: _group == group,
              // Повторное нажатие на выбранную группу снимает фильтр.
              onSelected: (_) =>
                  setState(() => _group = _group == group ? null : group),
            ),
        ],
      ),
    );
  }
}
