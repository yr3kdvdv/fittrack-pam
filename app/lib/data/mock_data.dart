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

class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.userId,
    required this.date,
    required this.exerciseIds,
    required this.durationMin,
    required this.notes,
  });

  final String id;
  final String userId;
  final DateTime date;

  /// Ссылки на упражнения каталога по id, как в модели backend.
  final List<String> exerciseIds;
  final int durationMin;
  final String notes;
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

Exercise exerciseById(String id) =>
    mockExercises.firstWhere((exercise) => exercise.id == id);

const mockUserId = 'user-01';

/// Демонстрационная «сегодняшняя» дата — конец периода mock-данных.
/// Зашита, а не DateTime.now(), чтобы макет выглядел одинаково в любой день.
final mockToday = DateTime(2026, 10, 18);

/// Тренировки за шесть недель (7 сентября — 18 октября 2026), сначала новые.
/// DateTime не бывает const, поэтому список final.
final mockSessions = <WorkoutSession>[
  WorkoutSession(
    id: 'ws-13',
    userId: mockUserId,
    date: DateTime(2026, 10, 17),
    exerciseIds: ['ex-05', 'ex-06', 'ex-08'],
    durationMin: 50,
    notes: 'Подтягивания 4×8, последний подход дался тяжело.',
  ),
  WorkoutSession(
    id: 'ws-12',
    userId: mockUserId,
    date: DateTime(2026, 10, 15),
    exerciseIds: ['ex-03', 'ex-04', 'ex-09'],
    durationMin: 55,
    notes: 'Жим лёжа 4×6 по 70 кг — новый рабочий вес.',
  ),
  WorkoutSession(
    id: 'ws-11',
    userId: mockUserId,
    date: DateTime(2026, 10, 13),
    exerciseIds: ['ex-01', 'ex-02', 'ex-10'],
    durationMin: 75,
    notes:
        'Присед 5×5 по 80 кг. В румынской тяге следить, '
        'чтобы колено опорной ноги не уходило внутрь.',
  ),
  WorkoutSession(
    id: 'ws-10',
    userId: mockUserId,
    date: DateTime(2026, 10, 9),
    exerciseIds: ['ex-07', 'ex-08', 'ex-09'],
    durationMin: 60,
    notes: 'Плечи и руки, отдых между подходами не больше минуты.',
  ),
  WorkoutSession(
    id: 'ws-09',
    userId: mockUserId,
    date: DateTime(2026, 10, 6),
    exerciseIds: ['ex-01', 'ex-10'],
    durationMin: 45,
    notes: 'Лёгкая тренировка после пропуска, техника без спешки.',
  ),
  WorkoutSession(
    id: 'ws-08',
    userId: mockUserId,
    date: DateTime(2026, 10, 2),
    exerciseIds: ['ex-03', 'ex-05', 'ex-06'],
    durationMin: 70,
    notes: 'Верх тела: жим 4×8 по 65 кг, тяга в наклоне 4×10.',
  ),
  WorkoutSession(
    id: 'ws-07',
    userId: mockUserId,
    date: DateTime(2026, 9, 29),
    exerciseIds: ['ex-01', 'ex-02'],
    durationMin: 50,
    notes: 'Ноги. Присед 5×5 по 77,5 кг.',
  ),
  WorkoutSession(
    id: 'ws-06',
    userId: mockUserId,
    date: DateTime(2026, 9, 26),
    exerciseIds: ['ex-04', 'ex-07', 'ex-09'],
    durationMin: 65,
    notes: 'Брусья с дополнительным весом 5 кг.',
  ),
  WorkoutSession(
    id: 'ws-05',
    userId: mockUserId,
    date: DateTime(2026, 9, 24),
    exerciseIds: ['ex-05', 'ex-10'],
    durationMin: 40,
    notes: 'Подтягивания и кор, в конце растяжка.',
  ),
  WorkoutSession(
    id: 'ws-04',
    userId: mockUserId,
    date: DateTime(2026, 9, 22),
    exerciseIds: ['ex-03', 'ex-08'],
    durationMin: 55,
    notes: 'Жим лёжа 5×5 по 62,5 кг.',
  ),
  WorkoutSession(
    id: 'ws-03',
    userId: mockUserId,
    date: DateTime(2026, 9, 15),
    exerciseIds: ['ex-01', 'ex-06', 'ex-10'],
    durationMin: 60,
    notes: 'После простуды — одна тренировка за неделю.',
  ),
  WorkoutSession(
    id: 'ws-02',
    userId: mockUserId,
    date: DateTime(2026, 9, 11),
    exerciseIds: ['ex-03', 'ex-04', 'ex-07'],
    durationMin: 45,
    notes: 'Первая неделя новой программы, веса умеренные.',
  ),
  WorkoutSession(
    id: 'ws-01',
    userId: mockUserId,
    date: DateTime(2026, 9, 8),
    exerciseIds: ['ex-01', 'ex-05'],
    durationMin: 50,
    notes: 'Знакомство с программой, подбор рабочих весов.',
  ),
];

/// Профиль пользователя. На L5 часть полей придёт из аутентификации шаблона.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    required this.weeklyTarget,
  });

  final String id;
  final String fullName;
  final String email;
  final int age;
  final int heightCm;
  final double weightKg;
  final String goal;

  /// Сколько тренировок в неделю пользователь планирует.
  final int weeklyTarget;
}

const mockUser = UserProfile(
  id: mockUserId,
  fullName: 'Анна Чебан',
  email: 'anna.ceban@example.com',
  age: 21,
  heightCm: 168,
  weightKg: 59.5,
  goal: 'Набрать силу и подтянуть выносливость к весенним соревнованиям',
  weeklyTarget: 3,
);

/// Итог одной недели для статистики.
class WeeklyStat {
  const WeeklyStat({
    required this.weekStart,
    required this.sessionCount,
    required this.totalMinutes,
  });

  /// Понедельник недели.
  final DateTime weekStart;
  final int sessionCount;
  final int totalMinutes;
}

/// Зашитые итоги по неделям, сначала новые. На L2 они не вычисляются в UI;
/// совпадение с mockSessions проверяет test/mock_data_test.dart.
final mockWeeklyStats = <WeeklyStat>[
  WeeklyStat(
    weekStart: DateTime(2026, 10, 12),
    sessionCount: 3,
    totalMinutes: 180,
  ),
  WeeklyStat(
    weekStart: DateTime(2026, 10, 5),
    sessionCount: 2,
    totalMinutes: 105,
  ),
  WeeklyStat(
    weekStart: DateTime(2026, 9, 28),
    sessionCount: 2,
    totalMinutes: 120,
  ),
  WeeklyStat(
    weekStart: DateTime(2026, 9, 21),
    sessionCount: 3,
    totalMinutes: 160,
  ),
  WeeklyStat(
    weekStart: DateTime(2026, 9, 14),
    sessionCount: 1,
    totalMinutes: 60,
  ),
  WeeklyStat(
    weekStart: DateTime(2026, 9, 7),
    sessionCount: 2,
    totalMinutes: 95,
  ),
];

/// Общие итоги за весь период, тоже зашитые и проверяемые тестом.
const mockTotalSessions = 13;
const mockTotalMinutes = 720;

/// Шаги техники по id упражнения. В модели темы техники нет, поэтому она
/// хранится отдельно и не расширяет Exercise сверх модели backend.
const exerciseTechnique = <String, List<String>>{
  'ex-01': [
    'Положите гриф на верх трапеций, стопы на ширине плеч.',
    'Сделайте вдох, отведите таз назад и опуститесь до параллели бёдер с полом.',
    'Колени направляйте по линии носков, спина остаётся прямой.',
    'Поднимитесь, отталкиваясь всей стопой, выдох в верхней точке.',
  ],
  'ex-02': [
    'Встаньте боком к скамье и обопритесь на неё свободной рукой.',
    'Перенесите вес на опорную ногу, колено слегка согнуто.',
    'Наклоняйтесь с прямой спиной, отводя свободную ногу назад.',
    'Опустите гантель до середины голени и вернитесь в исходное положение.',
  ],
  'ex-03': [
    'Лягте на скамью, сведите лопатки и упритесь стопами в пол.',
    'Возьмите гриф чуть шире плеч и снимите его со стоек.',
    'Опустите штангу к нижней части груди, локти под углом около 45°.',
    'Выжмите гриф вверх до выпрямления рук.',
  ],
  'ex-04': [
    'Упритесь в брусья на прямых руках, плечи опущены.',
    'Наклоните корпус немного вперёд.',
    'Опуститесь до угла 90° в локтях.',
    'Выжмите тело вверх, не выпрямляя локти до щелчка.',
  ],
  'ex-05': [
    'Возьмитесь за перекладину хватом шире плеч.',
    'Сведите лопатки и потяните грудь к перекладине.',
    'Поднимитесь, пока подбородок не окажется выше перекладины.',
    'Медленно опуститесь до полного выпрямления рук.',
  ],
  'ex-06': [
    'Наклонитесь вперёд почти до параллели с полом, спина прямая.',
    'Держите штангу на прямых руках хватом на ширине плеч.',
    'Тяните гриф к поясу, сводя лопатки.',
    'Опустите штангу под контролем.',
  ],
  'ex-07': [
    'Сядьте на скамью с вертикальной спинкой, гантели у плеч.',
    'Выжмите гантели вверх, не соударяя их в верхней точке.',
    'Опустите гантели до уровня ушей.',
  ],
  'ex-08': [
    'Встаньте прямо, возьмите штангу хватом снизу на ширине плеч.',
    'Прижмите локти к корпусу.',
    'Согните руки, поднимая штангу к груди без раскачки.',
    'Медленно опустите штангу до почти прямых рук.',
  ],
  'ex-09': [
    'Лягте на скамью, держите штангу над грудью на прямых руках.',
    'Сгибайте руки только в локтях, опуская гриф ко лбу.',
    'Локти направлены вверх и не разводятся в стороны.',
    'Разогните руки за счёт трицепса.',
  ],
  'ex-10': [
    'Упритесь предплечьями в пол, локти под плечами.',
    'Выпрямите тело в одну линию от головы до пяток.',
    'Напрягите пресс и ягодицы, не прогибайтесь в пояснице.',
    'Удерживайте положение 30–60 секунд, дыша ровно.',
  ],
};
