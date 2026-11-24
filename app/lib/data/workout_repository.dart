import 'result.dart';
import 'workout_session.dart';

/// Контракт хранилища тренировок: ЧТО можно просить, а не КАК.
/// На L5 каждый метод станет одним REST-запросом к backend-у.
abstract class WorkoutRepository {
  /// GET /sessions.
  Future<Result<List<WorkoutSession>>> fetchAll();

  /// GET /sessions/{id}; нет такой — Err («404»).
  Future<Result<WorkoutSession>> fetchById(String id);

  /// POST /sessions; id новой сессии выдаёт хранилище, а не экран.
  Future<Result<WorkoutSession>> create(WorkoutSession session);

  /// PUT /sessions/{id}: заменяет сессию с тем же id.
  Future<Result<WorkoutSession>> update(WorkoutSession session);

  /// DELETE /sessions/{id}: 204 без тела, поэтому `Result<void>`.
  Future<Result<void>> delete(String id);
}
