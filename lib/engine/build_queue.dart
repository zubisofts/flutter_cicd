import 'dart:async';
import 'dart:collection';
import '../config/config_repository.dart';
import '../config/environment_resolver.dart';
import '../config/models/pipeline_definition.dart';
import '../data/run_repository.dart';
import '../execution/log_line.dart';
import '../services/firestore_sync_service.dart';
import 'pipeline_runner.dart';
import 'step_result.dart';
import 'step_state.dart';

enum ActiveBuildStatus { pending, running, completed, failed, cancelled }

class ActiveBuild {
  final String id;
  final RunRequest request;
  final PipelineRunner runner;
  ActiveBuildStatus status;
  PipelineRunResult? result;
  final DateTime queuedAt;
  DateTime? startedAt;
  DateTime? completedAt;

  // Current running step (ID), used for queue card progress label.
  String? currentStepId;

  // Accumulated step states for the detail panel.
  final List<PipelineStepState> steps = [];

  // Accumulated logs (last 2000 lines).
  final List<LogLine> _logs = [];
  List<LogLine> get logs => List.unmodifiable(_logs);

  // Notifies the queue screen when steps or logs change (80ms batched).
  final _changeController = StreamController<void>.broadcast();
  Stream<void> get onChange => _changeController.stream;

  // Direct stream access — ExecutionBloc can subscribe to these.
  Stream<StepUpdate> get stepStream => runner.stepUpdates;
  Stream<LogLine> get logStream => runner.logLines;

  // Completes when the pipeline finishes (success or failure).
  final _completer = Completer<PipelineRunResult>();
  Future<PipelineRunResult> get completion => _completer.future;

  StreamSubscription<StepUpdate>? _stepSub;
  StreamSubscription<LogLine>? _logSub;
  final Queue<LogLine> _logBuffer = Queue();
  Timer? _flushTimer;

  ActiveBuild({
    required this.id,
    required this.request,
    required this.runner,
    required this.queuedAt,
    this.status = ActiveBuildStatus.pending,
  });

  void startBuffering() {
    _stepSub = runner.stepUpdates.listen(_onStep);
    _logSub = runner.logLines.listen(_onLog);
  }

  // Pre-populate steps as pending before execution starts.
  void initializeSteps(List<PipelineStepState> initialSteps) {
    if (steps.isNotEmpty) return;
    steps.addAll(initialSteps);
    _notifyChange();
  }

  void _onStep(StepUpdate update) {
    final idx = steps.indexWhere((s) => s.stepId == update.stepId);
    // Ignore steps that weren't pre-populated — they are skipped steps whose
    // condition didn't match the request (e.g. iOS steps in an Android-only
    // run). Showing them would flood the list with underscored step IDs.
    if (idx < 0) return;

    if (update.status == StepStatus.running) {
      currentStepId = update.stepId;
    } else if (currentStepId == update.stepId &&
        update.status != StepStatus.running) {
      currentStepId = null;
    }

    steps[idx] = PipelineStepState(
      stepId: update.stepId,
      stepName: steps[idx].stepName, // always preserve the display name
      status: update.status,
      duration: update.duration,
      errorMessage: update.errorMessage,
    );
    _notifyChange();
  }

  void _onLog(LogLine line) {
    _logBuffer.add(line);
    _flushTimer ??= Timer(const Duration(milliseconds: 80), _flushLogs);
  }

  void _flushLogs() {
    _flushTimer = null;
    if (_logBuffer.isEmpty) return;
    _logs.addAll(_logBuffer);
    if (_logs.length > 2000) _logs.removeRange(0, _logs.length - 2000);
    _logBuffer.clear();
    _notifyChange();
  }

  void _notifyChange() {
    if (!_changeController.isClosed) _changeController.add(null);
  }

  void complete(PipelineRunResult result) {
    _flushLogs();
    if (!_completer.isCompleted) _completer.complete(result);
  }

  void fail(Object error) {
    if (!_completer.isCompleted) _completer.completeError(error);
  }

  void dispose() {
    _stepSub?.cancel();
    _logSub?.cancel();
    _flushTimer?.cancel();
    _changeController.close();
  }

  bool get isTerminal =>
      status == ActiveBuildStatus.completed ||
      status == ActiveBuildStatus.failed ||
      status == ActiveBuildStatus.cancelled;

  bool get hasIos => request.platforms.contains('ios');

  String get displayLabel => '${request.projectName} › ${request.envName}';

  // Only TestFlight hides the build number — iOS uses auto-resolved number.
  // Android (Play Store) always uses the manually entered number so we show it.
  bool get _isStoreBuild => request.targets.contains('testflight');

  String get versionLabel => _isStoreBuild
      ? request.versionName
      : '${request.versionName}+${request.buildNumber}';
}

class BuildQueue {
  // Concurrency caps: max 3 total, max 1 iOS build at a time.
  static const maxConcurrent = 3;
  static const maxIosConcurrent = 1;

  final ConfigRepository _configRepo;
  final EnvironmentResolver _envResolver;
  final RunRepository _repo;
  final FirestoreSyncService? _firestoreSync;

  final List<ActiveBuild> _builds = [];
  final _listController = StreamController<List<ActiveBuild>>.broadcast();
  int _counter = 0;

  BuildQueue({
    required ConfigRepository configRepo,
    required EnvironmentResolver envResolver,
    required RunRepository repo,
    FirestoreSyncService? firestoreSync,
  })  : _configRepo = configRepo,
        _envResolver = envResolver,
        _repo = repo,
        _firestoreSync = firestoreSync;

  Stream<List<ActiveBuild>> get stream => _listController.stream;
  List<ActiveBuild> get builds => List.unmodifiable(_builds);

  int get activeCount =>
      _builds.where((b) => b.status == ActiveBuildStatus.running).length;

  int get pendingCount =>
      _builds.where((b) => b.status == ActiveBuildStatus.pending).length;

  int get liveCount => activeCount + pendingCount;

  ActiveBuild submit(RunRequest request) {
    final build = ActiveBuild(
      id: 'build_${++_counter}',
      request: request,
      runner: PipelineRunner(
        configRepo: _configRepo,
        envResolver: _envResolver,
      ),
      queuedAt: DateTime.now(),
    );
    build.startBuffering();
    _builds.add(build);
    _emitList();
    _preloadSteps(build);
    _schedule();
    return build;
  }

  void _preloadSteps(ActiveBuild build) async {
    try {
      final pipeline =
          await _configRepo.loadPipeline(build.request.projectId, 'mobile');
      final initialSteps = pipeline.steps
          .where((s) => _stepWillRun(s, build.request))
          .map((s) => PipelineStepState(
                stepId: s.id,
                stepName: s.name,
                status: StepStatus.pending,
              ))
          .toList();
      build.initializeSteps(initialSteps);
    } catch (_) {}
  }

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

  void cancel(String buildId) {
    final build = _findById(buildId);
    if (build == null) return;
    if (build.status == ActiveBuildStatus.pending) {
      build.status = ActiveBuildStatus.cancelled;
      build.completedAt = DateTime.now();
      _emitList();
    } else if (build.status == ActiveBuildStatus.running) {
      build.runner.abort();
    }
  }

  ActiveBuild? _findById(String id) {
    try {
      return _builds.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  void _schedule() {
    for (final build
        in _builds.where((b) => b.status == ActiveBuildStatus.pending).toList()) {
      if (_canStart(build.request)) _start(build);
    }
  }

  bool _canStart(RunRequest request) {
    final active = _builds.where((b) => b.status == ActiveBuildStatus.running);
    if (active.length >= maxConcurrent) return false;
    if (request.platforms.contains('ios') &&
        active.where((b) => b.hasIos).length >= maxIosConcurrent) {
      return false;
    }
    return true;
  }

  void _start(ActiveBuild build) {
    build.status = ActiveBuildStatus.running;
    build.startedAt = DateTime.now();
    _emitList();

    build.runner.run(build.request).then((result) {
      build.result = result;
      build.status =
          result.success ? ActiveBuildStatus.completed : ActiveBuildStatus.failed;
      build.completedAt = DateTime.now();
      build.complete(result);
      _persistRun(build, result);
      _emitList();
      _schedule();
    }).catchError((Object e) {
      build.status = ActiveBuildStatus.failed;
      build.completedAt = DateTime.now();
      build.fail(e);
      _emitList();
      _schedule();
    });
  }

  void _persistRun(ActiveBuild build, PipelineRunResult result) async {
    if (result.runId.isEmpty) return;
    final req = build.request;
    final stepNames = {for (final s in build.steps) s.stepId: s.stepName};

    // ── Local SQLite ────────────────────────────────────────────────────────
    try {
      await _repo.createRun(
        id: result.runId,
        projectId: req.projectId,
        projectName: req.projectName,
        envName: req.envName,
        branch: req.branch,
        versionLabel: build.versionLabel,
        platforms: req.platforms,
        targets: req.targets,
      );
      await _repo.completeRun(
        id: result.runId,
        success: result.success,
        duration: result.totalDuration,
        errorMessage: result.errorMessage,
      );
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
    } catch (_) {}

    // ── Firestore sync (best-effort) ────────────────────────────────────────
    if (_firestoreSync != null) {
      final steps = result.stepResults.entries.map((e) {
        final sr = e.value;
        return StepSyncRecord(
          stepId: e.key,
          stepName: stepNames[e.key] ?? e.key,
          status: sr.status.name,
          durationSeconds: sr.duration?.inSeconds ?? 0,
          errorMessage: sr.errorMessage,
        );
      }).toList();

      _firestoreSync.syncRun(
        runId: result.runId,
        projectId: req.projectId,
        projectName: req.projectName,
        envName: req.envName,
        branch: req.branch,
        versionLabel: build.versionLabel,
        platforms: req.platforms,
        targets: req.targets,
        startedAt: build.startedAt ?? build.queuedAt,
        finishedAt: build.completedAt ?? DateTime.now(),
        success: result.success,
        durationSeconds: result.totalDuration.inSeconds,
        errorMessage: result.errorMessage,
        steps: steps,
      );
    }
  }

  void _emitList() {
    if (!_listController.isClosed) {
      _listController.add(List.unmodifiable(_builds));
    }
  }

  void dispose() {
    for (final b in _builds) {
      b.dispose();
    }
    _listController.close();
  }
}
