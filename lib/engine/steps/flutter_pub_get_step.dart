import '../pipeline_context.dart';
import '../step_result.dart';
import '../../execution/exceptions.dart';
import '../../execution/log_line.dart';
import '../../execution/process_runner.dart';
import '../../execution/retry_controller.dart';
import 'pipeline_step.dart';

class FlutterPubGetStep extends PipelineStep {
  final ProcessRunner _runner;

  FlutterPubGetStep(super.definition, {ProcessRunner? runner})
      : _runner = runner ?? ProcessRunner();

  @override
  Future<StepResult> execute(PipelineContext ctx) async {
    await _pubGet(ctx);
    await _buildRunner(ctx);
    return StepResult.success();
  }

  Future<void> _pubGet(PipelineContext ctx) async {
    ctx.logSink.addRaw(id, LogLevel.info, 'Running flutter pub get...');

    Future<StepResult> attempt() async {
      final result = await _runner.run(
        command: ['flutter', 'pub', 'get'],
        workingDir: ctx.workspaceDir,
        environment: ctx.environment.shellEnv,
        logSink: ctx.logSink,
        stepId: id,
        cancelSignal: ctx.abortSignal,
      );
      if (!result.success) {
        throw RetryableStepException(
          stepId: id,
          message: 'flutter pub get failed (exit ${result.exitCode})',
        );
      }
      return StepResult.success();
    }

    if (retryPolicy != null) {
      await RetryController.withRetry(
        fn: attempt,
        policy: retryPolicy!,
        logSink: ctx.logSink,
        stepId: id,
      );
    } else {
      final result = await _runner.run(
        command: ['flutter', 'pub', 'get'],
        workingDir: ctx.workspaceDir,
        environment: ctx.environment.shellEnv,
        logSink: ctx.logSink,
        stepId: id,
      );
      if (!result.success) {
        throw FatalPipelineException(
          stepId: id,
          message: 'flutter pub get failed',
          exitCode: result.exitCode,
        );
      }
    }

    ctx.logSink.addRaw(id, LogLevel.success, 'Dependencies installed');
  }

  Future<void> _buildRunner(PipelineContext ctx) async {
    ctx.logSink.addRaw(id, LogLevel.info, 'Running build_runner...');

    final result = await _runner.run(
      command: [
        'dart',
        'run',
        'build_runner',
        'build',
        '--delete-conflicting-outputs',
      ],
      workingDir: ctx.workspaceDir,
      environment: ctx.environment.shellEnv,
      logSink: ctx.logSink,
      stepId: id,
    );

    if (!result.success) {
      throw FatalPipelineException(
        stepId: id,
        message: 'build_runner build failed',
        exitCode: result.exitCode,
      );
    }

    ctx.logSink.addRaw(id, LogLevel.success, 'Code generation complete');
  }
}
