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

  group('тренировки', () {
    test('не меньше 8, идентификаторы уникальны, один пользователь', () {
      expect(mockSessions.length, greaterThanOrEqualTo(8));
      expect(mockSessions.map((s) => s.id).toSet().length, mockSessions.length);
      expect(mockSessions.every((s) => s.userId == mockUserId), isTrue);
    });

    test('ссылаются только на упражнения из каталога', () {
      final ids = mockExercises.map((e) => e.id).toSet();
      for (final session in mockSessions) {
        expect(session.exerciseIds, isNotEmpty, reason: session.id);
        expect(
          ids.containsAll(session.exerciseIds),
          isTrue,
          reason: session.id,
        );
        expect(session.durationMin, greaterThan(0), reason: session.id);
      }
    });

    test('упорядочены по дате, сначала новые', () {
      for (var i = 1; i < mockSessions.length; i++) {
        expect(
          mockSessions[i - 1].date.isAfter(mockSessions[i].date),
          isTrue,
          reason: '${mockSessions[i - 1].id} → ${mockSessions[i].id}',
        );
      }
    });
  });
}
