# FitTrack

Учебный проект по дисциплине «Программирование мобильных приложений» (PAM).
Тема T2: дневник тренировок.

## L1

- `dart_exercises/` — упражнения E1–E6.
- `docs/EXPLAIN/L1.md` — пояснения и контрольные вопросы.
- `docs/L1/PAM_L1_FitTrack.pdf` — отчёт без титульного листа.
- `docs/L1/mini-spec.md` — спецификация будущего приложения.
- `docs/L1/FitTrack_mini_spec.pdf` — спецификация на одной странице.

Первый коммит этого репозитория публикует готовый комплект L1.
Текущая версия FitTrack описана в спецификации; реализация приложения начинается на L2.

## Проверка упражнений

Требуется Dart 3.9+; контрольный прогон выполнен на Dart 3.13.4.
cd dart_exercises
dart analyze .
dart format --output=none --set-exit-if-changed .
dart run e1_null_safety.dart
Остальные упражнения запускаются аналогично: e2_collections.dart,
e3_functions.dart, e4_classes.dart, e5_mixin.dart, e6_async.dart.
