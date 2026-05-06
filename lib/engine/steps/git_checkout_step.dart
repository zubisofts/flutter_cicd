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
    final branch = ctx.options.branch;
    final workspace = ctx.workspaceDir;
    final depth = definition.params['depth'] as int? ?? 1;

    final repoUrl = ctx.state['project_repository'] as String? ?? '';
    if (repoUrl.isEmpty) {
      throw FatalPipelineException(
        stepId: id,
        message: 'Repository URL is not configured',
      );
    }

    final hasToken = ctx.environment.shellEnv.containsKey('GIT_CONFIG_COUNT');
    ctx.logSink.addRaw(id, LogLevel.info,
        hasToken
            ? 'Auth: GitHub token (HTTPS URL rewrite active)'
            : 'Auth: system SSH (no GitHub token configured)');
    ctx.logSink.addRaw(id, LogLevel.info,
        'Cloning $repoUrl @ $branch into $workspace');

    // shellEnv carries GIT_CONFIG_* URL-rewrite rules when a GitHub token is
    // configured, so git authenticates automatically — for this clone and for
    // any nested git calls (flutter pub get git deps, fastlane match, etc.).
    final result = await _runner.run(
      command: [
        'git', 'clone',
        '--depth', '$depth',
        '--branch', branch,
        '--single-branch',
        repoUrl,
        workspace,
      ],
      workingDir: '/tmp',
      environment: ctx.environment.shellEnv,
      logSink: ctx.logSink,
      stepId: id,
      cancelSignal: ctx.abortSignal,
    );

    if (!result.success) {
      throw FatalPipelineException(
        stepId: id,
        message: 'Git clone failed with exit code ${result.exitCode}',
        exitCode: result.exitCode,
      );
    }

    ctx.logSink.addRaw(id, LogLevel.success, 'Repository cloned successfully');
    return StepResult.success();
  }
}
