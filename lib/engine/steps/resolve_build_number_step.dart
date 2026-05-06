import 'dart:io';
import 'dart:math';
import '../pipeline_context.dart';
import '../step_result.dart';
import '../../execution/log_line.dart';
import '../../execution/process_runner.dart';
import 'pipeline_step.dart';

/// Queries the latest build number from TestFlight (iOS) and/or Play Store
/// (Android), takes the max across both, increments by 1, and stores the
/// result in ctx.state['resolved_build_number'].
///
/// Downstream steps (flutter_build, ios_archive, fastlane_lane) read
/// ctx.resolvedBuildNumber so they automatically use the right number.
/// If either query fails (credentials not configured, no builds yet, network
/// error), the step falls back silently to ctx.options.buildNumber so the
/// pipeline still proceeds.
class ResolveBuildNumberStep extends PipelineStep {
  final ProcessRunner _runner;

  ResolveBuildNumberStep(super.definition, {ProcessRunner? runner})
      : _runner = runner ?? ProcessRunner();

  @override
  Future<StepResult> execute(PipelineContext ctx) async {
    final platforms = ctx.options.platforms;
    final env = ctx.environment;

    final targets = ctx.options.targets;
    final queryIos = platforms.contains('ios') &&
        targets.contains('testflight') &&
        env.iosBundleId.isNotEmpty;
    final queryAndroid = platforms.contains('android') &&
        targets.contains('playstore') &&
        env.androidPackageName.isNotEmpty;

    if (!queryIos && !queryAndroid) {
      ctx.logSink.addRaw(id, LogLevel.info,
          'No store targets selected — using build number from setup: '
          '${ctx.options.buildNumber}');
      return StepResult.success();
    }

    ctx.logSink.addRaw(
        id, LogLevel.info, 'Auto-resolving build number from app stores...');

    final tempDir = await Directory.systemTemp.createTemp('cicd_resolve_');
    try {
      final fastlaneDir = Directory('${tempDir.path}/fastlane');
      await fastlaneDir.create();
      await File('${fastlaneDir.path}/Fastfile').writeAsString(_fastfile());

      final shellEnv = {
        ...env.shellEnv,
        'LANG': 'en_US.UTF-8',
        'LC_ALL': 'en_US.UTF-8',
        'BUNDLE_ID': env.iosBundleId,
        'ANDROID_PACKAGE_NAME': env.androidPackageName,
        'PLAY_TRACK': env.distributionRules.playStore?.track ?? 'internal',
      };

      int iosBuild = 0;
      int androidBuild = 0;

      if (queryIos) {
        if ((shellEnv['ASC_KEY_ID'] ?? '').isNotEmpty) {
          final result = await _runner.run(
            command: ['fastlane', 'ios_build_number'],
            workingDir: tempDir.path,
            environment: shellEnv,
            timeout: const Duration(minutes: 3),
            logSink: ctx.logSink,
            stepId: id,
            cancelSignal: ctx.abortSignal,
          );
          iosBuild = _parseMarker(result.output) ?? 0;
          ctx.logSink.addRaw(
              id, LogLevel.info, 'TestFlight latest build: $iosBuild');
        } else {
          ctx.logSink.addRaw(id, LogLevel.warning,
              'ASC API key not configured — skipping iOS build number query');
        }
      }

      if (queryAndroid) {
        if ((shellEnv['PLAY_STORE_JSON_KEY'] ?? '').isNotEmpty) {
          final result = await _runner.run(
            command: ['fastlane', 'android_build_number'],
            workingDir: tempDir.path,
            environment: shellEnv,
            timeout: const Duration(minutes: 3),
            logSink: ctx.logSink,
            stepId: id,
            cancelSignal: ctx.abortSignal,
          );
          androidBuild = _parseMarker(result.output) ?? 0;
          ctx.logSink.addRaw(
              id, LogLevel.info, 'Play Store latest build: $androidBuild');
        } else {
          ctx.logSink.addRaw(id, LogLevel.warning,
              'Play Store JSON key not configured — skipping Android build number query');
        }
      }

      final next = max(iosBuild, androidBuild) + 1;
      ctx.state['resolved_build_number'] = next;
      ctx.logSink.addRaw(id, LogLevel.success,
          'Next build number: $next '
          '(iOS latest: $iosBuild, Android latest: $androidBuild)');

      return StepResult.success(metadata: {
        'build_number': next,
        'ios_latest': iosBuild,
        'android_latest': androidBuild,
      });
    } catch (e) {
      ctx.logSink.addRaw(id, LogLevel.warning,
          'Build number resolution failed ($e) — '
          'using build number from setup: ${ctx.options.buildNumber}');
      return StepResult.success();
    } finally {
      await tempDir.delete(recursive: true);
    }
  }

  // Looks for a line emitted by the Fastfile lanes: CICD_BUILD_NUMBER:<n>
  int? _parseMarker(List<String> lines) {
    for (final line in lines.reversed) {
      final m = RegExp(r'CICD_BUILD_NUMBER:(\d+)').firstMatch(line);
      if (m != null) return int.tryParse(m.group(1)!);
    }
    return null;
  }

  static String _fastfile() => r'''
lane :ios_build_number do
  api_key = app_store_connect_api_key(
    key_id:                ENV["ASC_KEY_ID"],
    issuer_id:             ENV["ASC_ISSUER_ID"],
    key_content:           ENV["ASC_KEY_CONTENT"],
    is_key_content_base64: true,
    in_house:              false,
  )
  n = latest_testflight_build_number(
    api_key:        api_key,
    app_identifier: ENV["BUNDLE_ID"],
  )
  puts "CICD_BUILD_NUMBER:#{n}"
end

lane :android_build_number do
  max_code = 0
  %w[internal alpha beta production].each do |track|
    begin
      codes = google_play_track_version_codes(
        package_name: ENV["ANDROID_PACKAGE_NAME"],
        json_key:     ENV["PLAY_STORE_JSON_KEY"],
        track:        track,
      )
      n = codes.is_a?(Array) ? codes.max.to_i : codes.to_i
      max_code = [max_code, n].max
    rescue
    end
  end
  puts "CICD_BUILD_NUMBER:#{max_code}"
end
''';
}
