import 'package:flutter/foundation.dart';

import '../data/exercise.dart';
import '../data/exercise_repository.dart';
import '../data/result.dart';
import 'safe_notifier.dart';

/// Каталог упражнений: его читают каталог, детали, форма и карточки дневника.
/// Только чтение — пишущей формы упражнений в T2 нет.
class ExercisesModel extends ChangeNotifier with SafeNotifier {
  ExercisesModel(this._repository);

  final ExerciseRepository _repository;

  bool _loading = false;
  String? _error;
  List<Exercise> _exercises = const [];

  /// Был ли хоть один успешный ответ. Форме этого достаточно, чтобы
  /// показывать список при последующих перезагрузках.
  bool _loaded = false;

  bool get isLoading => _loading;
  String? get error => _error;
  bool get hasData => _loaded;
  List<Exercise> get exercises => List.unmodifiable(_exercises);

  /// Группы мышц для фильтра — из загруженного каталога, в порядке первого
  /// появления: отдельного захардкоженного списка в UI нет.
  List<String> get muscleGroups =>
      List.unmodifiable(_exercises.map((e) => e.muscleGroup).toSet());

  Exercise? byId(String id) => _exercises.where((e) => e.id == id).firstOrNull;

  // Техника грузится отдельно, по одному упражнению: в модели темы её нет,
  // и каталогу она не нужна. Своя триада на каждый id.
  final Map<String, List<String>> _techniques = {};
  final Map<String, String> _techniqueErrors = {};
  final Set<String> _techniqueLoading = {};

  /// Шаги техники или null, если они ещё не загружены.
  List<String>? techniqueOf(String id) {
    final steps = _techniques[id];
    return steps == null ? null : List.unmodifiable(steps);
  }

  String? techniqueErrorOf(String id) => _techniqueErrors[id];

  Future<void> loadTechnique(String id) async {
    if (_techniqueLoading.contains(id)) return;
    _techniqueLoading.add(id);
    _techniqueErrors.remove(id);
    notifyListeners();

    final result = await _repository.fetchTechnique(id);
    if (isDisposed) return;
    switch (result) {
      case Ok(:final value):
        _techniques[id] = value;
      case Err(:final msg):
        _techniqueErrors[id] = msg;
    }
    _techniqueLoading.remove(id);
    notifyListeners();
  }

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.fetchAll();
    if (isDisposed) return;
    switch (result) {
      case Ok(:final value):
        _exercises = value;
        _loaded = true;
      case Err(:final msg):
        _error = msg;
    }
    _loading = false;
    notifyListeners();
  }
}
