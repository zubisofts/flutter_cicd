import 'package:path/path.dart' as p;
import '../pipeline_context.dart';
import '../step_result.dart';
import '../../execution/exceptions.dart';
import '../../execution/log_line.dart';
import '../../execution/process_runner.dart';
import 'pipeline_step.dart';

class ShellScriptStep extends PipelineStep {
  final ProcessRunner _runner;

  ShellScriptStep(super.definition, {ProcessRunner? runner})
      : _runner = runner ?? ProcessRunner();

  @override
  Future<StepResult> execute(PipelineContext ctx) async {
    final script = definition.params['script'] as String;
    final subDir = definition.params['working_dir'] as String?;
    final env = ctx.environment;

    final workingDir =
        subDir != null ? p.join(ctx.workspaceDir, subDir) : ctx.workspaceDir;

    ctx.logSink.addRaw(id, LogLevel.info, 'Running: $script');

    final result = await _runner.run(
      command: ['/bin/zsh', '-c', script],
      workingDir: workingDir,
      environment: {
        ...env.shellEnv,
        'WORKSPACE_DIR': ctx.workspaceDir,
        'ENV_NAME': env.name,
        'VERSION_NAME': env.resolvedVersion,
        'BUILD_NUMBER': '${env.buildNumber}',
        'BUNDLE_ID': env.iosBundleId,
        'ANDROID_PACKAGE_NAME': env.androidPackageName,
      },
      timeout: const Duration(minutes: 30),
      logSink: ctx.logSink,
      stepId: id,
      cancelSignal: ctx.abortSignal,
    );

    if (!result.success) {
      throw FatalPipelineException(
        stepId: id,
        message: 'Script failed (exit ${result.exitCode})',
        exitCode: result.exitCode,
      );
    }

    return StepResult.success();
  }
}
