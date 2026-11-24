import 'package:flutter/foundation.dart';

import '../data/workout_session.dart';

/// Разделяемое состояние дневника: его читают дневник, badge вкладки,
/// статистика и профиль. Чистый Dart — ни одного widget-а.
class WorkoutsModel extends ChangeNotifier {
  WorkoutsModel(Iterable<WorkoutSession> initial)
    : _sessions = _newestFirst(initial);

  /// Приватный список: изменить его можно только методами ниже,
  /// а каждый из них извещает подписчиков.
  List<WorkoutSession> _sessions;

  /// Наружу — только копия для чтения: `sessions.add(...)` бросит ошибку,
  /// а не тихо рассинхронизирует экраны.
  List<WorkoutSession> get sessions => List.unmodifiable(_sessions);

  int get count => _sessions.length;

  /// Сессия из текущего списка или null, если такой нет.
  WorkoutSession? byId(String id) =>
      _sessions.where((s) => s.id == id).firstOrNull;

  void add(WorkoutSession session) {
    _sessions = _newestFirst([session, ..._sessions]);
    notifyListeners();
  }

  void update(WorkoutSession session) {
    _sessions = _newestFirst([
      for (final s in _sessions) s.id == session.id ? session : s,
    ]);
    notifyListeners();
  }

  void remove(String id) {
    _sessions = _sessions.where((s) => s.id != id).toList();
    notifyListeners();
  }

  /// Сначала новые. При равной дате сохраняется исходный порядок: List.sort
  /// не гарантирует устойчивость, поэтому сравниваем ещё и позицию.
  static List<WorkoutSession> _newestFirst(Iterable<WorkoutSession> sessions) {
    final list = sessions.toList();
    final position = {for (var i = 0; i < list.length; i++) list[i]: i};
    list.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : position[a]!.compareTo(position[b]!);
    });
    return list;
  }
}
