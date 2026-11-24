/// Упражнение каталога. Поля повторяют модель данных темы T2: файл переживёт
/// mock и перейдёт на L5 без изменений.
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.description,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String muscleGroup;
  final String description;

  /// Путь к изображению на будущем сервере (L5). Файлы не загружаются:
  /// вместо фотографии экраны показывают иконку группы мышц.
  final String imageUrl;
}
