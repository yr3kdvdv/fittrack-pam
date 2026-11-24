import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/workouts_model.dart';

/// Оболочка с нижней навигацией. Активную вкладку и стеки веток хранит
/// go_router, поэтому собственного состояния у оболочки нет.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  /// Ветки StatefulShellRoute; сам виджет показывает активную из них.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        // goBranch возвращает ветку в её последнее место: открытые детали
        // и прокрутка остаются. Повторный выбор активной вкладки тоже ничего
        // не сбрасывает, поэтому initialLocation не передаётся.
        onDestinationSelected: navigationShell.goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Упражнения',
          ),
          NavigationDestination(
            icon: _WorkoutsBadge(icon: Icons.event_note_outlined),
            selectedIcon: _WorkoutsBadge(icon: Icons.event_note),
            label: 'Дневник',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Статистика',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

/// Иконка вкладки «Дневник» с числом тренировок. Consumer перестраивает
/// только этот угол, а не всю оболочку: число меняется после мутации
/// на любом экране.
class _WorkoutsBadge extends StatelessWidget {
  const _WorkoutsBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutsModel>(
      builder: (context, workouts, child) => Badge.count(
        count: workouts.count,
        isLabelVisible: workouts.count > 0,
        child: child,
      ),
      // Иконка не зависит от модели и не пересоздаётся при извещении.
      child: Icon(icon),
    );
  }
}
