/// Общие mock-данные FitTrack. Поля моделей повторяют модель данных темы T2,
/// чтобы на L4/L5 их заменили данные Repository и backend без переделки экранов.
library;

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

  /// Путь к изображению на будущем сервере (L5). На L2 файлы не загружаются:
  /// вместо фотографии экраны показывают иконку группы мышц.
  final String imageUrl;
}

/// Группы мышц для фильтра каталога, в порядке показа.
const muscleGroups = ['Ноги', 'Грудь', 'Спина', 'Плечи', 'Руки', 'Пресс'];

const mockExercises = <Exercise>[
  Exercise(
    id: 'ex-01',
    name: 'Приседания со штангой на спине',
    muscleGroup: 'Ноги',
    description:
        'Базовое упражнение для квадрицепсов и ягодичных мышц. '
        'Развивает силу ног и укрепляет мышцы кора.',
    imageUrl: '/media/exercises/back-squat.jpg',
  ),
  Exercise(
    id: 'ex-02',
    name: 'Румынская тяга с гантелями на одной ноге с опорой о скамью',
    muscleGroup: 'Ноги',
    description:
        'Изолированно нагружает заднюю поверхность бедра и ягодицы, '
        'тренирует баланс и стабильность голеностопа.',
    imageUrl: '/media/exercises/single-leg-rdl.jpg',
  ),
  Exercise(
    id: 'ex-03',
    name: 'Жим штанги лёжа',
    muscleGroup: 'Грудь',
    description:
        'Основное упражнение для грудных мышц. Дополнительно работают '
        'передние дельты и трицепсы.',
    imageUrl: '/media/exercises/bench-press.jpg',
  ),
  Exercise(
    id: 'ex-04',
    name: 'Отжимания на брусьях',
    muscleGroup: 'Грудь',
    description:
        'Упражнение с собственным весом для нижней части груди и трицепсов. '
        'Наклон корпуса вперёд смещает нагрузку на грудь.',
    imageUrl: '/media/exercises/dips.jpg',
  ),
  Exercise(
    id: 'ex-05',
    name: 'Подтягивания широким хватом',
    muscleGroup: 'Спина',
    description:
        'Развивают широчайшие мышцы спины и делают силуэт шире. '
        'Хороший показатель относительной силы.',
    imageUrl: '/media/exercises/pull-ups.jpg',
  ),
  Exercise(
    id: 'ex-06',
    name: 'Тяга штанги в наклоне',
    muscleGroup: 'Спина',
    description:
        'Прорабатывает середину спины и задние дельты, '
        'укрепляет разгибатели позвоночника.',
    imageUrl: '/media/exercises/barbell-row.jpg',
  ),
  Exercise(
    id: 'ex-07',
    name: 'Жим гантелей сидя',
    muscleGroup: 'Плечи',
    description:
        'Нагружает передние и средние пучки дельтовидных мышц. '
        'Спинка скамьи снижает нагрузку на поясницу.',
    imageUrl: '/media/exercises/seated-db-press.jpg',
  ),
  Exercise(
    id: 'ex-08',
    name: 'Подъём штанги на бицепс стоя',
    muscleGroup: 'Руки',
    description:
        'Классическое упражнение для двуглавой мышцы плеча. '
        'Важно не раскачивать корпус.',
    imageUrl: '/media/exercises/barbell-curl.jpg',
  ),
  Exercise(
    id: 'ex-09',
    name: 'Французский жим лёжа',
    muscleGroup: 'Руки',
    description:
        'Изолированное упражнение для трицепса, особенно его длинной головки.',
    imageUrl: '/media/exercises/skull-crusher.jpg',
  ),
  Exercise(
    id: 'ex-10',
    name: 'Планка на предплечьях',
    muscleGroup: 'Пресс',
    description:
        'Статическое упражнение для мышц кора: укрепляет пресс, '
        'поясницу и учит держать корпус ровным.',
    imageUrl: '/media/exercises/plank.jpg',
  ),
];
