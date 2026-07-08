import 'package:go_router/go_router.dart';
import '../../ui/presentation/screens/splash_screen.dart';
import '../../ui/presentation/screens/main_menu_screen.dart';
import '../../ui/presentation/screens/level_select_screen.dart';
import '../../ui/presentation/screens/game_play_screen.dart';
import '../../ui/presentation/screens/settings_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/menu',
      builder: (context, state) => const MainMenuScreen(),
    ),
    GoRoute(
      path: '/levels',
      builder: (context, state) => const LevelSelectScreen(),
    ),
    GoRoute(
      path: '/game/:levelId',
      builder: (context, state) {
        final levelIdStr = state.pathParameters['levelId'] ?? '1';
        final levelId = int.tryParse(levelIdStr) ?? 1;
        return GamePlayScreen(levelId: levelId);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
