import 'package:flutter/material.dart';

/// Seed-цвет домена: бирюзово-зелёный ассоциируется со спортом, здоровьем
/// и энергией, при этом он спокойный и не утомляет в ежедневном дневнике.
const Color fitTrackSeedColor = Color(0xFF00897B);

/// Единая тема приложения. Вся палитра выводится из одного seed-цвета,
/// поэтому экраны берут цвета только из Theme.of(context).colorScheme.
ThemeData buildFitTrackTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: fitTrackSeedColor),
    // Точечные подстройки типографики, остальное — по умолчанию Material 3.
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontWeight: FontWeight.w600),
    ),
    // Отступы между карточками задают сами списки, а не карточка.
    cardTheme: const CardThemeData(margin: EdgeInsets.zero),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
