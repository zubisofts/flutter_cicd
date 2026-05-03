import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../di/injection.dart';
import '../../services/theme_service.dart';
import '../../ui/execution/execution_bloc.dart';
import 'app_theme.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const AppShell({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _SideNav(currentPath: currentPath),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  final String currentPath;
  const _SideNav({required this.currentPath});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 220,
      color: cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Image.asset(
                  'assets/app_icon.png',
                  width: 28,
                  height: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  'FlutterCI',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _NavSection(label: 'PIPELINE'),
          _NavItem(
            icon: Icons.play_circle_outline,
            label: 'Setup & Run',
            route: '/setup',
            currentPath: currentPath,
          ),
          BlocBuilder<ExecutionBloc, ExecutionState>(
            bloc: getIt<ExecutionBloc>(),
            buildWhen: (prev, curr) => prev.phase != curr.phase,
            builder: (context, state) => _NavItem(
              icon: Icons.terminal,
              label: 'Execution',
              route: '/run',
              currentPath: currentPath,
              badge: state.phase == ExecutionPhase.running,
            ),
          ),
          const SizedBox(height: 8),
          _NavSection(label: 'RECORDS'),
          _NavItem(
            icon: Icons.history,
            label: 'Run History',
            route: '/history',
            currentPath: currentPath,
          ),
          const SizedBox(height: 8),
          _NavSection(label: 'CONFIG'),
          _NavItem(
            icon: Icons.settings,
            label: 'Settings',
            route: '/settings',
            currentPath: currentPath,
          ),
          const Spacer(),
          const Divider(),
          _ThemeSelector(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: Text(
              'FlutterCI v1.0',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: getIt<ThemeService>(),
      builder: (context, mode, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: Row(
            children: [
              Text(
                'Theme',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _ThemeBtn(
                icon: Icons.light_mode,
                label: 'Light',
                target: ThemeMode.light,
                current: mode,
              ),
              _ThemeBtn(
                icon: Icons.dark_mode,
                label: 'Dark',
                target: ThemeMode.dark,
                current: mode,
              ),
              _ThemeBtn(
                icon: Icons.desktop_mac,
                label: 'System',
                target: ThemeMode.system,
                current: mode,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeMode target;
  final ThemeMode current;

  const _ThemeBtn({
    required this.icon,
    required this.label,
    required this.target,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = current == target;
    return Tooltip(
      message: label,
      child: IconButton(
        icon: Icon(icon, size: 14),
        color: isActive
            ? AppTheme.colorRunning
            : Theme.of(context).colorScheme.onSurfaceVariant,
        onPressed: () => getIt<ThemeService>().setMode(target),
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(),
      ),
    );
  }
}

class _NavSection extends StatelessWidget {
  final String label;
  const _NavSection({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 10,
          letterSpacing: 1.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentPath;
  final bool badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentPath,
    this.badge = false,
  });

  bool get isActive => currentPath.startsWith(route);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.go(route),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? cs.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppTheme.colorRunning : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? cs.onSurface : cs.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (badge)
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppTheme.colorRunning,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
