import '../pipeline_context.dart';
import '../step_result.dart';
import '../../execution/exceptions.dart';
import '../../execution/log_line.dart';
import '../../execution/process_runner.dart';
import 'pipeline_step.dart';

class GitCheckoutStep extends PipelineStep {
  final ProcessRunner _runner;

  GitCheckoutStep(super.definition, {ProcessRunner? runner})
      : _runner = runner ?? ProcessRunner();

  @override
  Future<StepResult> execute(PipelineContext ctx) async {
    final repo = ctx.environment.shellEnv['REPO'] ??
        ctx.options.branch; // resolved from project config
    final branch = ctx.options.branch;
    final workspace = ctx.workspaceDir;
    final depth = definition.params['depth'] as int? ?? 1;

    ctx.logSink.addRaw(id, LogLevel.info,
        'Cloning $repo@$branch into $workspace');

    // We pass the repo URL via state set by the pipeline builder
    final repoUrl = ctx.state['project_repository'] as String? ?? '';
    if (repoUrl.isEmpty) {
      throw FatalPipelineException(
        stepId: id,
        message: 'Repository URL is not configured',
      );
    }

    final result = await _runner.run(
      command: [
        'git',
        'clone',
        '--depth',
        '$depth',
        '--branch',
        branch,
        '--single-branch',
        repoUrl,
        workspace,
      ],
      workingDir: '/tmp',
      logSink: ctx.logSink,
      stepId: id,
    );

    if (!result.success) {
      throw FatalPipelineException(
        stepId: id,
        message: 'Git clone failed with exit code ${result.exitCode}',
        exitCode: result.exitCode,
      );
    }

    ctx.logSink.addRaw(
        id, LogLevel.success, 'Repository cloned successfully');
    return StepResult.success();
  }
}
