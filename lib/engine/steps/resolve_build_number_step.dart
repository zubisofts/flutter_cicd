import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:googleapis_auth/auth_io.dart' as gauth;
import 'package:http/http.dart' as http;
import '../pipeline_context.dart';
import '../step_result.dart';
import '../../execution/log_line.dart';
import '../../execution/process_runner.dart';
import 'pipeline_step.dart';

/// Queries the latest build number from TestFlight (iOS) and/or Play Store
/// (Android), takes the max across both, increments by 1, and stores the
/// result in ctx.state['resolved_build_number'].
///
/// Only runs when targets include 'testflight' or 'playstore' — dev/staging
/// Firebase-only runs skip it and use the manual build number unchanged.
///
/// iOS:     Fastfile lane (needs app_store_connect_api_key + latest_testflight_build_number).
/// Android: Direct Google Play Developer API call using the service account JSON —
///          no fastlane supply involved, so authentication and track listing are reliable.
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
    };

    try {
      int iosBuild = 0;
      int androidBuild = 0;

      if (queryIos) {
        iosBuild = await _resolveIos(ctx, shellEnv);
        ctx.logSink.addRaw(id, LogLevel.info, 'TestFlight latest build: $iosBuild');
      }

      if (queryAndroid) {
        androidBuild = await _resolveAndroid(
          ctx,
          env.shellEnv['PLAY_STORE_JSON_KEY'] ?? '',
          env.androidPackageName,
        );
        ctx.logSink.addRaw(id, LogLevel.info, 'Play Store max version code: $androidBuild');
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

  // ── iOS — Fastfile lane ─────────────────────────────────────────────────

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

  // ── Android — direct Google Play Developer API ──────────────────────────

  Future<int> _resolveAndroid(
      PipelineContext ctx, String jsonKeyPath, String packageName) async {
    if (jsonKeyPath.isEmpty) {
      ctx.logSink.addRaw(id, LogLevel.warning,
          'Play Store JSON key not configured — skipping Android build number query');
      return 0;
    }

    try {
      final keyContent = await File(jsonKeyPath).readAsString();
      final credentials = gauth.ServiceAccountCredentials.fromJson(keyContent);
      final authClient = await gauth.clientViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/androidpublisher'],
        baseClient: http.Client(),
      );
      try {
        final uri = Uri.parse(
          'https://www.googleapis.com/androidpublisher/v3/applications'
          '/$packageName/tracks',
        );
        final response = await authClient.get(uri);

        if (response.statusCode != 200) {
          ctx.logSink.addRaw(id, LogLevel.warning,
              'Play Store API error ${response.statusCode}: '
              '${response.body.length > 300 ? response.body.substring(0, 300) : response.body}');
          return 0;
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tracks = data['tracks'] as List? ?? [];

        int maxCode = 0;
        for (final track in tracks) {
          final trackName = track['track'] as String? ?? '';
          final releases = track['releases'] as List? ?? [];
          for (final release in releases) {
            final codes = release['versionCodes'] as List? ?? [];
            for (final code in codes) {
              final n = int.tryParse(code.toString()) ?? 0;
              if (n > maxCode) {
                maxCode = n;
                ctx.logSink.addRaw(
                    id, LogLevel.info, 'Play Store track "$trackName": $n');
              }
            }
          }
        }
        return maxCode;
      } finally {
        authClient.close();
      }
    } catch (e) {
      ctx.logSink.addRaw(id, LogLevel.warning, 'Play Store query failed: $e');
      return 0;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  int? _parseMarker(List<String> lines) {
    for (final line in lines.reversed) {
      final m = RegExp(r'CICD_BUILD_NUMBER:(\d+)').firstMatch(line);
      if (m != null) return int.tryParse(m.group(1)!);
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
