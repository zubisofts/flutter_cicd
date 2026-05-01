import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:path/path.dart' as p;
import '../../data/database.dart';
import '../../data/run_repository.dart';

// ─── Events ───────────────────────────────────────────────────────────────

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();
  @override
  List<Object?> get props => [];
}

class HistoryLoaded extends HistoryEvent {
  const HistoryLoaded();
}

class HistoryRunSelected extends HistoryEvent {
  final String runId;
  const HistoryRunSelected(this.runId);
  @override
  List<Object?> get props => [runId];
}

class HistoryRunDeleted extends HistoryEvent {
  final String runId;
  const HistoryRunDeleted(this.runId);
  @override
  List<Object?> get props => [runId];
}

class HistoryRetryRequested extends HistoryEvent {
  final String runId;
  const HistoryRetryRequested(this.runId);
  @override
  List<Object?> get props => [runId];
}

class HistoryRetryClear extends HistoryEvent {
  const HistoryRetryClear();
}

class HistoryLogLoaded extends HistoryEvent {
  final String runId;
  final List<String> lines;
  const HistoryLogLoaded(this.runId, this.lines);
  @override
  List<Object?> get props => [runId];
}

// ─── States ───────────────────────────────────────────────────────────────

class HistoryState extends Equatable {
  final List<RunRecord> runs;
  final RunRecord? selectedRun;
  final List<StepRecord> selectedSteps;
  final List<String> logLines;
  final bool isLoading;
  final String? error;
  final RunRecord? retryRun; // set briefly when user requests retry

  const HistoryState({
    this.runs = const [],
    this.selectedRun,
    this.selectedSteps = const [],
    this.logLines = const [],
    this.isLoading = false,
    this.error,
    this.retryRun,
  });

  HistoryState copyWith({
    List<RunRecord>? runs,
    RunRecord? selectedRun,
    List<StepRecord>? selectedSteps,
    List<String>? logLines,
    bool? isLoading,
    String? error,
    bool clearSelection = false,
    RunRecord? retryRun,
    bool clearRetry = false,
  }) =>
      HistoryState(
        runs: runs ?? this.runs,
        selectedRun:
            clearSelection ? null : (selectedRun ?? this.selectedRun),
        selectedSteps:
            clearSelection ? [] : (selectedSteps ?? this.selectedSteps),
        logLines: clearSelection ? [] : (logLines ?? this.logLines),
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        retryRun: clearRetry ? null : (retryRun ?? this.retryRun),
      );

  // Stats
  int get successCount => runs.where((r) => r.success).length;
  String get successRate => runs.isEmpty
      ? '—'
      : '${(successCount / runs.length * 100).round()}%';

  @override
  List<Object?> get props => [
        runs.length,
        selectedRun?.id,
        selectedSteps.length,
        logLines.length,
        isLoading,
        error,
        retryRun?.id,
      ];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final RunRepository _repo;
  final String _baseDir;

  HistoryBloc(this._repo, {String? baseDir})
      : _baseDir = baseDir ??
            p.join(
                Platform.environment['HOME'] ?? '/tmp', '.cicd'),
        super(const HistoryState()) {
    on<HistoryLoaded>(_onLoaded);
    on<HistoryRunSelected>(_onRunSelected);
    on<HistoryRunDeleted>(_onRunDeleted);
    on<HistoryRetryRequested>(_onRetryRequested);
    on<HistoryRetryClear>((_, emit) => emit(state.copyWith(clearRetry: true)));
    on<HistoryLogLoaded>(_onLogLoaded);
  }

  Future<void> _onLoaded(
      HistoryLoaded event, Emitter<HistoryState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final runs = await _repo.getAll();
      emit(state.copyWith(runs: runs, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onRunSelected(
      HistoryRunSelected event, Emitter<HistoryState> emit) async {
    final run = state.runs.firstWhere(
      (r) => r.id == event.runId,
      orElse: () => state.runs.first,
    );
    final steps = await _repo.getSteps(event.runId);
    emit(state.copyWith(
      selectedRun: run,
      selectedSteps: steps,
    ));

    // Load log file async
    final logFile = File(
        p.join(_baseDir, 'runs', event.runId, 'run.log'));
    if (await logFile.exists()) {
      final lines = await logFile.readAsLines();
      add(HistoryLogLoaded(event.runId, lines));
    }
  }

  Future<void> _onRunDeleted(
      HistoryRunDeleted event, Emitter<HistoryState> emit) async {
    try {
      await _repo.deleteRun(event.runId);
      // Also delete the run log file from disk
      final logFile =
          File(p.join(_baseDir, 'runs', event.runId, 'run.log'));
      if (await logFile.exists()) await logFile.delete();
      final runDir = Directory(p.join(_baseDir, 'runs', event.runId));
      if (await runDir.exists()) await runDir.delete(recursive: true);

      final runs = await _repo.getAll();
      final wasSelected = state.selectedRun?.id == event.runId;
      emit(state.copyWith(
        runs: runs,
        clearSelection: wasSelected,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onRetryRequested(
      HistoryRetryRequested event, Emitter<HistoryState> emit) {
    final run = state.runs.firstWhere(
      (r) => r.id == event.runId,
      orElse: () => state.runs.first,
    );
    emit(state.copyWith(retryRun: run));
  }

  void _onLogLoaded(HistoryLogLoaded event, Emitter<HistoryState> emit) {
    if (state.selectedRun?.id == event.runId) {
      emit(state.copyWith(logLines: event.lines));
    }
  }
}
