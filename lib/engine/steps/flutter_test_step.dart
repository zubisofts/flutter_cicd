import '../pipeline_context.dart';
import '../step_result.dart';
import '../../execution/exceptions.dart';
import '../../execution/log_line.dart';
import '../../execution/process_runner.dart';
import 'pipeline_step.dart';

class FlutterTestStep extends PipelineStep {
  final ProcessRunner _runner;

  FlutterTestStep(super.definition, {ProcessRunner? runner})
      : _runner = runner ?? ProcessRunner();

  @override
  Future<StepResult> execute(PipelineContext ctx) async {
    final coverage = definition.params['coverage'] as bool? ?? false;
    final testPath = definition.params['path'] as String?;
    final env = ctx.environment;

    ctx.logSink.addRaw(id, LogLevel.info, 'Running Flutter tests...');

    final command = [
      'flutter',
      'test',
      '--reporter=compact',
      if (coverage) '--coverage',
      if (env.dartDefineFromFile.isNotEmpty)
        '--dart-define-from-file=${env.dartDefineFromFile}'
      else
        '--dart-define=ENV=${env.name}',
      if (testPath != null) testPath,
    ];

    final result = await _runner.run(
      command: command,
      workingDir: ctx.workspaceDir,
      environment: env.shellEnv,
      timeout: const Duration(minutes: 20),
      logSink: ctx.logSink,
      stepId: id,
      cancelSignal: ctx.abortSignal,
    );

    final summary = _parseSummary(result.output);

    if (!result.success) {
      throw FatalPipelineException(
        stepId: id,
        message: summary != null
            ? 'Tests failed — $summary'
            : 'Flutter tests failed (exit ${result.exitCode})',
        exitCode: result.exitCode,
      );
    }

    ctx.logSink.addRaw(
      id,
      LogLevel.success,
      summary != null ? 'All tests passed — $summary' : 'All tests passed',
    );
    return StepResult.success(
      metadata: summary != null ? {'test_summary': summary} : const {},
    );
  }

  // Compact reporter summary lines look like:
  //   "00:05 +42: All tests passed!"
  //   "00:05 +40 -2: 2 tests failed."
  //   "00:01 ~1: test skipped."
  String? _parseSummary(List<String> lines) {
    final pattern = RegExp(r'^\d+:\d+\s+[+\-~]\d+');
    for (final line in lines.reversed) {
      final trimmed = line.trim();
      if (pattern.hasMatch(trimmed)) {
        return trimmed.replaceFirst(RegExp(r'^\d+:\d+\s+'), '');
      }
    }
    return null;
  }
}
