import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'di/injection.dart';
import 'engine/pipeline_runner.dart';
import 'services/theme_service.dart';
import 'ui/execution/execution_bloc.dart';
import 'ui/execution/execution_screen.dart';
import 'ui/history/history_screen.dart';
import 'ui/settings/settings_screen.dart';
import 'ui/setup/setup_screen.dart';
import 'ui/shell/app_shell.dart';
import 'ui/shell/app_theme.dart';

final _router = GoRouter(
  initialLocation: '/setup',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(
        currentPath: state.uri.path,
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/setup',
          builder: (context, state) => const SetupScreen(),
        ),
        GoRoute(
          path: '/run',
          builder: (context, state) {
            final newRequest = state.extra as RunRequest?;
            if (newRequest != null) {
              // Fresh run triggered from SetupScreen
              return ExecutionScreen(request: newRequest, startRun: true);
            }
            // Re-attach: nav item clicked while a run is active/completed
            final activeRequest = getIt<ExecutionBloc>().currentRequest;
            if (activeRequest != null) {
              return ExecutionScreen(request: activeRequest, startRun: false);
            }
            return const SetupScreen();
          },
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) {
            final extra = state.extra as Map<String, String>?;
            return SettingsScreen(
              projectId: extra?['projectId'] ?? '',
              initialEnv: extra?['env'] ?? 'dev',
            );
          },
        ),
      ],
    ),
  ],
);

class CicdApp extends StatelessWidget {
  const CicdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: getIt<ThemeService>(),
      builder: (context, mode, child) => MaterialApp.router(
        title: 'FlutterCI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        routerConfig: _router,
      ),
    );
  }
}
