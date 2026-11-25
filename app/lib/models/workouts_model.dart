import 'package:flutter/foundation.dart';

import '../data/result.dart';
import '../data/workout_repository.dart';
import '../data/workout_session.dart';
import 'safe_notifier.dart';
import 'workout_stats.dart';

/// Разделяемое состояние дневника: его читают дневник, badge вкладки,
/// форма, статистика и профиль. Чистый Dart — ни одного widget-а.
class WorkoutsModel extends ChangeNotifier with SafeNotifier {
  /// Простой DI: хранилище приходит снаружи. Тип — интерфейс, модель не знает,
  /// mock это или backend.
  WorkoutsModel(this._repository);

  final WorkoutRepository _repository;

  bool _loading = false;
  String? _error;

  /// Приватный список: изменить его можно только методами ниже,
  /// а каждый из них извещает подписчиков.
  List<WorkoutSession> _sessions = const [];

  /// Счётчик успешных мутаций: по нему load узнаёт, что ответ устарел.
  int _mutations = 0;

  bool get isLoading => _loading;
  String? get error => _error;

  /// Наружу — только копия для чтения: `sessions.add(...)` бросит ошибку,
  /// а не тихо рассинхронизирует экраны.
  List<WorkoutSession> get sessions => List.unmodifiable(_sessions);

  int get count => _sessions.length;

  /// Агрегаты для статистики и профиля, из текущего списка.
  WorkoutStats get stats => WorkoutStats.fromSessions(_sessions);

  /// Сессия из загруженного списка или null, если её нет.
  WorkoutSession? byId(String id) =>
      _sessions.where((s) => s.id == id).firstOrNull;

  /// Загрузка с триадой: «грузится» → данные или ошибка. Повторный вызов
  /// во время загрузки ничего не делает: ответ уже в пути.
  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners(); // подписанные экраны входят в состояние «грузится»

    Result<List<WorkoutSession>> result;
    int mutationsBefore;
    do {
      mutationsBefore = _mutations;
      result = await _repository.fetchAll();
      if (isDisposed) return;
      // Пока список летел, другой экран успел создать/изменить/удалить
      // сессию. Ответ мог быть собран до этого и откатил бы мутацию,
      // поэтому спрашиваем ещё раз.
    } while (result is Ok && mutationsBefore != _mutations);

    switch (result) {
      case Ok(:final value):
        _sessions = _newestFirst(value);
      case Err(:final msg):
        _error = msg; // прежний список остаётся, экран покажет ошибку
    }
    _loading = false;
    notifyListeners(); // …и выходят: с данными или с ошибкой, никогда молча
  }

  /// Мутации возвращают null при успехе и сообщение при ошибке — как
  /// validator. При Err состояние не меняется, решает экран.
  Future<String?> add(WorkoutSession draft) async {
    switch (await _repository.create(draft)) {
      case Ok(:final value):
        // С id, полученным от хранилища.
        _apply([value, ..._sessions]);
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  Future<String?> update(WorkoutSession session) async {
    switch (await _repository.update(session)) {
      case Ok(:final value):
        // Замена на том же месте; если загрузка ещё не принесла эту
        // сессию, она просто добавляется.
        final known = _sessions.any((s) => s.id == value.id);
        _apply([
          for (final s in _sessions) s.id == value.id ? value : s,
          if (!known) value,
        ]);
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  Future<String?> remove(String id) async {
    switch (await _repository.delete(id)) {
      case Ok():
        _apply(_sessions.where((s) => s.id != id));
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  /// Общий хвост мутаций: новый список, отметка о мутации, весть всем.
  void _apply(Iterable<WorkoutSession> sessions) {
    _sessions = _newestFirst(sessions);
    _mutations++;
    notifyListeners(); // список, badge, статистика, профиль — узнают все
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
