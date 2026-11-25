import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'data/exercise_repository.dart';
import 'data/mock_exercise_repository.dart';
import 'data/mock_network.dart';
import 'data/mock_profile_repository.dart';
import 'data/mock_workout_repository.dart';
import 'data/profile_repository.dart';
import 'data/workout_repository.dart';
import 'models/exercises_model.dart';
import 'models/profile_model.dart';
import 'models/workouts_model.dart';
import 'router.dart';
import 'theme.dart';

/// Корень композиции: ЗДЕСЬ (и только здесь) выбирается источник данных.
/// На L5 mock-реализации заменятся http-реализациями тех же интерфейсов.
void main() {
  final network = MockNetwork();
  runApp(
    FitTrackProviders(
      network: network,
      workouts: MockWorkoutRepository(network),
      exercises: MockExerciseRepository(network),
      profile: MockProfileRepository(network),
      child: const FitTrackApp(),
    ),
  );
}

/// Модели над роутером: их видят все экраны всех вкладок.
/// Repositories приходят готовыми — тесты подставляют свои экземпляры.
class FitTrackProviders extends StatelessWidget {
  const FitTrackProviders({
    super.key,
    required this.network,
    required this.workouts,
    required this.exercises,
    required this.profile,
    required this.child,
  });

  /// Леса демонстрации аварии (выключатель в профиле) — исчезнут на L5.
  final MockNetwork network;
  final WorkoutRepository workouts;
  final ExerciseRepository exercises;
  final ProfileRepository profile;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Не ChangeNotifier и живёт всё приложение, поэтому .value.
        Provider<MockNetwork>.value(value: network),
        // Модели — фабрикой create: Provider создаёт их сам и сам вызовет
        // dispose; каскад ..load() начинает первую загрузку сразу.
        ChangeNotifierProvider(create: (_) => WorkoutsModel(workouts)..load()),
        ChangeNotifierProvider(
          create: (_) => ExercisesModel(exercises)..load(),
        ),
        ChangeNotifierProvider(create: (_) => ProfileModel(profile)..load()),
      ],
      child: child,
    );
  }
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
