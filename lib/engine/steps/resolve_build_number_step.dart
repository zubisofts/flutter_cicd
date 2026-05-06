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
/// Only runs when the targets include 'testflight' or 'playstore' — dev/staging
/// Firebase-only runs skip it entirely and use the manual build number.
///
/// iOS: runs a temp Fastfile lane (requires api_key chaining via
///   app_store_connect_api_key + latest_testflight_build_number).
/// Android: calls `fastlane run google_play_track_version_codes` directly
///   per track and parses fastlane's "Result:" output — avoids the silent
///   rescue problem of a shared Ruby loop.
class ResolveBuildNumberStep extends PipelineStep {
  final ProcessRunner _runner;

  ResolveBuildNumberStep(super.definition, {ProcessRunner? runner})
      : _runner = runner ?? ProcessRunner();

  @override
  Future<StepResult> execute(PipelineContext ctx) async {
    final platforms = ctx.options.platforms;
    final targets = ctx.options.targets;
    final env = ctx.environment;

    final queryIos = platforms.contains('ios') &&
        targets.contains('testflight') &&
        env.iosBundleId.isNotEmpty;
    final queryAndroid = platforms.contains('android') &&
        targets.contains('playstore') &&
        env.androidPackageName.isNotEmpty;

    if (!queryIos && !queryAndroid) {
      ctx.logSink.addRaw(id, LogLevel.info,
          'No store targets — using build number from setup: '
          '${ctx.options.buildNumber}');
      return StepResult.success();
    }

    ctx.logSink.addRaw(
        id, LogLevel.info, 'Auto-resolving build number from app stores...');

    final shellEnv = {
      ...env.shellEnv,
      'LANG': 'en_US.UTF-8',
      'LC_ALL': 'en_US.UTF-8',
      'BUNDLE_ID': env.iosBundleId,
      'ANDROID_PACKAGE_NAME': env.androidPackageName,
      'SUPPLY_PACKAGE_NAME': env.androidPackageName,
      'SUPPLY_JSON_KEY': env.shellEnv['PLAY_STORE_JSON_KEY'] ?? '',
    };

    try {
      int iosBuild = 0;
      int androidBuild = 0;

      if (queryIos) {
        iosBuild = await _resolveIos(ctx, shellEnv);
        ctx.logSink.addRaw(
            id, LogLevel.info, 'TestFlight latest build: $iosBuild');
      }

      if (queryAndroid) {
        androidBuild = await _resolveAndroid(ctx, shellEnv, env.androidPackageName);
        ctx.logSink.addRaw(
            id, LogLevel.info, 'Play Store max version code: $androidBuild');
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
    }
  }

  // iOS needs a Fastfile because latest_testflight_build_number requires the
  // api_key object from app_store_connect_api_key — can't chain via fastlane run.
  Future<int> _resolveIos(
      PipelineContext ctx, Map<String, String> shellEnv) async {
    if ((shellEnv['ASC_KEY_ID'] ?? '').isEmpty) {
      ctx.logSink.addRaw(id, LogLevel.warning,
          'ASC API key not configured — skipping iOS build number query');
      return 0;
    }

    final tempDir = await Directory.systemTemp.createTemp('cicd_resolve_ios_');
    try {
      final fastlaneDir = Directory('${tempDir.path}/fastlane');
      await fastlaneDir.create();
      await File('${fastlaneDir.path}/Fastfile').writeAsString(_iosFastfile());

      final result = await _runner.run(
        command: ['fastlane', 'ios_build_number'],
        workingDir: tempDir.path,
        environment: shellEnv,
        timeout: const Duration(minutes: 3),
        logSink: ctx.logSink,
        stepId: id,
        cancelSignal: ctx.abortSignal,
      );
      return _parseMarker(result.output) ?? 0;
    } finally {
      await tempDir.delete(recursive: true);
    }
  }

  // Android uses `fastlane run google_play_track_version_codes` directly per
  // track — no Fastfile needed, and fastlane's own "Result:" output is parsed
  // so failures are visible rather than silently rescued.
  Future<int> _resolveAndroid(
      PipelineContext ctx,
      Map<String, String> shellEnv,
      String packageName) async {
    final jsonKey = shellEnv['PLAY_STORE_JSON_KEY'] ?? '';
    if (jsonKey.isEmpty) {
      ctx.logSink.addRaw(id, LogLevel.warning,
          'Play Store JSON key not configured — skipping Android build number query');
      return 0;
    }

    int maxCode = 0;
    for (final track in const ['internal', 'alpha', 'beta', 'production']) {
      final result = await _runner.run(
        command: [
          'fastlane', 'run', 'google_play_track_version_codes',
          'package_name:$packageName',
          'json_key:$jsonKey',
          'track:$track',
        ],
        workingDir: Directory.systemTemp.path,
        environment: shellEnv,
        timeout: const Duration(minutes: 2),
        logSink: ctx.logSink,
        stepId: id,
        cancelSignal: ctx.abortSignal,
      );

      if (result.success) {
        final code = _parseVersionCodes(result.output);
        if (code != null && code > 0) {
          ctx.logSink.addRaw(
              id, LogLevel.info, 'Play Store track "$track": $code');
          if (code > maxCode) maxCode = code;
        } else {
          ctx.logSink.addRaw(
              id, LogLevel.info, 'Play Store track "$track": empty');
        }
      } else {
        ctx.logSink.addRaw(
            id, LogLevel.info, 'Play Store track "$track": not found or error');
      }
    }
    return maxCode;
  }

  // Parses the marker emitted by the iOS Fastfile lane: CICD_BUILD_NUMBER:<n>
  int? _parseMarker(List<String> lines) {
    for (final line in lines.reversed) {
      final m = RegExp(r'CICD_BUILD_NUMBER:(\d+)').firstMatch(line);
      if (m != null) return int.tryParse(m.group(1)!);
    }
    return null;
  }

  // Parses fastlane's own "Result: 45" or "Result: [42, 43, 44]" output.
  int? _parseVersionCodes(List<String> lines) {
    for (final line in lines.reversed) {
      final m = RegExp(r'Result:\s*\[?([\d,\s]+)\]?').firstMatch(line);
      if (m != null) {
        final nums = m
            .group(1)!
            .split(',')
            .map((s) => int.tryParse(s.trim()))
            .whereType<int>()
            .toList();
        if (nums.isNotEmpty) return nums.reduce(max);
      }
    }
    return null;
  }

  static String _iosFastfile() => r'''
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
''';
}
