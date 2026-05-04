import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'di/injection.dart';
import 'engine/pipeline_runner.dart';
import 'services/theme_service.dart';
import 'ui/execution/execution_bloc.dart';
import 'ui/execution/execution_screen.dart';
import 'ui/history/history_screen.dart';
import 'ui/queue/queue_screen.dart';
import 'ui/settings/settings_screen.dart';
import 'ui/setup/setup_screen.dart';
import 'ui/shell/app_shell.dart';
import 'ui/shell/app_theme.dart';

// 100ms ease-in fade — feels near-instant but removes the hard visual cut
// when switching between screens with very different layouts.
const _kTransitionDuration = Duration(milliseconds: 100);

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: _kTransitionDuration,
      reverseTransitionDuration: _kTransitionDuration,
      transitionsBuilder: (context, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
        child: child,
      ),
    );

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
          pageBuilder: (context, state) => _fadePage(state, const SetupScreen()),
        ),
        GoRoute(
          path: '/run',
          pageBuilder: (context, state) {
            final newRequest = state.extra as RunRequest?;
            if (newRequest != null) {
              return _fadePage(
                  state, ExecutionScreen(request: newRequest, startRun: true));
            }
            final activeRequest = getIt<ExecutionBloc>().currentRequest;
            if (activeRequest != null) {
              return _fadePage(state,
                  ExecutionScreen(request: activeRequest, startRun: false));
            }
            return _fadePage(state, const SetupScreen());
          },
        ),
        GoRoute(
          path: '/queue',
          pageBuilder: (context, state) => _fadePage(state, const QueueScreen()),
        ),
        GoRoute(
          path: '/history',
          pageBuilder: (context, state) =>
              _fadePage(state, const HistoryScreen()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, String>?;
            return _fadePage(
              state,
              SettingsScreen(
                projectId: extra?['projectId'] ?? '',
                initialEnv: extra?['env'] ?? 'dev',
              ),
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
