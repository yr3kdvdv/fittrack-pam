import 'package:go_router/go_router.dart';

import 'screens/exercise_detail_screen.dart';
import 'screens/exercises_screen.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/workout_edit_screen.dart';
import 'screens/workouts_screen.dart';

/// Единственный роутер приложения. Создаётся один раз при первом обращении,
/// а не в build: иначе каждая перестройка FitTrackApp сбрасывала бы стек.
final appRouter = createRouter();

/// Фабрика карты маршрутов. Отдельный экземпляр нужен тестам, чтобы каждый
/// тест начинал с чистого стека и мог сразу открыть любой адрес.
GoRouter createRouter({String initialLocation = '/login'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      // Вход вне оболочки: на нём нет нижней панели.
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      // Промежуточное решение: общая панель для всех вкладок. Независимые
      // стеки вкладок (StatefulShellRoute) — следующий шаг L3.
      ShellRoute(
        builder: (context, state, child) =>
            HomeShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/exercises',
            builder: (context, state) => const ExercisesScreen(),
            routes: [
              GoRoute(
                path: ':id',
                // В адресе только id; экран сам находит упражнение в mock.
                builder: (context, state) => ExerciseDetailScreen(
                  exerciseId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/workouts',
            builder: (context, state) => const WorkoutsScreen(),
            routes: [
              // new — отдельный адрес: редактирование требует сегмент /edit,
              // поэтому «new» никогда не попадает в параметр id сессии.
              GoRoute(
                path: 'new',
                builder: (context, state) => const WorkoutEditScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) =>
                    WorkoutEditScreen(sessionId: state.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
            path: '/stats',
            builder: (context, state) => const StatsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
