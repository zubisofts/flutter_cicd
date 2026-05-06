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
      // fastlane (Ruby) requires UTF-8 locale or it crashes on non-ASCII
      // changelog text with "incompatible encoding" errors.
      'LANG': 'en_US.UTF-8',
      'LC_ALL': 'en_US.UTF-8',
      'LC_CTYPE': 'en_US.UTF-8',
      'BUNDLE_ID': env.iosBundleId,
      'ANDROID_PACKAGE_NAME': env.androidPackageName,
      'IPA_PATH': ctx.artifactPath('ios') ?? '',
      'AAB_PATH': ctx.artifactPath('android_aab') ?? '',
      'APK_PATH': ctx.artifactPath('android_apk') ?? ctx.artifactPath('android') ?? '',
      'ARTIFACTS_DIR': '${ctx.workspaceDir}/artifacts',
      'PLAY_TRACK': env.distributionRules.playStore?.track ?? 'internal',
      'ROLLOUT_PERCENTAGE':
          '${env.distributionRules.playStore?.rolloutPercentage ?? 100}',
      'APPLE_TEAM_ID': env.iosConfig.teamId,
      'MATCH_APP_IDENTIFIER': env.iosBundleId,
      'FL_BUILD_NUMBER': '${env.buildNumber}',
      'FL_VERSION_NUMBER': env.resolvedVersion,
      'RELEASE_NOTES': ctx.options.releaseNotes ?? '',
      'MANAGED_PUBLISHING': ctx.options.managedPublishing ? 'true' : 'false',
    };

    // Play Store requires an App Bundle — APKs are rejected by Google for new
    // apps and exceed the 150 MB APK size limit enforced by Play Store.
    final laneBaseName = lane.trim().split(RegExp(r'\s+')).last;
    if (laneBaseName == 'upload_playstore' && shellEnv['AAB_PATH']!.isEmpty) {
      throw FatalPipelineException(
        stepId: id,
        message: 'Play Store upload requires an App Bundle (.aab). '
            'Set `artifact: appbundle` on your flutter_build step.',
      );
    }

    await _ensureFastlaneScaffolded(ctx, shellEnv);

    // Support "platform lane" syntax (e.g. "android upload_playstore") so
    // callers can target a specific platform block in their Fastfile.
    final laneParts = lane.trim().split(RegExp(r'\s+'));

    // Use `bundle exec fastlane` when a Gemfile exists, otherwise system fastlane.
    // ProcessRunner resolves the executable to an absolute path automatically.
    final hasGemfile = await File(p.join(ctx.workspaceDir, 'Gemfile')).exists();
    final command = hasGemfile
        ? ['bundle', 'exec', 'fastlane', ...laneParts]
        : ['fastlane', ...laneParts];

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

  // Top-level lanes (no platform blocks) so `fastlane <lane>` works directly
  // without needing a platform prefix. Fastlane actions like pilot and
  // upload_to_play_store know their own platform — they don't need a block.
  String _defaultFastfile() => r'''
desc "Upload IPA to TestFlight"
lane :upload_testflight do
  api_key = app_store_connect_api_key(
    key_id:         ENV["ASC_KEY_ID"],
    issuer_id:      ENV["ASC_ISSUER_ID"],
    key_content:    ENV["ASC_KEY_CONTENT"],
    is_key_content_base64: true,
    in_house:       false,
  )
  notes = ENV.fetch("RELEASE_NOTES", "")
  pilot(
    api_key:                           api_key,
    ipa:                               ENV["IPA_PATH"],
    team_id:                           ENV["APPLE_TEAM_ID"],
    changelog:                         notes.empty? ? nil : notes,
    skip_waiting_for_build_processing: true,
    skip_submission:                   true,
  )
end

desc "Sync certificates and profiles via Fastlane Match"
lane :sync_certificates do
  match(
    type:           ENV["MATCH_TYPE"],
    git_url:        ENV["MATCH_GIT_URL"],
    git_branch:     ENV.fetch("MATCH_GIT_BRANCH", "main"),
    app_identifier: ENV["MATCH_APP_IDENTIFIER"],
    readonly:       ENV.fetch("MATCH_READONLY", "true") == "true",
    verbose:        false,
  )
end

desc "Upload AAB to Play Store"
lane :upload_playstore do
  notes        = ENV.fetch("RELEASE_NOTES", "")
  build_number = ENV.fetch("FL_BUILD_NUMBER", "0")

  unless notes.empty?
    changelog_dir = "fastlane/metadata/android/en-US/changelogs"
    FileUtils.mkdir_p(changelog_dir)
    File.write("#{changelog_dir}/#{build_number}.txt", notes)
  end

  upload_to_play_store(
    track:                        ENV["PLAY_TRACK"],
    aab:                          ENV["AAB_PATH"],
    json_key:                     ENV["PLAY_STORE_JSON_KEY"],
    rollout:                      (ENV["ROLLOUT_PERCENTAGE"].to_f / 100).to_s,
    skip_upload_apk:              true,
    skip_upload_metadata:         true,
    skip_upload_changelogs:       notes.empty?,
    skip_upload_images:           true,
    skip_upload_screenshots:      true,
    changes_not_sent_for_review:  ENV.fetch("MANAGED_PUBLISHING", "false") == "true",
  )
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
