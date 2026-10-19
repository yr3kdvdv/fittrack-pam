// E2. Коллекции и функциональные методы.

double promotedAverage(List<int> grades) {
  // where ленивый: без toList фильтр заново проходил бы по оценкам
  // при каждом обращении (isEmpty, reduce, length).
  final passed = grades.where((g) => g >= 5).toList();

  // reduce на пустом списке бросает StateError, поэтому пустой случай
  // обрабатываем до него — заодно это требование ТЗ «вернуть 0».
  if (passed.isEmpty) return 0.0;

  final sum = passed.reduce((a, b) => a + b);

  // Оператор / в Dart всегда возвращает double, даже для двух int,
  // поэтому явное приведение типа не нужно.
  return sum / passed.length;
}

void main() {
  print(
    'promotedAverage([9, 4, 7, 10, 3, 5]) → '
    '${promotedAverage([9, 4, 7, 10, 3, 5])}',
  );
  print('promotedAverage([10, 10, 9]) → ${promotedAverage([10, 10, 9])}');
  print('promotedAverage([3, 4, 2]) → ${promotedAverage([3, 4, 2])}');
}
