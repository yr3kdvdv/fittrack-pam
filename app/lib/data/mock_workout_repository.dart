import 'mock_data.dart';
import 'mock_network.dart';
import 'result.dart';
import 'workout_repository.dart';
import 'workout_session.dart';

/// Тренировки в памяти, с повадками сети. Перезапуск приложения возвращает
/// seed: персистентности на L4 нет.
class MockWorkoutRepository implements WorkoutRepository {
  MockWorkoutRepository(this._network);

  final MockNetwork _network;

  /// Копия seed-а: изменения не трогают общий список mock_data.
  final List<WorkoutSession> _sessions = List.of(mockSessions);

  /// Выше любого номера seed-а (ws-01…ws-13).
  int _nextId = 1000;

  static const _errNotFound = 'Тренировка не существует';

  @override
  Future<Result<List<WorkoutSession>>> fetchAll() async {
    if (await _network.requestFails()) {
      return const Err(MockNetwork.errorMessage);
    }
    // Копия: внутренний список не отдаётся из рук.
    return Ok(List.of(_sessions));
  }

  @override
  Future<Result<WorkoutSession>> fetchById(String id) async {
    if (await _network.requestFails()) {
      return const Err(MockNetwork.errorMessage);
    }
    final index = _sessions.indexWhere((s) => s.id == id);
    if (index == -1) return const Err(_errNotFound);
    return Ok(_sessions[index]);
  }

  @override
  Future<Result<WorkoutSession>> create(WorkoutSession session) async {
    if (await _network.requestFails()) {
      return const Err(MockNetwork.errorMessage);
    }
    // Идентичность и владельца даёт хранилище (на L5 — сервер по JWT).
    final created = session.copyWith(id: 'ws-${_nextId++}', userId: mockUserId);
    _sessions.add(created);
    return Ok(created);
  }

  @override
  Future<Result<WorkoutSession>> update(WorkoutSession session) async {
    if (await _network.requestFails()) {
      return const Err(MockNetwork.errorMessage);
    }
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index == -1) return const Err(_errNotFound);
    _sessions[index] = session;
    return Ok(session);
  }

  @override
  Future<Result<void>> delete(String id) async {
    if (await _network.requestFails()) {
      return const Err(MockNetwork.errorMessage);
    }
    final index = _sessions.indexWhere((s) => s.id == id);
    if (index == -1) return const Err(_errNotFound);
    _sessions.removeAt(index);
    // «Удалил, отдать нечего» — 204 без тела.
    return const Ok(null);
  }
}
