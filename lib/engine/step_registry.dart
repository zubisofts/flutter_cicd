import '../config/models/pipeline_definition.dart';
import 'steps/pipeline_step.dart';
import 'steps/preflight_check_step.dart';
import 'steps/git_checkout_step.dart';
import 'steps/set_version_step.dart';
import 'steps/flutter_pub_get_step.dart';
import 'steps/flutter_build_step.dart';
import 'steps/firebase_distribute_step.dart';
import 'steps/fastlane_lane_step.dart';
import 'steps/flutter_test_step.dart';
import 'steps/ios_archive_step.dart';
import 'steps/resolve_build_number_step.dart';
import 'steps/shell_script_step.dart';

typedef StepFactory = PipelineStep Function(StepDefinition definition);

class UnknownStepTypeException implements Exception {
  final String type;
  const UnknownStepTypeException(this.type);
  @override
  String toString() => 'Unknown step type: "$type"';
}

class StepRegistry {
  final Map<String, StepFactory> _factories = {};

  void register(String type, StepFactory factory) {
    _factories[type] = factory;
  }

  PipelineStep resolve(StepDefinition def) {
    final factory = _factories[def.type];
    if (factory == null) throw UnknownStepTypeException(def.type);
    return factory(def);
  }

  static StepRegistry get defaults {
    final r = StepRegistry();
    r.register('preflight_check', (d) => PreflightCheckStep(d));
    r.register('git_checkout', (d) => GitCheckoutStep(d));
    r.register('resolve_build_number', (d) => ResolveBuildNumberStep(d));
    r.register('set_version', (d) => SetVersionStep(d));
    r.register('flutter_pub_get', (d) => FlutterPubGetStep(d));
    r.register('flutter_build', (d) => FlutterBuildStep(d));
    r.register('firebase_distribute', (d) => FirebaseDistributeStep(d));
    r.register('fastlane_lane', (d) => FastlaneLaneStep(d));
    r.register('flutter_test', (d) => FlutterTestStep(d));
    r.register('ios_archive', (d) => IosArchiveStep(d));
    r.register('shell_script', (d) => ShellScriptStep(d));
    return r;
  }
}
