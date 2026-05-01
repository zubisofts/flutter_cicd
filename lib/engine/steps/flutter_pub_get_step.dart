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
    ctx.logSink.addRaw(id, LogLevel.info, 'Running flutter pub get...');

    Future<StepResult> run() async {
      final result = await _runner.run(
        command: ['flutter', 'pub', 'get'],
        workingDir: ctx.workspaceDir,
        logSink: ctx.logSink,
        stepId: id,
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
      return await RetryController.withRetry(
        fn: run,
        policy: retryPolicy!,
        logSink: ctx.logSink,
        stepId: id,
      );
    }

    final result = await _runner.run(
      command: ['flutter', 'pub', 'get'],
      workingDir: ctx.workspaceDir,
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

    ctx.logSink.addRaw(id, LogLevel.success, 'Dependencies installed');
    return StepResult.success();
  }
}
