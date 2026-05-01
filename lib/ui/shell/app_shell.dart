import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../di/injection.dart';
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
    return Container(
      width: 220,
      color: const Color(0xFF0D1117),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.colorRunning,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.rocket_launch,
                      size: 16, color: Colors.black),
                ),
                const SizedBox(width: 10),
                const Text(
                  'FlutterCI',
                  style: TextStyle(
                    color: Color(0xFFE6EDF3),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'FlutterCI v1.0',
              style: TextStyle(
                color: const Color(0xFF8B949E),
                fontSize: 11,
              ),
            ),
          ),
        ],
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
        style: const TextStyle(
          color: Color(0xFF8B949E),
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
    return InkWell(
      onTap: () => context.go(route),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF21262D) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? AppTheme.colorRunning
                  : const Color(0xFF8B949E),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFFE6EDF3)
                      : const Color(0xFF8B949E),
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
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
