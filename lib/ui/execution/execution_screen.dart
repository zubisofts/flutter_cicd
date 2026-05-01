import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../config/config_repository.dart';
import '../../di/injection.dart';
import '../../engine/pipeline_runner.dart';
import '../shell/app_theme.dart';
import 'execution_bloc.dart';
import 'widgets/log_viewer.dart';
import 'widgets/step_progress_list.dart';

class ExecutionScreen extends StatefulWidget {
  final RunRequest request;
  /// When true, starts the pipeline immediately on mount.
  /// False when re-attaching to an already-running or completed run.
  final bool startRun;

  const ExecutionScreen({super.key, required this.request, this.startRun = true});

  @override
  State<ExecutionScreen> createState() => _ExecutionScreenState();
}

class _ExecutionScreenState extends State<ExecutionScreen> {
  late ExecutionBloc _bloc;
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<ExecutionBloc>();
    _startTimer();
    if (widget.startRun) {
      _loadAndRun();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_bloc.state.phase == ExecutionPhase.running) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  Future<void> _loadAndRun() async {
    try {
      final pipeline = await getIt<ConfigRepository>()
          .loadPipeline(widget.request.projectId, 'mobile');
      _bloc.add(ExecutionStarted(widget.request, pipeline.steps));
    } catch (e) {
      _bloc.add(ExecutionCompleted(PipelineRunResult(
        runId: '',
        success: false,
        errorMessage: 'Failed to load pipeline: $e',
        totalDuration: Duration.zero,
        stepResults: {},
      )));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Do NOT close _bloc — it's a singleton and must survive navigation.
    super.dispose();
  }

  String get _elapsedLabel {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<ExecutionBloc, ExecutionState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFF0D1117),
            body: Column(
              children: [
                _Header(
                  request: widget.request,
                  phase: state.phase,
                  elapsedLabel: _elapsedLabel,
                  totalDuration: state.totalDuration,
                  overallSuccess: state.overallSuccess,
                ),
                const Divider(height: 1),
                Expanded(
                  child: Row(
                    children: [
                      // Left panel: step list
                      SizedBox(
                        width: 300,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
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
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                child: StepProgressList(steps: state.steps),
                              ),
                            ),
                            const Divider(height: 1),
                            _ActionBar(phase: state.phase),
                          ],
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      // Right panel: live logs
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                              child: Text(
                                'LIVE OUTPUT',
                                style: TextStyle(
                                  color: Color(0xFF8B949E),
                                  fontSize: 10,
                                  letterSpacing: 1.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: LogViewer(
                                logs: state.logs,
                                autoScroll: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.phase == ExecutionPhase.completed &&
                    state.overallSuccess != null)
                  _CompletionBanner(success: state.overallSuccess!),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final RunRequest request;
  final ExecutionPhase phase;
  final String elapsedLabel;
  final Duration? totalDuration;
  final bool? overallSuccess;

  const _Header({
    required this.request,
    required this.phase,
    required this.elapsedLabel,
    this.totalDuration,
    this.overallSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 18,
                color: Color(0xFF8B949E)),
            onPressed: () => context.go('/setup'),
            tooltip: 'Back to Setup',
            padding: EdgeInsets.zero,
          ),
          const Gap(12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${request.projectId} › ${request.envName} › '
                '${request.versionName}+${request.buildNumber}',
                style: const TextStyle(
                  color: Color(0xFFE6EDF3),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                request.branch,
                style: const TextStyle(
                    color: Color(0xFF8B949E), fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          if (phase == ExecutionPhase.running)
            Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.colorRunning),
                ),
                const Gap(8),
                Text(
                  elapsedLabel,
                  style: const TextStyle(
                      color: Color(0xFF8B949E), fontSize: 12),
                ),
              ],
            ),
          if (phase == ExecutionPhase.completed && totalDuration != null)
            Row(
              children: [
                Icon(
                  overallSuccess == true
                      ? Icons.check_circle
                      : Icons.cancel,
                  size: 16,
                  color: overallSuccess == true
                      ? AppTheme.colorSuccess
                      : AppTheme.colorError,
                ),
                const Gap(6),
                Text(
                  _formatDuration(totalDuration!),
                  style: const TextStyle(
                      color: Color(0xFF8B949E), fontSize: 12),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
  }
}

class _ActionBar extends StatelessWidget {
  final ExecutionPhase phase;
  const _ActionBar({required this.phase});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          if (phase == ExecutionPhase.running)
            OutlinedButton.icon(
              onPressed: () => context
                  .read<ExecutionBloc>()
                  .add(const ExecutionAbortRequested()),
              icon: const Icon(Icons.stop, size: 14,
                  color: AppTheme.colorError),
              label: const Text('ABORT',
                  style: TextStyle(color: AppTheme.colorError)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.colorError),
              ),
            ),
          if (phase == ExecutionPhase.completed ||
              phase == ExecutionPhase.aborted) ...[
            OutlinedButton.icon(
              onPressed: () => context.go('/setup'),
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('New Run'),
            ),
            const Gap(8),
            OutlinedButton.icon(
              onPressed: () => context.go('/history'),
              icon: const Icon(Icons.history, size: 14),
              label: const Text('View History'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompletionBanner extends StatelessWidget {
  final bool success;
  const _CompletionBanner({required this.success});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      color: success
          ? AppTheme.colorSuccess.withValues(alpha:0.15)
          : AppTheme.colorError.withValues(alpha:0.15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            success ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: success ? AppTheme.colorSuccess : AppTheme.colorError,
          ),
          const Gap(8),
          Text(
            success
                ? 'Pipeline completed successfully'
                : 'Pipeline failed — check logs above',
            style: TextStyle(
              color: success ? AppTheme.colorSuccess : AppTheme.colorError,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
