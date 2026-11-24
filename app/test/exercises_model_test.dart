import 'package:fittrack/data/mock_data.dart';
import 'package:fittrack/data/mock_exercise_repository.dart';
import 'package:fittrack/data/mock_network.dart';
import 'package:fittrack/models/exercises_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockNetwork network;
  late ExercisesModel model;
  late int notifications;

  setUp(() {
    network = MockNetwork(latency: Duration.zero);
    model = ExercisesModel(MockExerciseRepository(network));
    notifications = 0;
    model.addListener(() => notifications++);
  });

  test('load: каталог, группы мышц из данных, byId', () async {
    expect(model.hasData, isFalse);
    await model.load();

    expect(notifications, 2);
    expect(model.hasData, isTrue);
    expect(model.exercises, hasLength(mockExercises.length));
    expect(model.muscleGroups, [
      'Ноги',
      'Грудь',
      'Спина',
      'Плечи',
      'Руки',
      'Пресс',
    ]);
    expect(model.byId('ex-03')!.name, 'Жим штанги лёжа');
    expect(model.byId('ex-404'), isNull);
  });

  test('коллекции только для чтения', () async {
    await model.load();
    expect(() => model.exercises.clear(), throwsUnsupportedError);
    expect(() => model.muscleGroups.add('Шея'), throwsUnsupportedError);
  });

  test('техника: своя триада по id, копия только для чтения', () async {
    expect(model.techniqueOf('ex-01'), isNull);
    network.simulateError = true;
    await model.loadTechnique('ex-01');
    expect(model.techniqueOf('ex-01'), isNull);
    expect(model.techniqueErrorOf('ex-01'), MockNetwork.errorMessage);

    network.simulateError = false;
    await model.loadTechnique('ex-01');
    expect(model.techniqueErrorOf('ex-01'), isNull);
    expect(model.techniqueOf('ex-01'), exerciseTechnique['ex-01']);
    expect(() => model.techniqueOf('ex-01')!.clear(), throwsUnsupportedError);
  });

  test('ошибка, затем retry; данные прошлой загрузки не теряются', () async {
    await model.load();
    network.simulateError = true;
    await model.load();
    expect(model.error, MockNetwork.errorMessage);
    expect(model.hasData, isTrue);

    network.simulateError = false;
    await model.load();
    expect(model.error, isNull);
    expect(model.exercises, hasLength(mockExercises.length));
  });
}
