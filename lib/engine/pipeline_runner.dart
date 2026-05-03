import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;

import '../config/config_repository.dart';
import '../config/environment_resolver.dart';
import '../config/models/resolved_environment.dart';
import '../execution/exceptions.dart';
import '../execution/log_line.dart';
import '../execution/log_sink.dart';
import 'pipeline_context.dart';
import 'step_registry.dart';
import 'step_result.dart';

class RunRequest {
  final String projectId;
  final String projectName;
  final String branch;
  final String envName;
  final String versionName;
  final int buildNumber;
  final List<String> platforms;
  final List<String> targets;
  /// Step IDs to skip because they already succeeded in a prior run.
  final Set<String> skipStepIds;

  const RunRequest({
    required this.projectId,
    required this.projectName,
    required this.branch,
    required this.envName,
    required this.versionName,
    required this.buildNumber,
    required this.platforms,
    required this.targets,
    this.skipStepIds = const {},
  });
}

class StepUpdate {
  final String stepId;
  final StepStatus status;
  final Duration? duration;
  final String? errorMessage;

  const StepUpdate({
    required this.stepId,
    required this.status,
    this.duration,
    this.errorMessage,
  });
}

class PipelineRunResult {
  final String runId;
  final bool success;
  final String? errorMessage;
  final Duration totalDuration;
  final Map<String, StepResult> stepResults;
  /// Persistent paths for build artifacts, keyed by platform.
  final Map<String, String> artifacts;

  const PipelineRunResult({
    required this.runId,
    required this.success,
    this.errorMessage,
    required this.totalDuration,
    required this.stepResults,
    this.artifacts = const {},
  });
}

class PipelineRunner {
  final ConfigRepository _configRepo;
  final EnvironmentResolver _envResolver;
  final StepRegistry _registry;
  final String _baseDir;

  final StreamController<StepUpdate> _stepUpdates =
      StreamController<StepUpdate>.broadcast();
  final StreamController<LogLine> _logLines =
      StreamController<LogLine>.broadcast();

  Stream<StepUpdate> get stepUpdates => _stepUpdates.stream;
  Stream<LogLine> get logLines => _logLines.stream;

  PipelineRunner({
    required ConfigRepository configRepo,
    required EnvironmentResolver envResolver,
    StepRegistry? registry,
    String? baseDir,
  })  : _configRepo = configRepo,
        _envResolver = envResolver,
        _registry = registry ?? StepRegistry.defaults,
        _baseDir = baseDir ??
            p.join(
                Platform.environment['HOME'] ?? '/tmp', '.cicd');

  PipelineContext? _currentContext;

  void abort() => _currentContext?.abort();

  Future<PipelineRunResult> run(RunRequest request) async {
    final runId = _generateRunId();
    final start = DateTime.now();
    final stepResults = <String, StepResult>{};

    // Set up workspace
    final workspace =
        p.join(_baseDir, 'runs', runId, 'workspace');
    await Directory(workspace).create(recursive: true);

    // Set up log sink
    final logSink = LogSink();
    await logSink.openFile(runId, _baseDir);

    // Forward logs to the public stream
    logSink.stream.listen((line) {
      if (!_logLines.isClosed) _logLines.add(line);
    });

    try {
      // Resolve environment
      final options = BuildOptions(
        projectId: request.projectId,
        branch: request.branch,
        versionName: request.versionName,
        buildNumber: request.buildNumber,
        platforms: request.platforms,
        targets: request.targets,
      );

      final env = await _envResolver.resolve(
        projectId: request.projectId,
        envName: request.envName,
        options: options,
        runId: runId,
      );

      // Load pipeline definition
      final pipeline =
          await _configRepo.loadPipeline(request.projectId, 'mobile');
      final project = await _configRepo.loadProject(request.projectId);

      // Build context
      final ctx = PipelineContext(
        runId: runId,
        projectId: request.projectId,
        environment: env,
        options: options,
        workspaceDir: workspace,
        logSink: logSink,
      );
      ctx.state['project_repository'] = project.repository;
      _currentContext = ctx;

      logSink.addRaw('pipeline', LogLevel.info,
          '══════════════════════════════════════════');
      logSink.addRaw('pipeline', LogLevel.info,
          'Pipeline: ${project.name} › ${env.displayName} › ${ctx.versionLabel}');
      logSink.addRaw('pipeline', LogLevel.info,
          'Run ID: $runId');
      logSink.addRaw('pipeline', LogLevel.info,
          'Platforms: ${request.platforms.join(', ')}');
      logSink.addRaw('pipeline', LogLevel.info,
          'Targets: ${request.targets.join(', ')}');
      logSink.addRaw('pipeline', LogLevel.info,
          '══════════════════════════════════════════');

      // Execute steps
      for (final stepDef in pipeline.steps) {
        if (ctx.isAborted) {
          _stepUpdates.add(StepUpdate(
            stepId: stepDef.id,
            status: StepStatus.aborted,
          ));
          stepResults[stepDef.id] = StepResult.aborted();
          continue;
        }

        // Skip steps that already succeeded in a prior run (resume feature).
        if (request.skipStepIds.contains(stepDef.id)) {
          logSink.addRaw(stepDef.id, LogLevel.debug,
              'Step "${stepDef.id}" skipped (resumed from prior success)');
          _stepUpdates.add(StepUpdate(
            stepId: stepDef.id,
            status: StepStatus.skipped,
          ));
          stepResults[stepDef.id] = StepResult.success();
          continue;
        }

        final step = _registry.resolve(stepDef);

        if (!step.shouldExecute(ctx)) {
          logSink.addRaw(stepDef.id, LogLevel.debug,
              'Step "${step.name}" skipped (condition not met)');
          _stepUpdates.add(StepUpdate(
            stepId: stepDef.id,
            status: StepStatus.skipped,
          ));
          stepResults[stepDef.id] = StepResult.skipped('condition not met');
          continue;
        }

        // Check dependencies completed.
        // Skipped steps (condition not met) count as satisfied — a distribution
        // step that depends on both build_android and archive_ios should still
        // run if the user only selected Android (archive_ios was skipped).
        final unmetDeps = stepDef.dependsOn.where((dep) {
          final depResult = stepResults[dep];
          return depResult == null ||
              (!depResult.isSuccess && !depResult.isSkipped);
        }).toList();

        if (unmetDeps.isNotEmpty) {
          final reason = 'Dependency not met: ${unmetDeps.join(', ')}';
          logSink.addRaw(stepDef.id, LogLevel.warning,
              'Skipping "${step.name}": $reason');
          _stepUpdates.add(StepUpdate(
            stepId: stepDef.id,
            status: StepStatus.skipped,
            errorMessage: reason,
          ));
          stepResults[stepDef.id] = StepResult.skipped(reason);
          continue;
        }

        _stepUpdates.add(
            StepUpdate(stepId: stepDef.id, status: StepStatus.running));

        final stepStart = DateTime.now();
        logSink.addRaw(stepDef.id, LogLevel.info,
            '─── ${step.name} ───────────────────────────');

        try {
          final result = await step.execute(ctx);
          final duration = DateTime.now().difference(stepStart);
          final finalResult = StepResult.success(
              duration: duration, metadata: result.metadata);

          stepResults[stepDef.id] = finalResult;
          _stepUpdates.add(StepUpdate(
            stepId: stepDef.id,
            status: StepStatus.success,
            duration: duration,
          ));
          logSink.addRaw(stepDef.id, LogLevel.success,
              '✓ ${step.name} completed in ${_formatDuration(duration)}');
        } on FatalPipelineException catch (e) {
          final duration = DateTime.now().difference(stepStart);
          stepResults[stepDef.id] = StepResult.failed(e.message, duration: duration);
          _stepUpdates.add(StepUpdate(
            stepId: stepDef.id,
            status: StepStatus.failed,
            duration: duration,
            errorMessage: e.message,
          ));
          logSink.addRaw(
              stepDef.id, LogLevel.error, '✗ ${step.name}: ${e.message}');

          if (step.abortOnFailure) {
            return PipelineRunResult(
              runId: runId,
              success: false,
              errorMessage: e.message,
              totalDuration: DateTime.now().difference(start),
              stepResults: stepResults,
              artifacts: await _copyArtifacts(ctx, runId, request.platforms),
            );
          }
        } on PipelineAbortedException {
          final duration = DateTime.now().difference(stepStart);
          stepResults[stepDef.id] = StepResult.aborted();
          _stepUpdates.add(StepUpdate(
            stepId: stepDef.id,
            status: StepStatus.aborted,
            duration: duration,
          ));
          break;
        } catch (e) {
          final duration = DateTime.now().difference(stepStart);
          final message = e.toString();
          stepResults[stepDef.id] =
              StepResult.failed(message, duration: duration);
          _stepUpdates.add(StepUpdate(
            stepId: stepDef.id,
            status: StepStatus.failed,
            duration: duration,
            errorMessage: message,
          ));
          logSink.addRaw(stepDef.id, LogLevel.error,
              '✗ Unexpected error in ${step.name}: $message');

          if (step.abortOnFailure) {
            return PipelineRunResult(
              runId: runId,
              success: false,
              errorMessage: message,
              totalDuration: DateTime.now().difference(start),
              stepResults: stepResults,
              artifacts: await _copyArtifacts(ctx, runId, request.platforms),
            );
          }
        }
      }

      final totalDuration = DateTime.now().difference(start);
      final overallSuccess =
          stepResults.values.every((r) => r.isSuccess || r.isSkipped);

      logSink.addRaw('pipeline', LogLevel.info,
          '══════════════════════════════════════════');
      logSink.addRaw(
          'pipeline',
          overallSuccess ? LogLevel.success : LogLevel.error,
          overallSuccess
              ? '✓ Pipeline completed in ${_formatDuration(totalDuration)}'
              : '✗ Pipeline failed after ${_formatDuration(totalDuration)}');
      logSink.addRaw('pipeline', LogLevel.info,
          '══════════════════════════════════════════');

      final artifacts = await _copyArtifacts(ctx, runId, request.platforms);
      return PipelineRunResult(
        runId: runId,
        success: overallSuccess,
        totalDuration: totalDuration,
        stepResults: stepResults,
        artifacts: artifacts,
      );
    } finally {
      _currentContext = null;
      await logSink.close();
      // Delete the workspace to reclaim disk space; the log file is kept.
      final ws = Directory(workspace);
      if (await ws.exists()) {
        await ws.delete(recursive: true);
      }
      // Prune Xcode DerivedData for Flutter Runner projects — each run
      // creates a fresh Runner-{hash} folder (~2–5 GB) that never auto-cleans.
      await _pruneXcodeDerivedData();
      // Keep only the 20 most recent run directories.
      await _pruneOldRuns(keep: 20);
      // Delete the per-run credential temp files written by EnvironmentResolver.
      await EnvironmentResolver.cleanTempCredentials(runId);
    }
  }

  /// Deletes Xcode DerivedData folders for Flutter Runner projects.
  /// Flutter workspace paths change every run, so Xcode creates a new
  /// Runner-{hash} folder (~2–5 GB) each time and never removes old ones.
  Future<void> _pruneXcodeDerivedData() async {
    final home = Platform.environment['HOME'];
    if (home == null) return;
    final derivedData =
        Directory('$home/Library/Developer/Xcode/DerivedData');
    if (!await derivedData.exists()) return;
    try {
      await for (final entry in derivedData.list()) {
        if (entry is Directory &&
            p.basename(entry.path).startsWith('Runner-')) {
          try {
            await entry.delete(recursive: true);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  Future<void> _pruneOldRuns({int keep = 20}) async {
    final runsDir = Directory(p.join(_baseDir, 'runs'));
    if (!await runsDir.exists()) return;
    final dirs = await runsDir
        .list()
        .where((e) => e is Directory)
        .cast<Directory>()
        .toList();
    // Sort newest first (run IDs are timestamp strings, so lexicographic desc = newest first)
    dirs.sort((a, b) =>
        p.basename(b.path).compareTo(p.basename(a.path)));
    for (final old in dirs.skip(keep)) {
      try {
        await old.delete(recursive: true);
      } catch (_) {}
    }
  }

  /// Copies build artifacts out of the (soon-to-be-deleted) workspace to
  /// a persistent location at ~/.cicd/artifacts/{runId}/.
  Future<Map<String, String>> _copyArtifacts(
      PipelineContext ctx, String runId, List<String> platforms) async {
    final result = <String, String>{};
    final destDir = p.join(_baseDir, 'artifacts', runId);
    for (final platform in platforms) {
      final srcPath = ctx.artifactPath(platform);
      if (srcPath == null) continue;
      final src = File(srcPath);
      if (!await src.exists()) continue;
      try {
        await Directory(destDir).create(recursive: true);
        final dest = p.join(destDir, p.basename(srcPath));
        await src.copy(dest);
        result[platform] = dest;
      } catch (_) {}
    }
    return result;
  }

  String _generateRunId() {
    final now = DateTime.now();
    return '${now.year}${_pad(now.month)}${_pad(now.day)}'
        '_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  String _formatDuration(Duration d) {
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds % 60}s';
    }
    return '${d.inSeconds}s';
  }
}
