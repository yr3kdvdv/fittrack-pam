/// Тренировка из дневника — главная сущность FitTrack.
class WorkoutSession {
  /// Конструктор не const: список упражнений копируется в неизменяемый,
  /// чтобы никто не мог поменять сессию в обход модели и Repository.
  WorkoutSession({
    required this.id,
    required this.userId,
    required this.date,
    required List<String> exerciseIds,
    required this.durationMin,
    required this.notes,
  }) : exerciseIds = List.unmodifiable(exerciseIds);

  final String id;
  final String userId;
  final DateTime date;

  /// Ссылки на упражнения каталога по id, как в модели backend.
  final List<String> exerciseIds;
  final int durationMin;
  final String notes;

  /// Та же тренировка с другими полями: id выдаёт хранилище при создании,
  /// форма меняет остальные поля при редактировании.
  WorkoutSession copyWith({
    String? id,
    String? userId,
    DateTime? date,
    List<String>? exerciseIds,
    int? durationMin,
    String? notes,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      durationMin: durationMin ?? this.durationMin,
      notes: notes ?? this.notes,
    );
  }
}
