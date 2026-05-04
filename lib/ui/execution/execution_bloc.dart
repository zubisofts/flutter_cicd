import 'dart:async';
import 'dart:collection';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:equatable/equatable.dart';
import '../../engine/pipeline_runner.dart';
import '../../engine/step_result.dart';
import '../../engine/step_state.dart';
import '../../execution/log_line.dart';
import '../../config/models/pipeline_definition.dart';
import '../../data/run_repository.dart';
import '../../services/email_notification_service.dart';
import '../../services/google_chat_notification_service.dart';
import '../../services/slack_notification_service.dart';
import '../../services/teams_notification_service.dart';
import '../../services/tray_service.dart';

export '../../engine/step_state.dart' show PipelineStepState;

// ─── Events ───────────────────────────────────────────────────────────────

abstract class ExecutionEvent extends Equatable {
  const ExecutionEvent();
  @override
  List<Object?> get props => [];
}

class ExecutionStarted extends ExecutionEvent {
  final RunRequest request;
  final List<StepDefinition> steps;
  const ExecutionStarted(this.request, this.steps);
  @override
  List<Object?> get props => [request.projectId];
}

class ExecutionLogReceived extends ExecutionEvent {
  final LogLine line;
  const ExecutionLogReceived(this.line);
  @override
  List<Object?> get props => [line.timestamp];
}

class _LogBatchFlushed extends ExecutionEvent {
  final List<LogLine> lines;
  const _LogBatchFlushed(this.lines);
  @override
  List<Object?> get props => [lines.length];
}

class ExecutionStepUpdated extends ExecutionEvent {
  final StepUpdate update;
  const ExecutionStepUpdated(this.update);
  @override
  List<Object?> get props => [update.stepId, update.status];
}

class ExecutionCompleted extends ExecutionEvent {
  final PipelineRunResult result;
  const ExecutionCompleted(this.result);
  @override
  List<Object?> get props => [result.success];
}

class ExecutionAbortRequested extends ExecutionEvent {
  const ExecutionAbortRequested();
}

class ExecutionReset extends ExecutionEvent {
  const ExecutionReset();
}

// ─── States ───────────────────────────────────────────────────────────────

enum ExecutionPhase { idle, running, completed, aborted }

class ExecutionState extends Equatable {
  final ExecutionPhase phase;
  final List<PipelineStepState> steps;
  final List<LogLine> logs;
  final DateTime? startedAt;
  final Duration? totalDuration;
  final bool? overallSuccess;
  final String? errorMessage;
  /// Persistent paths to build artifacts, keyed by platform.
  final Map<String, String> artifacts;

  const ExecutionState({
    this.phase = ExecutionPhase.idle,
    this.steps = const <PipelineStepState>[],
    this.logs = const [],
    this.startedAt,
    this.totalDuration,
    this.overallSuccess,
    this.errorMessage,
    this.artifacts = const {},
  });

  Duration get elapsed => startedAt != null
      ? DateTime.now().difference(startedAt!)
      : Duration.zero;

  ExecutionState copyWith({
    ExecutionPhase? phase,
    List<PipelineStepState>? steps,
    List<LogLine>? logs,
    DateTime? startedAt,
    Duration? totalDuration,
    bool? overallSuccess,
    String? errorMessage,
    Map<String, String>? artifacts,
  }) =>
      ExecutionState(
        phase: phase ?? this.phase,
        steps: steps ?? this.steps,
        logs: logs ?? this.logs,
        startedAt: startedAt ?? this.startedAt,
        totalDuration: totalDuration ?? this.totalDuration,
        overallSuccess: overallSuccess ?? this.overallSuccess,
        errorMessage: errorMessage ?? this.errorMessage,
        artifacts: artifacts ?? this.artifacts,
      );

  @override
  List<Object?> get props => [
        phase,
        steps,
        logs.length,
        startedAt,
        totalDuration,
        overallSuccess,
        errorMessage,
        artifacts.length,
      ];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────

class ExecutionBloc extends Bloc<ExecutionEvent, ExecutionState> {
  final PipelineRunner _runner;
  final RunRepository _repo;
  final EmailNotificationService _emailService;
  final SlackNotificationService _slackService;
  final TeamsNotificationService _teamsService;
  final GoogleChatNotificationService _googleChatService;
  final TrayService _tray;
  StreamSubscription<StepUpdate>? _stepSub;
  StreamSubscription<LogLine>? _logSub;
  final Queue<LogLine> _logBuffer = Queue();
  Timer? _logFlushTimer;

  RunRequest? _currentRequest;
  RunRequest? get currentRequest => _currentRequest;
  List<StepDefinition> _currentSteps = [];

  ExecutionBloc(
    this._runner,
    this._repo,
    this._emailService,
    this._slackService,
    this._teamsService,
    this._googleChatService,
    this._tray,
  ) : super(const ExecutionState()) {
    on<ExecutionStarted>(_onStarted);
    on<_LogBatchFlushed>(_onLogBatch);
    on<ExecutionStepUpdated>(_onStepUpdated);
    on<ExecutionCompleted>(_onCompleted);
    on<ExecutionAbortRequested>(_onAbortRequested);
    on<ExecutionReset>(_onReset);
  }

  /// Mirrors the platform/target condition logic from [PipelineStep.shouldExecute]
  /// so we can pre-filter the display list before execution starts.
  bool _stepWillRun(StepDefinition step, RunRequest request) {
    if (request.skipStepIds.contains(step.id)) return false;
    final cond = step.condition;
    if (cond == null || cond.isEmpty) return true;
    switch (cond) {
      case 'android':
        return request.platforms.contains('android');
      case 'ios':
        return request.platforms.contains('ios');
      case 'firebase_android':
        return request.targets.contains('firebase_android') &&
            request.platforms.contains('android');
      case 'firebase_ios':
        return request.targets.contains('firebase_ios') &&
            request.platforms.contains('ios');
      case 'testflight':
        return request.targets.contains('testflight') &&
            request.platforms.contains('ios');
      case 'playstore':
        return request.targets.contains('playstore') &&
            request.platforms.contains('android');
      default:
        return true;
    }
  }

  Future<void> _onStarted(
      ExecutionStarted event, Emitter<ExecutionState> emit) async {
    _currentRequest = event.request;
    _currentSteps = event.steps;

    final initialSteps = event.steps
        .where((s) => _stepWillRun(s, event.request))
        .map((s) => PipelineStepState(
              stepId: s.id,
              stepName: s.name,
              status: StepStatus.pending,
            ))
        .toList();

    emit(state.copyWith(
      phase: ExecutionPhase.running,
      steps: initialSteps,
      logs: [],
      startedAt: DateTime.now(),
      overallSuccess: null,
      errorMessage: null,
      artifacts: {},
    ));

    _tray.setBuilding(
        '${event.request.projectName} · ${event.request.envName}').ignore();

    _stepSub?.cancel();
    _logSub?.cancel();
    _logFlushTimer?.cancel();
    _logFlushTimer = null;
    _logBuffer.clear();

    _stepSub = _runner.stepUpdates.listen(
      (update) => add(ExecutionStepUpdated(update)),
    );

    // Buffer incoming log lines and flush to the BLoC at most every 80ms
    // to avoid thousands of state emissions per second during xcodebuild.
    _logSub = _runner.logLines.listen((line) {
      _logBuffer.add(line);
      _logFlushTimer ??= Timer(const Duration(milliseconds: 80), _flushLogs);
    });

    // Run pipeline in background
    _runner.run(event.request).then((result) {
      add(ExecutionCompleted(result));
    }).catchError((e) {
      add(ExecutionCompleted(PipelineRunResult(
        runId: '',
        success: false,
        errorMessage: e.toString(),
        totalDuration: Duration.zero,
        stepResults: {},
      )));
    });
  }

  void _flushLogs() {
    _logFlushTimer = null;
    if (_logBuffer.isEmpty || isClosed) return;
    add(_LogBatchFlushed(List.of(_logBuffer)));
    _logBuffer.clear();
  }

  void _onLogBatch(_LogBatchFlushed event, Emitter<ExecutionState> emit) {
    var updated = [...state.logs, ...event.lines];
    if (updated.length > 2000) {
      updated = updated.sublist(updated.length - 2000);
    }
    emit(state.copyWith(logs: updated));
  }

  void _onStepUpdated(
      ExecutionStepUpdated event, Emitter<ExecutionState> emit) {
    final update = event.update;
    final steps = state.steps.map<PipelineStepState>((s) {
      if (s.stepId == update.stepId) {
        return s.copyWith(
          status: update.status,
          duration: update.duration,
          errorMessage: update.errorMessage,
        );
      }
      return s;
    }).toList();
    emit(state.copyWith(steps: steps));
  }

  Future<void> _onCompleted(
      ExecutionCompleted event, Emitter<ExecutionState> emit) async {
    _stepSub?.cancel();
    _logSub?.cancel();
    _logFlushTimer?.cancel();
    _logFlushTimer = null;
    // Flush any lines that arrived in the last 80ms window
    if (_logBuffer.isNotEmpty) {
      var updated = [...state.logs, ..._logBuffer];
      if (updated.length > 2000) updated = updated.sublist(updated.length - 2000);
      emit(state.copyWith(logs: updated));
      _logBuffer.clear();
    }
    emit(state.copyWith(
      phase: ExecutionPhase.completed,
      overallSuccess: event.result.success,
      totalDuration: event.result.totalDuration,
      errorMessage: event.result.errorMessage,
      artifacts: event.result.artifacts,
    ));

    final label = _currentRequest != null
        ? '${_currentRequest!.projectName} · ${_currentRequest!.envName}'
        : '';
    if (event.result.success) {
      _tray.setSuccess(label).ignore();
    } else {
      _tray.setFailed(label).ignore();
    }

    _sendBuildNotification(event.result.success, event.result.totalDuration);
    if (_currentRequest != null) {
      _emailService.sendBuildResult(
        request: _currentRequest!,
        success: event.result.success,
        duration: event.result.totalDuration,
      ).ignore();
      _slackService.sendBuildResult(
        request: _currentRequest!,
        success: event.result.success,
        duration: event.result.totalDuration,
      ).ignore();
      _teamsService.sendBuildResult(
        request: _currentRequest!,
        success: event.result.success,
        duration: event.result.totalDuration,
      ).ignore();
      _googleChatService.sendBuildResult(
        request: _currentRequest!,
        success: event.result.success,
        duration: event.result.totalDuration,
      ).ignore();
    }

    final req = _currentRequest;
    final result = event.result;
    if (req != null && result.runId.isNotEmpty) {
      try {
        final versionLabel =
            '${req.versionName}+${req.buildNumber}';
        await _repo.createRun(
          id: result.runId,
          projectId: req.projectId,
          projectName: req.projectName,
          envName: req.envName,
          branch: req.branch,
          versionLabel: versionLabel,
          platforms: req.platforms,
          targets: req.targets,
        );
        await _repo.completeRun(
          id: result.runId,
          success: result.success,
          duration: result.totalDuration,
          errorMessage: result.errorMessage,
        );
        // Persist individual step outcomes
        final stepNames = {for (final s in _currentSteps) s.id: s.name};
        for (final entry in result.stepResults.entries) {
          final sr = entry.value;
          await _repo.recordStep(
            runId: result.runId,
            stepId: entry.key,
            stepName: stepNames[entry.key] ?? entry.key,
            status: sr.status,
            duration: sr.duration,
            errorMessage: sr.errorMessage,
          );
        }
      } catch (_) {
        // History persistence failure must not affect the UI
      }
    }
  }

  void _sendBuildNotification(bool success, Duration duration) {
    final req = _currentRequest;
    final subtitle = success ? 'Build Succeeded' : 'Build Failed';
    final body = req != null
        ? '${req.projectName} · ${req.envName} · ${req.versionName}+${req.buildNumber} — ${_formatDuration(duration)}'
        : _formatDuration(duration);
    LocalNotification(
      identifier: 'flutterci_build_result',
      title: 'FlutterCI',
      subtitle: subtitle,
      body: body,
    ).show();
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
  }

  void _onAbortRequested(
      ExecutionAbortRequested event, Emitter<ExecutionState> emit) {
    _runner.abort();
    _tray.setIdle().ignore();
    emit(state.copyWith(phase: ExecutionPhase.aborted));
  }

  void _onReset(ExecutionReset event, Emitter<ExecutionState> emit) {
    _stepSub?.cancel();
    _logSub?.cancel();
    _tray.setIdle().ignore();
    emit(const ExecutionState());
  }

  @override
  Future<void> close() {
    _stepSub?.cancel();
    _logSub?.cancel();
    _logFlushTimer?.cancel();
    return super.close();
  }
}
