import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'theme.dart';

void main() => runApp(const FitTrackApp());

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
