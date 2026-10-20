# FitTrack

Личный дневник тренировок: каталог упражнений по группам мышц, история
тренировочных сессий, статистика и профиль. Учебный проект курса PAM, тема T2.

Текущий этап — L2: статический интерфейс Material 3 с зашитыми в код данными.
Сети, базы данных, проверки форм и сохранения на этом этапе нет.

## Запуск

Нужны Flutter 3.47+ (Dart 3.13+) и запущенный эмулятор Android или телефон
с включённой отладкой по USB.

```sh
cd app
flutter pub get
flutter devices      # убедиться, что устройство видно
flutter run
```

## Проверки

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Структура

- `lib/main.dart` — MaterialApp и тема.
- `lib/theme.dart` — ThemeData на основе ColorScheme.fromSeed.
- `lib/screens/` — экраны, по одному файлу на экран.
- `lib/widgets/` — переиспользуемые компоненты.
- `lib/data/` — общие модели и mock-данные.
