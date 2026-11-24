import 'package:fittrack/data/workout_session.dart';
import 'package:fittrack/models/workouts_model.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutSession _session(String id, DateTime date) => WorkoutSession(
  id: id,
  userId: 'user-01',
  date: date,
  exerciseIds: ['ex-01'],
  durationMin: 30,
  notes: '',
);

void main() {
  late WorkoutsModel model;
  late int notifications;

  setUp(() {
    model = WorkoutsModel([
      _session('a', DateTime(2026, 10, 1)),
      _session('b', DateTime(2026, 10, 3)),
    ]);
    notifications = 0;
    model.addListener(() => notifications++);
  });

  test('сессии отсортированы по дате, сначала новые', () {
    expect(model.sessions.map((s) => s.id), ['b', 'a']);
    expect(model.count, 2);
  });

  test('список и вложенные exerciseIds доступны только для чтения', () {
    expect(
      () => model.sessions.add(_session('x', DateTime(2026))),
      throwsUnsupportedError,
    );
    expect(
      () => model.sessions.first.exerciseIds.add('ex-02'),
      throwsUnsupportedError,
    );
    expect(model.count, 2);
    expect(notifications, 0);
  });

  test('add, update, remove меняют список и извещают каждый раз', () {
    model.add(_session('c', DateTime(2026, 10, 2)));
    expect(model.sessions.map((s) => s.id), ['b', 'c', 'a']);
    expect(notifications, 1);

    model.update(_session('a', DateTime(2026, 10, 5)));
    expect(model.sessions.map((s) => s.id), ['a', 'b', 'c']);
    expect(notifications, 2);

    model.remove('b');
    expect(model.sessions.map((s) => s.id), ['a', 'c']);
    expect(model.byId('b'), isNull);
    expect(notifications, 3);
  });
}
