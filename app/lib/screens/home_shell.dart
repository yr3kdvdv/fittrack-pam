import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
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
