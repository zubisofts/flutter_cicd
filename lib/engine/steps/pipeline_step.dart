import '../pipeline_context.dart';
import '../step_result.dart';
import '../../config/models/pipeline_definition.dart';

abstract class PipelineStep {
  final StepDefinition definition;

  PipelineStep(this.definition);

  String get id => definition.id;
  String get name => definition.name;
  bool get abortOnFailure => definition.abortOnFailure;
  RetryPolicy? get retryPolicy => definition.retry;

  /// Evaluates the condition string against the context to decide
  /// whether this step should run.
  bool shouldExecute(PipelineContext ctx) {
    final condition = definition.condition;
    if (condition == null || condition.isEmpty) return true;
    return _evaluateCondition(condition, ctx);
  }

  bool _evaluateCondition(String condition, PipelineContext ctx) {
    final platforms = ctx.options.platforms;
    final targets = ctx.options.targets;
    switch (condition) {
      case 'android':
        return platforms.contains('android');
      case 'ios':
        return platforms.contains('ios');
      case 'firebase_android':
        return targets.contains('firebase_android') &&
            platforms.contains('android') &&
            (ctx.environment.distributionRules.firebase?.enabled ?? false);
      case 'firebase_ios':
        return targets.contains('firebase_ios') &&
            platforms.contains('ios') &&
            (ctx.environment.distributionRules.firebase?.enabled ?? false);
      case 'testflight':
        return targets.contains('testflight') &&
            platforms.contains('ios') &&
            ctx.environment.distributionRules.testflight;
      case 'playstore':
        return targets.contains('playstore') &&
            platforms.contains('android') &&
            (ctx.environment.distributionRules.playStore?.enabled ?? false);
      default:
        return true;
    }
  }

  Future<StepResult> execute(PipelineContext ctx);
}
