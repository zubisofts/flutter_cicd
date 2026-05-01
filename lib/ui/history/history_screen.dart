import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/database.dart';
import '../../data/run_repository.dart';
import '../../di/injection.dart';
import '../../engine/pipeline_runner.dart';
import '../../engine/step_result.dart';
import '../execution/widgets/log_viewer.dart';
import '../shell/app_theme.dart';
import '../../execution/log_line.dart';
import 'history_bloc.dart';

RunRequest _runRequestFrom(RunRecord run, {Set<String> skipStepIds = const {}}) =>
    RunRequest(
      projectId: run.projectId,
      projectName: run.projectName,
      branch: run.branch,
      envName: run.envName,
      versionName: run.versionLabel.split('+').first,
      buildNumber: int.tryParse(
              run.versionLabel.contains('+')
                  ? run.versionLabel.split('+').last
                  : '1') ??
          1,
      platforms: run.platforms.split(',').map((e) => e.trim()).toList(),
      targets: run.targets.split(',').map((e) => e.trim()).toList(),
      skipStepIds: skipStepIds,
    );

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HistoryBloc(getIt<RunRepository>())
        ..add(const HistoryLoaded()),
      child: const _HistoryContent(),
    );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HistoryBloc, HistoryState>(
      listenWhen: (prev, curr) =>
          (curr.retryRun != null && prev.retryRun == null) ||
          (curr.resumeRun != null && prev.resumeRun == null),
      listener: (context, state) {
        if (state.retryRun != null) {
          final run = state.retryRun!;
          context.read<HistoryBloc>().add(const HistoryRetryClear());
          context.go('/run', extra: _runRequestFrom(run));
        } else if (state.resumeRun != null) {
          final run = state.resumeRun!;
          final skipIds = state.resumeSkipStepIds;
          context.read<HistoryBloc>().add(const HistoryResumeClear());
          context.go('/run', extra: _runRequestFrom(run, skipStepIds: skipIds));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFF0D1117),
          body: Row(
            children: [
              // Run list
              SizedBox(
                width: 340,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Run History',
                            style: TextStyle(
                              color: Color(0xFFE6EDF3),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (state.runs.isNotEmpty) ...[
                            const Gap(8),
                            Row(children: [
                              _StatChip(
                                  label: '${state.runs.length} runs',
                                  color: const Color(0xFF58A6FF)),
                              const Gap(6),
                              _StatChip(
                                  label: '${state.successCount} passed',
                                  color: AppTheme.colorSuccess),
                              const Gap(6),
                              _StatChip(
                                  label: state.successRate,
                                  color: const Color(0xFF8B949E)),
                            ]),
                            const Gap(10),
                            _DurationSparkline(runs: state.runs),
                          ],
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: state.isLoading
                          ? const Center(
                              child: CircularProgressIndicator())
                          : state.runs.isEmpty
                              ? _EmptyHistory()
                              : _RunList(
                                  runs: state.runs,
                                  selectedId: state.selectedRun?.id,
                                ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              // Detail panel
              Expanded(
                child: state.selectedRun != null
                    ? _RunDetail(
                        run: state.selectedRun!,
                        steps: state.selectedSteps,
                        logLines: state.logLines,
                      )
                    : const _EmptyDetail(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11,
              fontWeight: FontWeight.w500)),
    );
  }
}

class _RunList extends StatelessWidget {
  final List<RunRecord> runs;
  final String? selectedId;

  const _RunList({required this.runs, this.selectedId});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: runs.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final run = runs[i];
        return _RunTile(
          run: run,
          isSelected: run.id == selectedId,
          onTap: () => context
              .read<HistoryBloc>()
              .add(HistoryRunSelected(run.id)),
        );
      },
    );
  }
}

class _RunTile extends StatelessWidget {
  final RunRecord run;
  final bool isSelected;
  final VoidCallback onTap;

  const _RunTile({
    required this.run,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, HH:mm');
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
        color: isSelected
            ? const Color(0xFF21262D)
            : Colors.transparent,
        child: Row(
          children: [
            Icon(
              run.success ? Icons.check_circle : Icons.cancel,
              size: 16,
              color: run.success
                  ? AppTheme.colorSuccess
                  : AppTheme.colorError,
            ),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${run.projectName} › ${run.envName} › ${run.versionLabel}',
                    style: const TextStyle(
                      color: Color(0xFFE6EDF3),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(2),
                  Text(
                    '${fmt.format(run.startedAt)}  •  '
                    '${run.branch}  •  '
                    '${_duration(run.durationSeconds)}',
                    style: const TextStyle(
                        color: Color(0xFF8B949E), fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 14),
              tooltip: 'Delete',
              color: const Color(0xFF8B949E),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => context
                  .read<HistoryBloc>()
                  .add(HistoryRunDeleted(run.id)),
            ),
          ],
        ),
      ),
    );
  }

  String _duration(int? seconds) {
    if (seconds == null) return '—';
    if (seconds >= 60) return '${seconds ~/ 60}m ${seconds % 60}s';
    return '${seconds}s';
  }
}

class _RunDetail extends StatelessWidget {
  final RunRecord run;
  final List<StepRecord> steps;
  final List<String> logLines;

  const _RunDetail({
    required this.run,
    required this.steps,
    required this.logLines,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    run.success ? Icons.check_circle : Icons.cancel,
                    size: 18,
                    color: run.success
                        ? AppTheme.colorSuccess
                        : AppTheme.colorError,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      '${run.projectName} › ${run.envName} › ${run.versionLabel}',
                      style: const TextStyle(
                        color: Color(0xFFE6EDF3),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Gap(8),
                  OutlinedButton.icon(
                    onPressed: () => context
                        .read<HistoryBloc>()
                        .add(HistoryRetryRequested(run.id)),
                    icon: const Icon(Icons.replay, size: 14),
                    label: const Text('Retry'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF58A6FF),
                      side: const BorderSide(color: Color(0xFF58A6FF)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                  if (!run.success) ...[
                    const Gap(8),
                    OutlinedButton.icon(
                      onPressed: () => context
                          .read<HistoryBloc>()
                          .add(HistoryResumeRequested(run.id)),
                      icon: const Icon(Icons.fast_forward, size: 14),
                      label: const Text('Resume'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDB8C39),
                        side: const BorderSide(color: Color(0xFFDB8C39)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
              const Gap(6),
              Text(
                'Run ID: ${run.id}  •  Branch: ${run.branch}  •  '
                'Platforms: ${run.platforms}  •  Targets: ${run.targets}',
                style: const TextStyle(
                    color: Color(0xFF8B949E), fontSize: 12),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Steps + Logs
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        'STEPS',
                        style: TextStyle(
                          color: Color(0xFF8B949E),
                          fontSize: 10,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        itemCount: steps.length,
                        itemBuilder: (_, i) => _StepHistoryRow(
                            step: steps[i]),
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        'LOG OUTPUT',
                        style: TextStyle(
                          color: Color(0xFF8B949E),
                          fontSize: 10,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: logLines.isEmpty
                          ? const Center(
                              child: Text('No log file found',
                                  style: TextStyle(
                                      color: Color(0xFF8B949E),
                                      fontSize: 13)))
                          : LogViewer(
                              logs: logLines
                                  .map((l) => LogLine(
                                        stepId: '',
                                        level: LogLevel.info,
                                        message: l,
                                        timestamp: DateTime.now(),
                                      ))
                                  .toList(),
                              autoScroll: false,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepHistoryRow extends StatelessWidget {
  final StepRecord step;
  const _StepHistoryRow({required this.step});

  @override
  Widget build(BuildContext context) {
    final status = StepStatus.values[step.statusIndex];
    Color color;
    IconData icon;

    switch (status) {
      case StepStatus.success:
        color = AppTheme.colorSuccess;
        icon = Icons.check_circle;
        break;
      case StepStatus.failed:
        color = AppTheme.colorError;
        icon = Icons.cancel;
        break;
      case StepStatus.skipped:
        color = AppTheme.colorSkipped;
        icon = Icons.skip_next;
        break;
      default:
        color = AppTheme.colorSkipped;
        icon = Icons.radio_button_unchecked;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const Gap(8),
          Expanded(
            child: Text(
              step.stepName,
              style: const TextStyle(
                  color: Color(0xFFE6EDF3), fontSize: 12),
            ),
          ),
          if (step.durationSeconds != null)
            Text(
              '${step.durationSeconds}s',
              style: const TextStyle(
                  color: Color(0xFF8B949E), fontSize: 11),
            ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 40, color: Color(0xFF30363D)),
          Gap(12),
          Text('No runs yet',
              style: TextStyle(
                  color: Color(0xFF8B949E), fontSize: 14)),
          Gap(4),
          Text('Start a pipeline from the Setup screen',
              style: TextStyle(
                  color: Color(0xFF8B949E), fontSize: 12)),
        ],
      ),
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app, size: 40, color: Color(0xFF30363D)),
          Gap(12),
          Text('Select a run to view details',
              style: TextStyle(
                  color: Color(0xFF8B949E), fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── Duration Sparkline ───────────────────────────────────────────────────

class _DurationSparkline extends StatelessWidget {
  final List<RunRecord> runs;
  const _DurationSparkline({required this.runs});

  @override
  Widget build(BuildContext context) {
    // Runs are newest-first; take last 20 and reverse to oldest-first
    final recent = runs.take(20).toList().reversed.toList();
    if (recent.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: 36,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(recent),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<RunRecord> runs;
  _SparklinePainter(this.runs);

  @override
  void paint(Canvas canvas, Size size) {
    if (runs.length < 2) return;

    final durations = runs.map((r) => (r.durationSeconds ?? 0).toDouble()).toList();
    final maxD = durations.fold<double>(1.0, (m, d) => d > m ? d : m);

    final points = <Offset>[];
    for (int i = 0; i < runs.length; i++) {
      final x = i / (runs.length - 1) * size.width;
      final y = size.height - (durations[i] / maxD) * (size.height - 8) - 2;
      points.add(Offset(x, y));
    }

    // Draw connecting line
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF30363D)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // Draw dots colored by success/failure
    for (int i = 0; i < runs.length; i++) {
      final color = runs[i].success
          ? AppTheme.colorSuccess
          : AppTheme.colorError;
      canvas.drawCircle(points[i], 3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.runs.length != runs.length ||
      (runs.isNotEmpty && old.runs.last.id != runs.last.id);
}
