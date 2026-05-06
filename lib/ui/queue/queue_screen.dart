import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../di/injection.dart';
import '../../engine/build_queue.dart';
import '../../engine/pipeline_runner.dart';
import '../execution/widgets/log_viewer.dart';
import '../execution/widgets/step_progress_list.dart';
import '../shell/app_theme.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  String? _selectedBuildId;
  bool _detailVisible = false;
  // Tracks build IDs we've already seen so we can detect newly enqueued builds
  // and auto-select them without disturbing the current selection logic.
  Set<String> _knownBuildIds = {};
  bool _initialized = false;

  static const _narrowBreakpoint = 700.0;
  static const _listWidth = 280.0;

  @override
  Widget build(BuildContext context) {
    final queue = getIt<BuildQueue>();
    return StreamBuilder<List<ActiveBuild>>(
      stream: queue.stream,
      initialData: queue.builds,
      builder: (context, snapshot) {
        final builds = snapshot.data ?? queue.builds;

        if (!_initialized && builds.isNotEmpty) {
          // First non-empty render — seed known IDs and select the first build.
          _initialized = true;
          _selectedBuildId ??= builds.first.id;
          _knownBuildIds = builds.map((b) => b.id).toSet();
        } else if (_initialized) {
          // On subsequent emissions, auto-select any build that just appeared.
          final newBuild =
              builds.where((b) => !_knownBuildIds.contains(b.id)).firstOrNull;
          if (newBuild != null) {
            _selectedBuildId = newBuild.id;
            _detailVisible = true; // show detail immediately on narrow layout
          }
          _knownBuildIds = builds.map((b) => b.id).toSet();
        }

        final selected = builds.isEmpty
            ? null
            : builds.firstWhere(
                (b) => b.id == _selectedBuildId,
                orElse: () => builds.first,
              );

        return Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(builds: builds),
              const Divider(height: 1),
              Expanded(
                child: builds.isEmpty
                    ? _EmptyState(onNewRun: () => context.go('/setup'))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide =
                              constraints.maxWidth >= _narrowBreakpoint;

                          if (isWide) {
                            return Row(
                              children: [
                                SizedBox(
                                  width: _listWidth,
                                  child: _BuildList(
                                    builds: builds,
                                    selectedId: _selectedBuildId,
                                    onSelect: (id) =>
                                        setState(() => _selectedBuildId = id),
                                  ),
                                ),
                                const VerticalDivider(width: 1),
                                Expanded(
                                  child: selected == null
                                      ? const SizedBox.shrink()
                                      : _BuildDetail(
                                          key: ValueKey(selected.id),
                                          activeBuild: selected,
                                          onCancel: () => getIt<BuildQueue>()
                                              .cancel(selected.id),
                                        ),
                                ),
                              ],
                            );
                          }

                          // Narrow: master-detail navigation
                          if (_detailVisible && selected != null) {
                            return Column(
                              children: [
                                _NarrowBackBar(
                                  onBack: () =>
                                      setState(() => _detailVisible = false),
                                ),
                                const Divider(height: 1),
                                Expanded(
                                  child: _BuildDetail(
                                    key: ValueKey(selected.id),
                                    activeBuild: selected,
                                    onCancel: () => getIt<BuildQueue>()
                                        .cancel(selected.id),
                                  ),
                                ),
                              ],
                            );
                          }

                          return _BuildList(
                            builds: builds,
                            selectedId: _selectedBuildId,
                            onSelect: (id) => setState(() {
                              _selectedBuildId = id;
                              _detailVisible = true;
                            }),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final List<ActiveBuild> builds;
  const _Header({required this.builds});

  @override
  Widget build(BuildContext context) {
    final running = builds.where((b) => b.status == ActiveBuildStatus.running).length;
    final pending = builds.where((b) => b.status == ActiveBuildStatus.pending).length;

    final parts = <String>[];
    if (running > 0) parts.add('$running running');
    if (pending > 0) parts.add('$pending pending');
    final subtitle = parts.isEmpty ? 'No active builds' : parts.join(', ');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 560;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Build Queue',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => context.go('/setup'),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('New Run'),
                        ),
                      ],
                    ),
                    const Gap(4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          color: Color(0xFF8B949E), fontSize: 12),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Build Queue',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                        const Gap(2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                              color: Color(0xFF8B949E), fontSize: 13),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'Max ${BuildQueue.maxConcurrent} concurrent · '
                      '${BuildQueue.maxIosConcurrent} iOS build at a time',
                      style: const TextStyle(
                          color: Color(0xFF8B949E), fontSize: 11),
                    ),
                    const Gap(16),
                    FilledButton.icon(
                      onPressed: () => context.go('/setup'),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New Run'),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// ─── Build List ───────────────────────────────────────────────────────────

class _BuildList extends StatelessWidget {
  final List<ActiveBuild> builds;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _BuildList({
    required this.builds,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'BUILDS',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: builds.length,
            itemBuilder: (_, i) => _BuildCard(
              activeBuild: builds[i],
              isSelected: builds[i].id == selectedId,
              onTap: () => onSelect(builds[i].id),
            ),
          ),
        ),
      ],
    );
  }
}

class _BuildCard extends StatelessWidget {
  final ActiveBuild activeBuild;
  final bool isSelected;
  final VoidCallback onTap;

  const _BuildCard({
    required this.activeBuild,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return StreamBuilder<void>(
      stream: activeBuild.onChange,
      builder: (context, _) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? cs.primary.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusDot(status: activeBuild.status),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        activeBuild.displayLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Gap(6),
                Row(
                  children: [
                    Text(
                      activeBuild.versionLabel,
                      style: const TextStyle(
                          color: Color(0xFF8B949E), fontSize: 11),
                    ),
                    const Gap(6),
                    ..._platformChips(activeBuild.request),
                  ],
                ),
                const Gap(4),
                _StatusLine(activeBuild: activeBuild),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _platformChips(RunRequest request) {
    return request.platforms.map((p) {
      final label = p == 'android' ? 'Android' : 'iOS';
      return Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: const Color(0xFF30363D),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Color(0xFF8B949E), fontSize: 10),
        ),
      );
    }).toList();
  }
}

class _StatusDot extends StatelessWidget {
  final ActiveBuildStatus status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case ActiveBuildStatus.running:
        color = AppTheme.colorRunning;
      case ActiveBuildStatus.completed:
        color = AppTheme.colorSuccess;
      case ActiveBuildStatus.failed:
        color = AppTheme.colorError;
      case ActiveBuildStatus.cancelled:
        color = AppTheme.colorWarning;
      case ActiveBuildStatus.pending:
        color = const Color(0xFF8B949E);
    }

    if (status == ActiveBuildStatus.running) {
      return SizedBox(
        width: 10,
        height: 10,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: color,
        ),
      );
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final ActiveBuild activeBuild;
  const _StatusLine({required this.activeBuild});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;

    switch (activeBuild.status) {
      case ActiveBuildStatus.pending:
        text = 'Pending';
        color = const Color(0xFF8B949E);
      case ActiveBuildStatus.running:
        final step = activeBuild.currentStepId;
        text = step != null ? step.replaceAll('_', ' ') : 'Running…';
        color = AppTheme.colorRunning;
      case ActiveBuildStatus.completed:
        final d = activeBuild.completedAt != null && activeBuild.startedAt != null
            ? activeBuild.completedAt!.difference(activeBuild.startedAt!)
            : null;
        text = 'Completed${d != null ? ' in ${_fmt(d)}' : ''}';
        color = AppTheme.colorSuccess;
      case ActiveBuildStatus.failed:
        text = 'Failed';
        color = AppTheme.colorError;
      case ActiveBuildStatus.cancelled:
        text = 'Cancelled';
        color = AppTheme.colorWarning;
    }

    return Text(
      text,
      style: TextStyle(color: color, fontSize: 11),
      overflow: TextOverflow.ellipsis,
    );
  }

  String _fmt(Duration d) {
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
  }
}

// ─── Build Detail ─────────────────────────────────────────────────────────

class _BuildDetail extends StatelessWidget {
  final ActiveBuild activeBuild;
  final VoidCallback onCancel;

  const _BuildDetail({super.key, required this.activeBuild, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: activeBuild.onChange,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailHeader(activeBuild: activeBuild, onCancel: onCancel),
            const Divider(height: 1),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const stepsWidth = 260.0;
                  const logMinWidth = 380.0;
                  final hasSteps = activeBuild.steps.isNotEmpty;
                  final usedBySteps = hasSteps ? stepsWidth + 1 : 0; // +1 for divider
                  final availableLog = constraints.maxWidth - usedBySteps;
                  final logWidth = availableLog < logMinWidth
                      ? logMinWidth
                      : availableLog;
                  final totalWidth = usedBySteps + logWidth;
                  final needsScroll = totalWidth > constraints.maxWidth;

                  Widget row = Row(
                    children: [
                      if (hasSteps)
                        SizedBox(
                          width: stepsWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                                child: Text(
                                  'STEPS',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 10,
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6),
                                  child: StepProgressList(
                                      steps: activeBuild.steps),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (hasSteps) const VerticalDivider(width: 1),
                      SizedBox(
                        width: logWidth,
                        child: activeBuild.logs.isEmpty
                            ? const Center(
                                child: Text(
                                  'Waiting for output…',
                                  style: TextStyle(color: Color(0xFF8B949E)),
                                ),
                              )
                            : LogViewer(logs: activeBuild.logs),
                      ),
                    ],
                  );

                  if (needsScroll) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(width: totalWidth, child: row),
                    );
                  }
                  return row;
                },
              ),
            ),
            if (activeBuild.isTerminal && activeBuild.result != null)
              _QueueCompletionBanner(
                success: activeBuild.status == ActiveBuildStatus.completed,
                artifacts: activeBuild.result!.artifacts,
              ),
          ],
        );
      },
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final ActiveBuild activeBuild;
  final VoidCallback onCancel;

  const _DetailHeader({required this.activeBuild, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final canCancel = activeBuild.status == ActiveBuildStatus.running ||
        activeBuild.status == ActiveBuildStatus.pending;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activeBuild.displayLabel,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const Gap(2),
              Text(
                '${activeBuild.versionLabel} · ${activeBuild.request.branch}',
                style: const TextStyle(
                    color: Color(0xFF8B949E), fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          if (canCancel)
            OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.stop, size: 14),
              label: Text(
                activeBuild.status == ActiveBuildStatus.pending
                    ? 'Remove'
                    : 'Abort',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.colorError,
                side: BorderSide(
                    color: AppTheme.colorError.withValues(alpha: 0.4)),
              ),
            ),
          if (activeBuild.status == ActiveBuildStatus.completed)
            Row(
              children: [
                const Icon(Icons.check_circle,
                    size: 16, color: AppTheme.colorSuccess),
                const Gap(6),
                const Text('Succeeded',
                    style: TextStyle(
                        color: AppTheme.colorSuccess, fontSize: 13)),
              ],
            ),
          if (activeBuild.status == ActiveBuildStatus.failed)
            Row(
              children: [
                const Icon(Icons.cancel, size: 16, color: AppTheme.colorError),
                const Gap(6),
                const Text('Failed',
                    style: TextStyle(
                        color: AppTheme.colorError, fontSize: 13)),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Narrow back bar ─────────────────────────────────────────────────────

class _NarrowBackBar extends StatelessWidget {
  final VoidCallback onBack;
  const _NarrowBackBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 18),
            onPressed: onBack,
            tooltip: 'Back to list',
          ),
          const Text('Build detail',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onNewRun;
  const _EmptyState({required this.onNewRun});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.queue,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const Gap(16),
          Text(
            'No builds in queue',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(8),
          const Text(
            'Start a build from Setup & Run',
            style: TextStyle(color: Color(0xFF8B949E), fontSize: 13),
          ),
          const Gap(20),
          FilledButton.icon(
            onPressed: onNewRun,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Run'),
          ),
        ],
      ),
    );
  }
}

// ─── Completion Banner ────────────────────────────────────────────────────

class _QueueCompletionBanner extends StatelessWidget {
  final bool success;
  final Map<String, String> artifacts;

  const _QueueCompletionBanner({
    required this.success,
    this.artifacts = const {},
  });

  @override
  Widget build(BuildContext context) {
    final color = success ? AppTheme.colorSuccess : AppTheme.colorError;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: color.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: color,
              ),
              const Gap(8),
              Text(
                success
                    ? 'Pipeline completed successfully'
                    : 'Pipeline failed — check logs above',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (artifacts.isNotEmpty) ...[
            const Gap(8),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                for (final entry in artifacts.entries)
                  _QueueArtifactRow(platform: entry.key, path: entry.value),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QueueArtifactRow extends StatelessWidget {
  final String platform;
  final String path;

  const _QueueArtifactRow({required this.platform, required this.path});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.folder_open, size: 13, color: Color(0xFF8B949E)),
        const Gap(4),
        Text(
          platform,
          style: const TextStyle(color: Color(0xFF8B949E), fontSize: 11),
        ),
        const Gap(8),
        TextButton.icon(
          onPressed: () => Process.run('open', ['-R', path]).ignore(),
          icon: const Icon(Icons.open_in_new, size: 11),
          label: const Text('Show in Finder'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF58A6FF),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            textStyle: const TextStyle(fontSize: 11),
          ),
        ),
        TextButton.icon(
          onPressed: () =>
              Clipboard.setData(ClipboardData(text: path)).ignore(),
          icon: const Icon(Icons.copy, size: 11),
          label: const Text('Copy Path'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF8B949E),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            textStyle: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }
}
