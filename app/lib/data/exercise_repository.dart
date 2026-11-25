import 'exercise.dart';
import 'result.dart';

/// Каталог упражнений только читается: пишущей формы упражнений в T2 нет.
abstract class ExerciseRepository {
  /// GET /exercises.
  Future<Result<List<Exercise>>> fetchAll();

  /// GET /exercises/{id}; нет такого — Err.
  Future<Result<Exercise>> fetchById(String id);

  /// Шаги техники выполнения упражнения [exerciseId].
  Future<Result<List<String>>> fetchTechnique(String exerciseId);
}
