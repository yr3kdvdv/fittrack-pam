import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'data/mock_data.dart';
import 'models/workouts_model.dart';
import 'router.dart';
import 'theme.dart';

void main() {
  runApp(
    // Модель над роутером: её видят все экраны всех вкладок. Фабрика create,
    // а не готовый экземпляр: Provider создаёт модель сам и сам вызовет dispose.
    ChangeNotifierProvider(
      create: (_) => WorkoutsModel(mockSessions),
      child: const FitTrackApp(),
    ),
  );
}

class FitTrackApp extends StatelessWidget {
  /// [router] передают только тесты; приложение использует общий [appRouter].
  const FitTrackApp({super.key, this.router});

  final GoRouter? router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FitTrack',
      debugShowCheckedModeBanner: false,
      theme: buildFitTrackTheme(),
      routerConfig: router ?? appRouter,
    );
  }
}
