// E4. Классы.

class Student {
  final String name;
  final String group;

  Student(this.name, this.group);

  // Перенаправляем в основной конструктор, чтобы логика создания
  // была в одном месте, а guest() только задавал значения.
  Student.guest() : this('Guest', '—');

  @override
  String toString() => 'Student($name, $group)';

  // По умолчанию == сравнивает ссылки (один и тот же объект в памяти),
  // а нам нужно равенство по содержимому.
  @override
  bool operator ==(Object other) =>
      other is Student && other.name == name && other.group == group;

  // Set и Map сначала сравнивают hashCode, и только при совпадении
  // вызывают ==. Равные объекты обязаны иметь одинаковый hashCode,
  // поэтому считаем его из тех же полей, что участвуют в ==.
  @override
  int get hashCode => Object.hash(name, group);
}

void main() {
  print(Student('Ana Rusu', 'TI-231'));
  print(Student.guest());
  print(
    "Student('Ana Rusu', 'TI-231') == Student('Ana Rusu', 'TI-231') → "
    '${Student('Ana Rusu', 'TI-231') == Student('Ana Rusu', 'TI-231')}',
  );
  print(
    "{Student('Ana Rusu', 'TI-231'), Student('Ana Rusu', 'TI-231')}.length → "
    '${{Student('Ana Rusu', 'TI-231'), Student('Ana Rusu', 'TI-231')}.length}',
  );
}
