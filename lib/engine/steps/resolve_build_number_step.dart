import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as p;
import '../pipeline_context.dart';
import '../step_result.dart';
import '../../execution/log_line.dart';
import '../../execution/process_runner.dart';
import 'pipeline_step.dart';

/// Queries the latest TestFlight build number for iOS and auto-increments it.
///
/// Android always uses the manually entered build number — this step does
/// nothing for Android-only or Firebase-only runs.
///
/// Writes ctx.state['resolved_build_number'] which is then read by flutter
/// build and archive steps. Also persists the resolved number locally
/// (~/.cicd/projects/{id}/build_counters.json) so that builds discarded from
/// TestFlight still act as a floor on the next run.
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

    if (!queryIos) {
      ctx.logSink.addRaw(id, LogLevel.info,
          'No TestFlight target — using build number from setup: '
          '${ctx.options.buildNumber}');
      return StepResult.success();
    }

    ctx.logSink.addRaw(
        id, LogLevel.info, 'Auto-resolving iOS build number from TestFlight...');

    final shellEnv = {
      ...env.shellEnv,
      'LANG': 'en_US.UTF-8',
      'LC_ALL': 'en_US.UTF-8',
      'BUNDLE_ID': env.iosBundleId,
    };

    final localCounters = await _readLocalCounters(ctx.projectId);
    final localIosMax = localCounters['ios'] as int? ?? 0;

    try {
      final apiResult = await _resolveIos(ctx, shellEnv);
      final int iosBuild;

      if (apiResult != null) {
        iosBuild = max(apiResult, localIosMax);
        ctx.logSink.addRaw(id, LogLevel.info,
            'TestFlight latest build: $apiResult'
            '${iosBuild > apiResult ? " (local floor: $iosBuild)" : ""}');
      } else if (localIosMax > 0) {
        iosBuild = localIosMax;
        ctx.logSink.addRaw(id, LogLevel.info,
            'TestFlight query failed — using local history floor: $iosBuild');
      } else {
        ctx.logSink.addRaw(id, LogLevel.warning,
            'TestFlight query returned no result and no local history — '
            'using manual build number: ${ctx.options.buildNumber}');
        return StepResult.success();
      }

      final next = iosBuild + 1;
      ctx.state['resolved_build_number'] = next;
      ctx.logSink.addRaw(
          id, LogLevel.success, 'Next iOS build number: $next (latest: $iosBuild)');

      final updated = Map<String, dynamic>.from(localCounters)..['ios'] = next;
      await _writeLocalCounters(ctx.projectId, updated);

      return StepResult.success(metadata: {'build_number': next, 'ios_latest': iosBuild});
    } catch (e) {
      ctx.logSink.addRaw(id, LogLevel.warning,
          'Build number resolution failed ($e) — '
          'using manual build number: ${ctx.options.buildNumber}');
      return StepResult.success();
    }
  }

  // ── iOS — Fastfile lane ─────────────────────────────────────────────────

  Future<int?> _resolveIos(
      PipelineContext ctx, Map<String, String> shellEnv) async {
    if ((shellEnv['ASC_KEY_ID'] ?? '').isEmpty) {
      ctx.logSink.addRaw(id, LogLevel.warning,
          'ASC API key not configured — skipping TestFlight build number query');
      return null;
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
      return _parseMarker(result.output);
    } finally {
      await tempDir.delete(recursive: true);
    }
  }

  // ── Local build-number tracking ──────────────────────────────────────────

  String _countersPath(String projectId) {
    final home = Platform.environment['HOME'] ?? '/tmp';
    return p.join(home, '.cicd', 'projects', projectId, 'build_counters.json');
  }

  Future<Map<String, dynamic>> _readLocalCounters(String projectId) async {
    try {
      final file = File(_countersPath(projectId));
      if (!await file.exists()) return {};
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeLocalCounters(
      String projectId, Map<String, dynamic> counters) async {
    try {
      final file = File(_countersPath(projectId));
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(counters));
    } catch (_) {}
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
