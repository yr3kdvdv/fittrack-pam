import 'package:fittrack/data/mock_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('упражнения', () {
    test('не меньше 8, идентификаторы уникальны', () {
      expect(mockExercises.length, greaterThanOrEqualTo(8));
      final ids = mockExercises.map((e) => e.id).toSet();
      expect(ids.length, mockExercises.length);
    });

    test('каждая группа мышц из фильтра используется и наоборот', () {
      final used = mockExercises.map((e) => e.muscleGroup).toSet();
      expect(used, muscleGroups.toSet());
    });

    test('есть длинное название для проверки переноса строк', () {
      expect(mockExercises.any((e) => e.name.length > 45), isTrue);
    });

    test('у каждого упражнения есть шаги техники', () {
      for (final exercise in mockExercises) {
        expect(exerciseTechnique[exercise.id], isNotEmpty, reason: exercise.id);
      }
      expect(exerciseTechnique.length, mockExercises.length);
    });
  });
}
