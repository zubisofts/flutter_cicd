import 'dart:async';
import 'dart:collection';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../engine/pipeline_runner.dart';
import '../../engine/step_result.dart';
import '../../execution/log_line.dart';
import '../../config/models/pipeline_definition.dart';
import '../../data/run_repository.dart';

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

class PipelineStepState extends Equatable {
  final String stepId;
  final String stepName;
  final StepStatus status;
  final Duration? duration;
  final String? errorMessage;

  const PipelineStepState({
    required this.stepId,
    required this.stepName,
    required this.status,
    this.duration,
    this.errorMessage,
  });

  PipelineStepState copyWith({
    StepStatus? status,
    Duration? duration,
    String? errorMessage,
  }) =>
      PipelineStepState(
        stepId: stepId,
        stepName: stepName,
        status: status ?? this.status,
        duration: duration ?? this.duration,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props =>
      [stepId, stepName, status, duration, errorMessage];
}

class ExecutionState extends Equatable {
  final ExecutionPhase phase;
  final List<PipelineStepState> steps;
  final List<LogLine> logs;
  final DateTime? startedAt;
  final Duration? totalDuration;
  final bool? overallSuccess;
  final String? errorMessage;

  const ExecutionState({
    this.phase = ExecutionPhase.idle,
    this.steps = const <PipelineStepState>[],
    this.logs = const [],
    this.startedAt,
    this.totalDuration,
    this.overallSuccess,
    this.errorMessage,
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
  }) =>
      ExecutionState(
        phase: phase ?? this.phase,
        steps: steps ?? this.steps,
        logs: logs ?? this.logs,
        startedAt: startedAt ?? this.startedAt,
        totalDuration: totalDuration ?? this.totalDuration,
        overallSuccess: overallSuccess ?? this.overallSuccess,
        errorMessage: errorMessage ?? this.errorMessage,
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
      ];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────

class ExecutionBloc extends Bloc<ExecutionEvent, ExecutionState> {
  final PipelineRunner _runner;
  final RunRepository _repo;
  StreamSubscription<StepUpdate>? _stepSub;
  StreamSubscription<LogLine>? _logSub;
  final Queue<LogLine> _logBuffer = Queue();
  Timer? _logFlushTimer;

  RunRequest? _currentRequest;
  RunRequest? get currentRequest => _currentRequest;
  List<StepDefinition> _currentSteps = [];

  ExecutionBloc(this._runner, this._repo) : super(const ExecutionState()) {
    on<ExecutionStarted>(_onStarted);
    on<_LogBatchFlushed>(_onLogBatch);
    on<ExecutionStepUpdated>(_onStepUpdated);
    on<ExecutionCompleted>(_onCompleted);
    on<ExecutionAbortRequested>(_onAbortRequested);
    on<ExecutionReset>(_onReset);
  }

  Future<void> _onStarted(
      ExecutionStarted event, Emitter<ExecutionState> emit) async {
    _currentRequest = event.request;
    _currentSteps = event.steps;

    final initialSteps = event.steps
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
    ));

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
    ));

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

  void _onAbortRequested(
      ExecutionAbortRequested event, Emitter<ExecutionState> emit) {
    _runner.abort();
    emit(state.copyWith(phase: ExecutionPhase.aborted));
  }

  void _onReset(ExecutionReset event, Emitter<ExecutionState> emit) {
    _stepSub?.cancel();
    _logSub?.cancel();
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
