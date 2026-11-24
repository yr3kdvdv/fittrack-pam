import '../data/workout_session.dart';

/// Итог одной недели для статистики.
class WeeklyStat {
  const WeeklyStat({
    required this.weekStart,
    required this.sessionCount,
    required this.totalMinutes,
  });

  /// Понедельник недели.
  final DateTime weekStart;
  final int sessionCount;
  final int totalMinutes;
}

/// Агрегаты дневника. Не хранятся, а считаются из актуального списка сессий:
/// после любой мутации статистика и профиль сразу согласованы с дневником.
class WorkoutStats {
  WorkoutStats._({
    required this.totalSessions,
    required this.totalMinutes,
    required List<WeeklyStat> weeks,
  }) : weeks = List.unmodifiable(weeks);

  factory WorkoutStats.fromSessions(Iterable<WorkoutSession> sessions) {
    final count = <DateTime, int>{};
    final minutes = <DateTime, int>{};
    var totalMinutes = 0;
    var totalSessions = 0;
    for (final session in sessions) {
      final monday = mondayOf(session.date);
      count[monday] = (count[monday] ?? 0) + 1;
      minutes[monday] = (minutes[monday] ?? 0) + session.durationMin;
      totalMinutes += session.durationMin;
      totalSessions++;
    }
    final mondays = count.keys.toList()..sort((a, b) => b.compareTo(a));
    return WorkoutStats._(
      totalSessions: totalSessions,
      totalMinutes: totalMinutes,
      weeks: [
        for (final monday in mondays)
          WeeklyStat(
            weekStart: monday,
            sessionCount: count[monday]!,
            totalMinutes: minutes[monday]!,
          ),
      ],
    );
  }

  final int totalSessions;
  final int totalMinutes;

  /// Только недели, в которых были тренировки, сначала новые.
  final List<WeeklyStat> weeks;

  /// Пустой дневник даёт 0, а не деление на ноль.
  int get averageMinutes =>
      totalSessions == 0 ? 0 : (totalMinutes / totalSessions).round();

  int get busiestWeekSessions =>
      weeks.fold(0, (best, w) => w.sessionCount > best ? w.sessionCount : best);

  int get longestWeekMinutes =>
      weeks.fold(0, (best, w) => w.totalMinutes > best ? w.totalMinutes : best);

  /// Понедельник недели даты. Конструктор с днём, а не subtract(Duration),
  /// чтобы не зависеть от перехода на летнее/зимнее время.
  static DateTime mondayOf(DateTime date) =>
      DateTime(date.year, date.month, date.day - (date.weekday - 1));
}
