import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Оболочка с нижней навигацией. Выбранная вкладка вычисляется из адреса,
/// поэтому собственного состояния у оболочки больше нет.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.location, required this.child});

  /// Текущий путь, например /exercises/ex-01.
  final String location;

  /// Экран текущего маршрута внутри оболочки.
  final Widget child;

  static const _tabPaths = ['/exercises', '/workouts', '/stats', '/profile'];

  int get _selectedIndex {
    final index = _tabPaths.indexWhere(location.startsWith);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        // go, а не push: вкладка заменяет текущий стек, а не копится поверх.
        onDestinationSelected: (index) => context.go(_tabPaths[index]),
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
