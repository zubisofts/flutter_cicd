import '../pipeline_context.dart';
import '../step_result.dart';
import '../../execution/exceptions.dart';
import '../../execution/log_line.dart';
import '../../execution/process_runner.dart';
import '../../execution/retry_controller.dart';
import 'pipeline_step.dart';

class FirebaseDistributeStep extends PipelineStep {
  final ProcessRunner _runner;

  FirebaseDistributeStep(super.definition, {ProcessRunner? runner})
      : _runner = runner ?? ProcessRunner();

  @override
  Future<StepResult> execute(PipelineContext ctx) async {
    final platform =
        definition.params['platform'] as String? ?? 'android';
    final env = ctx.environment;

    final firebaseAppId = platform == 'ios'
        ? env.iosFirebaseAppId
        : env.androidFirebaseAppId;

    if (firebaseAppId.isEmpty) {
      throw FatalPipelineException(
        stepId: id,
        message: 'Firebase App ID is not configured for $platform '
            'in environment ${env.name}',
      );
    }

    final artifactPath = platform == 'android'
        ? (ctx.artifactPath('android_apk') ?? ctx.artifactPath('android'))
        : ctx.artifactPath(platform);
    if (artifactPath == null || artifactPath.isEmpty) {
      throw FatalPipelineException(
        stepId: id,
        message: 'No artifact found for $platform. '
            'Ensure the build step ran first.',
      );
    }

    final groups =
        env.distributionRules.firebase?.testerGroups.join(',') ?? '';
    final releaseNotes = _buildReleaseNotes(ctx);
    final serviceAccountPath =
        env.shellEnv['GOOGLE_APPLICATION_CREDENTIALS'] ?? '';

    ctx.logSink.addRaw(id, LogLevel.info,
        'Uploading $platform artifact to Firebase App Distribution...');

    Future<StepResult> distribute() async {
      final command = [
        'firebase',
        'appdistribution:distribute',
        artifactPath,
        '--app',
        firebaseAppId,
        '--release-notes',
        releaseNotes,
      ];
      if (groups.isNotEmpty) {
        command.addAll(['--groups', groups]);
      }

      final procEnv = <String, String>{};
      if (serviceAccountPath.isNotEmpty) {
        procEnv['GOOGLE_APPLICATION_CREDENTIALS'] = serviceAccountPath;
      }

      final result = await _runner.run(
        command: command,
        workingDir: ctx.workspaceDir,
        environment: procEnv,
        timeout: const Duration(minutes: 15),
        logSink: ctx.logSink,
        stepId: id,
        cancelSignal: ctx.abortSignal,
      );

      if (!result.success) {
        throw RetryableStepException(
          stepId: id,
          message: 'Firebase upload failed (exit ${result.exitCode})',
        );
      }

      return StepResult.success();
    }

    final policy = retryPolicy;
    if (policy != null) {
      return await RetryController.withRetry(
        fn: distribute,
        policy: policy,
        logSink: ctx.logSink,
        stepId: id,
      );
    }

    return await distribute();
  }

  String _buildReleaseNotes(PipelineContext ctx) =>
      'Build ${ctx.versionLabel} | '
      '${ctx.options.branch} | '
      '${ctx.environment.displayName}';
}
