import 'package:fittrack/data/mock_data.dart';
import 'package:fittrack/data/mock_exercise_repository.dart';
import 'package:fittrack/data/mock_network.dart';
import 'package:fittrack/data/mock_profile_repository.dart';
import 'package:fittrack/data/mock_workout_repository.dart';
import 'package:fittrack/data/result.dart';
import 'package:flutter_test/flutter_test.dart';

/// Значение Ok или провал теста с сообщением Err.
T _ok<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final msg) => fail('ожидался Ok, получен Err: $msg'),
};

String _err<T>(Result<T> result) => switch (result) {
  Ok() => fail('ожидался Err, получен Ok'),
  Err(:final msg) => msg,
};

WorkoutSession _draft({int minutes = 40}) => WorkoutSession(
  id: '',
  userId: '',
  date: DateTime(2026, 11, 24),
  exerciseIds: ['ex-01', 'ex-03'],
  durationMin: minutes,
  notes: 'черновик',
);

void main() {
  late MockNetwork network;
  late MockWorkoutRepository workouts;

  setUp(() {
    network = MockNetwork(latency: Duration.zero);
    workouts = MockWorkoutRepository(network);
  });

  group('MockWorkoutRepository', () {
    test('fetchAll отдаёт копию seed-а, а не внутренний список', () async {
      final first = _ok(await workouts.fetchAll());
      expect(first.map((s) => s.id), mockSessions.map((s) => s.id));

      first.clear();
      final second = _ok(await workouts.fetchAll());
      expect(second, hasLength(mockSessions.length));
    });

    test('fetchById: найденная сессия и Err для неизвестного id', () async {
      final session = _ok(await workouts.fetchById('ws-12'));
      expect(session.durationMin, 55);
      expect(_err(await workouts.fetchById('ws-404')), isNotEmpty);
    });

    test('create выдаёт уникальные id и владельца, список растёт', () async {
      final a = _ok(await workouts.create(_draft()));
      final b = _ok(await workouts.create(_draft()));

      expect(a.id, isNot(b.id));
      final seedIds = mockSessions.map((s) => s.id).toSet();
      expect(seedIds.contains(a.id) || seedIds.contains(b.id), isFalse);
      expect(a.userId, mockUserId);
      expect(a.exerciseIds, ['ex-01', 'ex-03']);
      expect(
        _ok(await workouts.fetchAll()),
        hasLength(mockSessions.length + 2),
      );
      // Общий seed не изменился: у каждого repository своя копия.
      expect(mockSessions, hasLength(13));
    });

    test('update заменяет по id; неизвестный id — Err без изменений', () async {
      final original = _ok(await workouts.fetchById('ws-13'));
      final changed = original.copyWith(durationMin: 99);

      expect(_ok(await workouts.update(changed)).durationMin, 99);
      expect(_ok(await workouts.fetchById('ws-13')).durationMin, 99);

      final ghost = changed.copyWith(id: 'ws-404');
      expect(_err(await workouts.update(ghost)), isNotEmpty);
      expect(_ok(await workouts.fetchAll()), hasLength(mockSessions.length));
    });

    test('delete убирает сессию; повторный delete — Err', () async {
      final result = await workouts.delete('ws-13');
      expect(result, isA<Ok<void>>());
      expect(_err(await workouts.fetchById('ws-13')), isNotEmpty);
      expect(_err(await workouts.delete('ws-13')), isNotEmpty);
      expect(
        _ok(await workouts.fetchAll()),
        hasLength(mockSessions.length - 1),
      );
    });

    test('авария: каждый метод возвращает Err и ничего не меняет', () async {
      network.simulateError = true;
      final session = mockSessions.first;

      for (final result in [
        await workouts.fetchAll(),
        await workouts.fetchById(session.id),
        await workouts.create(_draft()),
        await workouts.update(session.copyWith(durationMin: 1)),
        await workouts.delete(session.id),
      ]) {
        expect(_err(result), MockNetwork.errorMessage);
      }

      network.simulateError = false;
      final after = _ok(await workouts.fetchAll());
      expect(after, hasLength(mockSessions.length));
      expect(
        _ok(await workouts.fetchById(session.id)).durationMin,
        session.durationMin,
      );
    });
  });

  group('MockExerciseRepository и MockProfileRepository', () {
    test('каталог, упражнение по id, техника — копии seed-а', () async {
      final exercises = MockExerciseRepository(network);

      final all = _ok(await exercises.fetchAll());
      expect(all, hasLength(mockExercises.length));
      expect(_ok(await exercises.fetchById('ex-03')).name, 'Жим штанги лёжа');
      expect(_err(await exercises.fetchById('ex-404')), isNotEmpty);

      final steps = _ok(await exercises.fetchTechnique('ex-01'));
      expect(steps, exerciseTechnique['ex-01']);
      steps.clear();
      expect(exerciseTechnique['ex-01'], isNotEmpty);
      expect(_err(await exercises.fetchTechnique('ex-404')), isNotEmpty);
    });

    test('одна авария MockNetwork роняет все repositories', () async {
      final exercises = MockExerciseRepository(network);
      final profile = MockProfileRepository(network);
      expect(_ok(await profile.fetchProfile()).fullName, mockUser.fullName);

      network.simulateError = true;
      expect(_err(await exercises.fetchAll()), MockNetwork.errorMessage);
      expect(_err(await exercises.fetchById('ex-01')), isNotEmpty);
      expect(_err(await exercises.fetchTechnique('ex-01')), isNotEmpty);
      expect(_err(await profile.fetchProfile()), MockNetwork.errorMessage);
      expect(_err(await workouts.fetchAll()), MockNetwork.errorMessage);
    });
  });

  testWidgets('по умолчанию каждый метод отвечает через 800 мс', (
    tester,
  ) async {
    // testWidgets идёт на поддельных часах: задержку видно без ожидания.
    final slow = MockWorkoutRepository(MockNetwork());
    final calls = <String, Future<Object?>>{
      'fetchAll': slow.fetchAll(),
      'fetchById': slow.fetchById('ws-13'),
      'create': slow.create(_draft()),
      'update': slow.update(mockSessions.first),
      'delete': slow.delete('ws-12'),
      'profile': MockProfileRepository(MockNetwork()).fetchProfile(),
      'exercises': MockExerciseRepository(MockNetwork()).fetchAll(),
      'technique': MockExerciseRepository(MockNetwork())
          .fetchTechnique('ex-01'),
    };
    final done = <String>{};
    for (final MapEntry(:key, :value) in calls.entries) {
      value.then((_) => done.add(key));
    }

    await tester.pump(const Duration(milliseconds: 799));
    expect(done, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(done, calls.keys.toSet());
  });
}
