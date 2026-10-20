/// Русские подписи дат и длительности. Написаны вручную, чтобы не добавлять
/// пакет intl ради нескольких строк статического макета.
library;

const _weekdays = [
  'Понедельник',
  'Вторник',
  'Среда',
  'Четверг',
  'Пятница',
  'Суббота',
  'Воскресенье',
];

const _monthsGenitive = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

/// «Суббота, 17 октября».
String formatLongDate(DateTime date) =>
    '${_weekdays[date.weekday - 1]}, ${date.day} ${_monthsGenitive[date.month - 1]}';

const _monthsShort = [
  'янв.',
  'февр.',
  'марта',
  'апр.',
  'мая',
  'июня',
  'июля',
  'авг.',
  'сент.',
  'окт.',
  'нояб.',
  'дек.',
];

/// «12–18 окт.» или «28 сент. – 4 окт.», если неделя переходит в другой месяц.
String formatWeekRange(DateTime monday) {
  // Конструктор с днём + 6, а не add(Duration), чтобы не зависеть от перехода
  // на летнее/зимнее время.
  final sunday = DateTime(monday.year, monday.month, monday.day + 6);
  final endMonth = _monthsShort[sunday.month - 1];
  if (monday.month == sunday.month) {
    return '${monday.day}–${sunday.day} $endMonth';
  }
  return '${monday.day} ${_monthsShort[monday.month - 1]} – ${sunday.day} $endMonth';
}

/// «17.10.2026».
String formatNumericDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

/// «45 мин», «1 ч 15 мин», «12 ч».
String formatDuration(int minutes) {
  if (minutes < 60) return '$minutes мин';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '$hours ч' : '$hours ч $rest мин';
}
