import 'dart:async';

import 'package:fittrack/data/mock_data.dart';
import 'package:fittrack/data/mock_network.dart';
import 'package:fittrack/data/mock_workout_repository.dart';
import 'package:fittrack/data/result.dart';
import 'package:fittrack/data/workout_repository.dart';
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

/// Repository, ответами которого управляет тест: fetchAll ждёт complete.
class _ControlledRepository implements WorkoutRepository {
  final fetches = <Completer<Result<List<WorkoutSession>>>>[];
  final stored = <WorkoutSession>[];

  @override
  Future<Result<List<WorkoutSession>>> fetchAll() {
    final completer = Completer<Result<List<WorkoutSession>>>();
    fetches.add(completer);
    return completer.future;
  }

  @override
  Future<Result<WorkoutSession>> create(WorkoutSession session) async {
    final created = session.copyWith(id: 'new-${stored.length}');
    stored.add(created);
    return Ok(created);
  }

  @override
  Future<Result<WorkoutSession>> fetchById(String id) async =>
      const Err('не нужен');

  @override
  Future<Result<WorkoutSession>> update(WorkoutSession session) async =>
      Ok(session);

  @override
  Future<Result<void>> delete(String id) async => const Ok(null);
}

void main() {
  late MockNetwork network;
  late WorkoutsModel model;
  late int notifications;

  setUp(() async {
    network = MockNetwork(latency: Duration.zero);
    model = WorkoutsModel(MockWorkoutRepository(network));
    notifications = 0;
    model.addListener(() => notifications++);
  });

  test('load: «грузится», затем данные, отсортированные по дате', () async {
    final loading = model.load();
    expect(model.isLoading, isTrue);
    expect(notifications, 1);

    await loading;
    expect(model.isLoading, isFalse);
    expect(model.error, isNull);
    expect(notifications, 2);
    expect(model.count, mockSessions.length);
    for (var i = 1; i < model.count; i++) {
      expect(
        model.sessions[i - 1].date.isAfter(model.sessions[i].date),
        isTrue,
      );
    }
    expect(model.byId('ws-13'), isNotNull);
    expect(model.byId('ws-404'), isNull);
  });

  test('ошибка загрузки, затем retry приносит данные', () async {
    network.simulateError = true;
    await model.load();
    expect(model.error, MockNetwork.errorMessage);
    expect(model.isLoading, isFalse);
    expect(model.sessions, isEmpty);

    network.simulateError = false;
    await model.load();
    expect(model.error, isNull);
    expect(model.count, mockSessions.length);
  });

  test('повторный load во время загрузки не запускает второй запрос', () async {
    final repository = _ControlledRepository();
    final controlled = WorkoutsModel(repository);

    final first = controlled.load();
    unawaited(controlled.load());
    expect(repository.fetches, hasLength(1));

    repository.fetches.single.complete(Ok([_session('a', DateTime(2026))]));
    await first;
    expect(controlled.count, 1);
  });

  test('список и вложенные exerciseIds доступны только для чтения', () async {
    await model.load();
    notifications = 0;
    expect(
      () => model.sessions.add(_session('x', DateTime(2026))),
      throwsUnsupportedError,
    );
    expect(
      () => model.sessions.first.exerciseIds.add('ex-02'),
      throwsUnsupportedError,
    );
    expect(model.count, mockSessions.length);
    expect(notifications, 0);
  });

  test('add, update, remove: через repository, одна весть на успех', () async {
    await model.load();
    notifications = 0;

    final error = await model.add(_session('', DateTime(2026, 11, 24)));
    expect(error, isNull);
    expect(notifications, 1);
    expect(model.count, mockSessions.length + 1);
    final created = model.sessions.first;
    expect(created.id, startsWith('ws-'));
    expect(created.id, isNot(''));

    expect(await model.update(created.copyWith(durationMin: 77)), isNull);
    expect(model.byId(created.id)!.durationMin, 77);
    expect(notifications, 2);

    expect(await model.remove(created.id), isNull);
    expect(model.byId(created.id), isNull);
    expect(model.count, mockSessions.length);
    expect(notifications, 3);
  });

  test('ошибка мутации: сообщение, данные и подписчики нетронуты', () async {
    await model.load();
    notifications = 0;
    final before = model.sessions;
    network.simulateError = true;

    expect(
      await model.add(_session('', DateTime(2026))),
      MockNetwork.errorMessage,
    );
    expect(
      await model.update(before.first.copyWith(durationMin: 1)),
      MockNetwork.errorMessage,
    );
    expect(await model.remove(before.first.id), MockNetwork.errorMessage);

    expect(model.sessions, before);
    expect(model.byId(before.first.id)!.durationMin, before.first.durationMin);
    expect(notifications, 0);
  });

  test('неизвестный id в update/remove — Err, список не меняется', () async {
    await model.load();
    notifications = 0;

    expect(await model.update(_session('ws-404', DateTime(2026))), isNotNull);
    expect(await model.remove('ws-404'), isNotNull);
    expect(model.count, mockSessions.length);
    expect(notifications, 0);
  });

  test('ответ загрузки, устаревший из-за мутации, не откатывает её', () async {
    final repository = _ControlledRepository();
    final controlled = WorkoutsModel(repository);

    final loading = controlled.load();
    // Пока список в пути, другой экран добавляет тренировку.
    expect(await controlled.add(_session('', DateTime(2026, 11, 24))), isNull);
    expect(controlled.count, 1);

    // Старый ответ без новой записи: модель не верит ему и спрашивает снова.
    repository.fetches.first.complete(const Ok([]));
    await Future<void>.delayed(Duration.zero);
    expect(repository.fetches, hasLength(2));
    expect(controlled.isLoading, isTrue);

    repository.fetches.last.complete(Ok(List.of(repository.stored)));
    await loading;
    expect(controlled.count, 1);
    expect(controlled.isLoading, isFalse);
  });

  test('dispose во время запроса: поздний ответ не извещает', () async {
    final repository = _ControlledRepository();
    final controlled = WorkoutsModel(repository);

    final loading = controlled.load();
    controlled.dispose();
    repository.fetches.single.complete(const Ok([]));
    // Без защиты notifyListeners после dispose бросил бы FlutterError.
    await loading;
  });
}
