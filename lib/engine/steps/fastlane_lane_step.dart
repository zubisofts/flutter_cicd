import 'dart:io';
import 'package:path/path.dart' as p;
import '../pipeline_context.dart';
import '../step_result.dart';
import '../../execution/exceptions.dart';
import '../../execution/log_line.dart';
import '../../execution/process_runner.dart';
import 'pipeline_step.dart';

class FastlaneLaneStep extends PipelineStep {
  final ProcessRunner _runner;

  FastlaneLaneStep(super.definition, {ProcessRunner? runner})
      : _runner = runner ?? ProcessRunner();

  @override
  Future<StepResult> execute(PipelineContext ctx) async {
    final lane = definition.params['lane'] as String;
    final env = ctx.environment;

    ctx.logSink.addRaw(id, LogLevel.info, 'Running Fastlane lane: $lane');

    final shellEnv = {
      ...env.shellEnv,
      'BUNDLE_ID': env.iosBundleId,
      'ANDROID_PACKAGE_NAME': env.androidPackageName,
      'IPA_PATH': ctx.artifactPath('ios') ?? '',
      'AAB_PATH': ctx.artifactPath('android') ?? '',
      'APK_PATH': ctx.artifactPath('android') ?? '',
      'ARTIFACTS_DIR': '${ctx.workspaceDir}/artifacts',
      'PLAY_TRACK': env.distributionRules.playStore?.track ?? 'internal',
      'ROLLOUT_PERCENTAGE':
          '${env.distributionRules.playStore?.rolloutPercentage ?? 100}',
      'APPLE_TEAM_ID': env.iosConfig.teamId,
      'MATCH_APP_IDENTIFIER': env.iosBundleId,
      'FL_BUILD_NUMBER': '${env.buildNumber}',
      'FL_VERSION_NUMBER': env.resolvedVersion,
    };

    await _ensureFastlaneScaffolded(ctx, shellEnv);

    // Use `bundle exec fastlane` when a Gemfile exists, otherwise system fastlane.
    // ProcessRunner resolves the executable to an absolute path automatically.
    final hasGemfile = await File(p.join(ctx.workspaceDir, 'Gemfile')).exists();
    final command = hasGemfile
        ? ['bundle', 'exec', 'fastlane', lane]
        : ['fastlane', lane];

    final result = await _runner.run(
      command: command,
      workingDir: ctx.workspaceDir,
      environment: shellEnv,
      timeout: const Duration(minutes: 30),
      logSink: ctx.logSink,
      stepId: id,
      cancelSignal: ctx.abortSignal,
    );

    if (!result.success) {
      throw FatalPipelineException(
        stepId: id,
        message: 'Fastlane lane "$lane" failed (exit ${result.exitCode}). '
            'Check ${ctx.workspaceDir}/fastlane/report.xml for details.',
        exitCode: result.exitCode,
      );
    }

    ctx.logSink.addRaw(id, LogLevel.success, 'Fastlane lane "$lane" completed');
    return StepResult.success();
  }

  /// Writes a default Fastfile + Appfile when the project has no fastlane setup.
  Future<void> _ensureFastlaneScaffolded(
      PipelineContext ctx, Map<String, String> shellEnv) async {
    final fastlaneDir = Directory(p.join(ctx.workspaceDir, 'fastlane'));
    final fastfile = File(p.join(fastlaneDir.path, 'Fastfile'));

    if (await fastfile.exists()) return;

    await fastlaneDir.create(recursive: true);

    ctx.logSink.addRaw(id, LogLevel.info,
        'No Fastfile found — scaffolding default lanes...');

    await fastfile.writeAsString(_defaultFastfile());
    await File(p.join(fastlaneDir.path, 'Appfile'))
        .writeAsString(_defaultAppfile(shellEnv));

    ctx.logSink.addRaw(id, LogLevel.info,
        'Fastfile scaffolded at ${fastlaneDir.path}');
  }

  String _defaultFastfile() => r'''
default_platform(:ios)

platform :ios do
  desc "Upload IPA to TestFlight"
  lane :upload_testflight do
    api_key = app_store_connect_api_key(
      key_id:         ENV["ASC_KEY_ID"],
      issuer_id:      ENV["ASC_ISSUER_ID"],
      key_content:    ENV["ASC_KEY_CONTENT"],
      is_key_content_base64: true,
      in_house:       false,
    )
    pilot(
      api_key:                         api_key,
      ipa:                             ENV["IPA_PATH"],
      team_id:                         ENV["APPLE_TEAM_ID"],
      skip_waiting_for_build_processing: true,
      skip_submission:                 true,
    )
  end
end

platform :android do
  desc "Upload AAB to Play Store"
  lane :upload_playstore do
    upload_to_play_store(
      track:               ENV["PLAY_TRACK"],
      aab:                 ENV["AAB_PATH"],
      json_key:            ENV["PLAY_STORE_JSON_KEY"],
      rollout:             (ENV["ROLLOUT_PERCENTAGE"].to_f / 100).to_s,
      skip_upload_apk:     true,
      skip_upload_metadata: true,
      skip_upload_images:  true,
      skip_upload_screenshots: true,
    )
  end
end
''';

  String _defaultAppfile(Map<String, String> env) {
    final bundleId = env['BUNDLE_ID'] ?? '';
    final teamId = env['APPLE_TEAM_ID'] ?? '';
    final packageName = env['ANDROID_PACKAGE_NAME'] ?? '';
    return '''
app_identifier("$bundleId")
team_id("$teamId")
json_key_file(ENV["PLAY_STORE_JSON_KEY"])
package_name("$packageName")
''';
  }
}
