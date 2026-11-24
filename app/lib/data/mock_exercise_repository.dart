import 'exercise_repository.dart';
import 'mock_data.dart';
import 'mock_network.dart';
import 'result.dart';

/// Каталог и техника упражнений из seed-а, с задержкой и общей аварией.
class MockExerciseRepository implements ExerciseRepository {
  MockExerciseRepository(this._network);

  final MockNetwork _network;

  static const _errNotFound = 'Упражнение не существует';

  @override
  Future<Result<List<Exercise>>> fetchAll() async {
    if (await _network.requestFails()) {
      return const Err(MockNetwork.errorMessage);
    }
    return Ok(List.of(mockExercises));
  }

  @override
  Future<Result<Exercise>> fetchById(String id) async {
    if (await _network.requestFails()) {
      return const Err(MockNetwork.errorMessage);
    }
    final exercise = mockExercises.where((e) => e.id == id).firstOrNull;
    return exercise == null ? const Err(_errNotFound) : Ok(exercise);
  }

  @override
  Future<Result<List<String>>> fetchTechnique(String exerciseId) async {
    if (await _network.requestFails()) {
      return const Err(MockNetwork.errorMessage);
    }
    final steps = exerciseTechnique[exerciseId];
    return steps == null ? const Err(_errNotFound) : Ok(List.of(steps));
  }
}
