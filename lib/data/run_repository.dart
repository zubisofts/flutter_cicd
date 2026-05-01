import 'package:drift/drift.dart';
import 'database.dart';
import '../engine/step_result.dart';

class RunRepository {
  final AppDatabase _db;

  RunRepository(this._db);

  Future<List<RunRecord>> getAll() => _db.getAllRuns();

  Future<RunRecord?> getById(String id) => _db.getRunById(id);

  Future<List<StepRecord>> getSteps(String runId) =>
      _db.getStepsForRun(runId);

  Future<void> createRun({
    required String id,
    required String projectId,
    required String projectName,
    required String envName,
    required String branch,
    required String versionLabel,
    required List<String> platforms,
    required List<String> targets,
  }) async {
    await _db.insertRun(RunRecordsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      projectName: Value(projectName),
      envName: Value(envName),
      branch: Value(branch),
      versionLabel: Value(versionLabel),
      platforms: Value(platforms.join(',')),
      targets: Value(targets.join(',')),
      startedAt: Value(DateTime.now()),
      success: const Value(false),
    ));
  }

  Future<void> completeRun({
    required String id,
    required bool success,
    required Duration duration,
    String? errorMessage,
  }) async {
    await _db.updateRun(RunRecordsCompanion(
      id: Value(id),
      finishedAt: Value(DateTime.now()),
      durationSeconds: Value(duration.inSeconds),
      success: Value(success),
      errorMessage: Value(errorMessage),
      // required columns that won't change:
      projectId: const Value.absent(),
      projectName: const Value.absent(),
      envName: const Value.absent(),
      branch: const Value.absent(),
      versionLabel: const Value.absent(),
      platforms: const Value.absent(),
      targets: const Value.absent(),
      startedAt: const Value.absent(),
    ));
  }

  Future<void> deleteRun(String id) => _db.deleteRun(id);

  Future<void> recordStep({
    required String runId,
    required String stepId,
    required String stepName,
    required StepStatus status,
    Duration? duration,
    String? errorMessage,
  }) async {
    await _db.insertStep(StepRecordsCompanion(
      runId: Value(runId),
      stepId: Value(stepId),
      stepName: Value(stepName),
      statusIndex: Value(status.index),
      durationSeconds: Value(duration?.inSeconds),
      errorMessage: Value(errorMessage),
    ));
  }
}
