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

    // We pass the repo URL via state set by the pipeline builder
    final repoUrl = ctx.state['project_repository'] as String? ?? '';
    if (repoUrl.isEmpty) {
      throw FatalPipelineException(
        stepId: id,
        message: 'Repository URL is not configured',
      );
    }

    // If a GitHub token is available, rewrite to HTTPS so the clone works
    // without SSH key or agent setup. SSH URLs are converted automatically.
    final token = ctx.environment.shellEnv['GITHUB_TOKEN'] ?? '';
    final cloneUrl = token.isNotEmpty ? _injectToken(repoUrl, token) : repoUrl;

    ctx.logSink.addRaw(id, LogLevel.info,
        'Cloning $repoUrl @ $branch into $workspace');

    final result = await _runner.run(
      command: [
        'git', 'clone',
        '--depth', '$depth',
        '--branch', branch,
        '--single-branch',
        cloneUrl,
        workspace,
      ],
      workingDir: '/tmp',
      environment: ctx.environment.shellEnv,
      // Redact the token from any git output (error messages, progress lines).
      lineFilter: token.isNotEmpty ? (l) => !l.contains(token) : null,
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

    ctx.logSink.addRaw(
        id, LogLevel.success, 'Repository cloned successfully');
    return StepResult.success();
  }

  /// Rewrites [url] to an HTTPS URL with [token] embedded as credentials.
  /// Handles both SSH (`git@github.com:org/repo.git`) and plain HTTPS forms.
  static String _injectToken(String url, String token) {
    // SSH form: git@github.com:org/repo.git → https://github.com/org/repo.git
    final sshPattern = RegExp(r'^git@([^:]+):(.+)$');
    String httpsUrl = url;
    final sshMatch = sshPattern.firstMatch(url);
    if (sshMatch != null) {
      httpsUrl = 'https://${sshMatch.group(1)}/${sshMatch.group(2)}';
    }
    // Ensure .git suffix
    if (!httpsUrl.endsWith('.git')) httpsUrl = '$httpsUrl.git';
    // Inject token: https://github.com/... → https://oauth2:<token>@github.com/...
    return httpsUrl.replaceFirst('https://', 'https://oauth2:$token@');
  }
}
