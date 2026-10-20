import 'package:flutter/material.dart';

import 'theme.dart';

void main() => runApp(const FitTrackApp());

class FitTrackApp extends StatelessWidget {
  const FitTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTrack',
      debugShowCheckedModeBanner: false,
      theme: buildFitTrackTheme(),
      home: const _StartPreview(),
    );
  }
}

/// Временный стартовый экран: показывает применённую тему, пока не готов вход.
class _StartPreview extends StatelessWidget {
  const _StartPreview();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('FitTrack')),
      body: Center(
        child: Icon(Icons.fitness_center, size: 64, color: colorScheme.primary),
      ),
    );
  }
}
