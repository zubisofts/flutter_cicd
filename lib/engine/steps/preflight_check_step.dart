import '../checks/tool_check.dart';
import '../pipeline_context.dart';
import '../step_result.dart';
import '../../execution/exceptions.dart';
import '../../execution/log_line.dart';
import 'pipeline_step.dart';

class PreflightCheckStep extends PipelineStep {
  PreflightCheckStep(super.definition);

  @override
  Future<StepResult> execute(PipelineContext ctx) async {
    final platforms = ctx.options.platforms;
    final targets = ctx.options.targets;

    final needsFastlane = platforms.contains('ios') ||
        targets.contains('testflight') ||
        targets.contains('playstore');
    final needsFirebase = targets.any((t) => t.contains('firebase'));

    final checks = <ToolCheck>[
      FlutterCheck(),
      GitCheck(),
      if (platforms.contains('ios')) XcodeCheck(platforms),
      if (platforms.contains('ios')) CocoaPodsCheck(),
      if (platforms.contains('android')) JavaCheck(),
      if (needsFastlane) FastlaneCheck(),
      if (needsFirebase) FirebaseCliCheck(),
    ];

    final results = <CheckResult>[];
    bool hasFatal = false;

    for (final check in checks) {
      ctx.logSink.addRaw(id, LogLevel.info, 'Checking ${check.name}...');
      final result = await check.run();
      results.add(result);

      if (result.isOk) {
        ctx.logSink.addRaw(
            id, LogLevel.success, '  ✓ ${result.label}');
      } else if (result.isFatal) {
        ctx.logSink.addRaw(
            id, LogLevel.error, '  ✗ ${result.label}');
        hasFatal = true;
      } else {
        ctx.logSink.addRaw(
            id, LogLevel.warning, '  ⚠ ${result.label}');
      }
    }

    ctx.state['preflight_results'] = results;

    if (hasFatal) {
      final failed =
          results.where((r) => r.isFatal).map((r) => r.name).join(', ');
      throw FatalPipelineException(
        stepId: id,
        message: 'Required tools not found: $failed. '
            'Please install them and try again.',
      );
    }

    return StepResult.success(
        metadata: {'checks': results.map((r) => r.label).toList()});
  }
}
